const { logger, logError } = require('../utils/logger');

// Middleware de gestion des erreurs centralisée avec masquage des informations sensibles
const errorHandler = (err, req, res, next) => {
  // Enregistrement détaillé de l'erreur dans les logs (ne contient pas de données sensibles)
  logError(err, req, {
    operation: 'error_handling',
    timestamp: new Date().toISOString()
  });

  // Classification et réponse en fonction du type d'erreur, avec masquage des détails internes

  // Erreurs de validation - informations révélées car elles proviennent des données d'entrée
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Erreur de validation',
      errors: process.env.NODE_ENV === 'production'
        ? Object.keys(err.errors).map(key => ({ field: key, message: 'Valeur invalide' })) // Masquer les détails en production
        : Object.keys(err.errors).map(key => ({ field: key, message: err.errors[key].message }))
    });
  }

  // Erreurs de base de données - masquer les détails techniques
  if (err.name === 'MongoError' || err.code === '23505') { // Code d'erreur PostgreSQL pour doublon
    return res.status(409).json({
      success: false,
      message: process.env.NODE_ENV === 'production'
        ? 'Donnée en conflit - une ressource similaire existe déjà' // Message générique en production
        : 'Conflit de données - une ressource avec ces informations existe déjà' // Message plus détaillé en développement
    });
  }

  // Erreurs d'authentification - informations généralement non sensibles
  if (err.name === 'UnauthorizedError' || err.message === 'jwt expired' || err.message === 'invalid token' || err.name === 'TokenExpiredError' || err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Token invalide ou expiré'
    });
  }

  // Erreurs 404 - pas d'informations sensibles
  if (err.status === 404) {
    return res.status(404).json({
      success: false,
      message: 'Ressource non trouvée'
    });
  }

  // Erreurs liées à multer pour les uploads
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      success: false,
      message: 'Le fichier est trop volumineux'
    });
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      success: false,
      message: 'Nom de champ de fichier incorrect'
    });
  }

  // Pour les autres erreurs, renvoyer une erreur interne générique
  // Masquer les détails de l'erreur pour éviter les fuites d'informations
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production'
      ? 'Une erreur interne du serveur est survenue' // Message générique en production
      : err.message, // Message détaillé en développement
    ...(process.env.NODE_ENV === 'production' && {
      errorId: `ERR_${Date.now()}_${Math.random().toString(36).substr(2, 9).toUpperCase()}` // ID pour le support
    })
  });
};

// Middleware pour les routes non trouvées
const notFoundHandler = (req, res, next) => {
  const error = new Error(`Route non trouvée: ${req.originalUrl}`);
  error.status = 404;
  next(error);
};

// Middleware de gestion des erreurs asynchrones
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler
};