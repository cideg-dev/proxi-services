const { logger, logError } = require('../utils/logger');

// Middleware de gestion des erreurs centralisée
const errorHandler = (err, req, res, next) => {
  // Enregistrement de l'erreur dans les logs
  logError(err, req, { 
    operation: 'error_handling',
    timestamp: new Date().toISOString()
  });

  // Classification et réponse en fonction du type d'erreur
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Erreur de validation',
      errors: Object.keys(err.errors).map(key => ({
        field: key,
        message: err.errors[key].message
      }))
    });
  }

  if (err.name === 'MongoError' || err.code === '23505') { // Code d'erreur PostgreSQL pour doublon
    return res.status(409).json({
      success: false,
      message: 'Conflit de données - une ressource avec ces informations existe déjà'
    });
  }

  if (err.name === 'UnauthorizedError' || err.message === 'jwt expired' || err.message === 'invalid token') {
    return res.status(401).json({
      success: false,
      message: 'Token invalide ou expiré'
    });
  }

  if (err.status === 404) {
    return res.status(404).json({
      success: false,
      message: 'Ressource non trouvée'
    });
  }

  // Pour les autres erreurs, renvoyer une erreur interne
  res.status(500).json({
    success: false,
    message: 'Une erreur interne du serveur est survenue'
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