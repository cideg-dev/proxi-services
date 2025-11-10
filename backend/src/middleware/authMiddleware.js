const { verifyToken, verifyRefreshToken } = require('../services/jwtService');
const { logger, logError } = require('../utils/logger');
const { pool } = require('../../db.config');

// Middleware d'authentification
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  
  // Vérifier la présence de l'en-tête Authorization
  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: 'Accès refusé. Aucun token fourni.'
    });
  }

  // Vérifier le format de l'en-tête Authorization
  const tokenParts = authHeader.split(' ');
  if (tokenParts.length !== 2 || tokenParts[0] !== 'Bearer') {
    return res.status(401).json({
      success: false,
      message: 'Format de token invalide. Utilisez le format Bearer.'
    });
  }

  const token = tokenParts[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Accès refusé. Aucun token fourni.'
    });
  }

  try {
    const decoded = verifyToken(token);

    // Vérifier si l'utilisateur existe encore dans la base
    const userResult = await pool.query('SELECT id, role, email, is_active, is_blocked, last_login FROM users WHERE id = $1', [decoded.userId]);

    if (userResult.rows.length === 0) {
      // Ne pas révéler si l'utilisateur existe ou non pour des raisons de sécurité
      return res.status(401).json({
        success: false,
        message: 'Token invalide. Veuillez vous reconnecter.'
      });
    }

    const user = userResult.rows[0];

    // Vérifier si l'utilisateur est bloqué
    if (user.is_blocked) {
      return res.status(401).json({
        success: false,
        message: 'Votre compte est bloqué. Veuillez contacter l\'administrateur.'
      });
    }

    // Vérifier si l'utilisateur est actif
    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        message: 'Votre compte est inactif. Veuillez le réactiver.'
      });
    }

    req.user = user;
    req.userId = decoded.userId;
    req.role = decoded.role;

    logger.info('AUTHENTICATION_SUCCESS', {
      userId: decoded.userId,
      role: decoded.role,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      timestamp: new Date().toISOString()
    });

    next();
  } catch (error) {
    logError(error, req, { operation: 'token_verification' });

    // Ne pas révéler la nature exacte de l'erreur pour des raisons de sécurité
    if (error.message.includes('expiré') || error.name === 'TokenExpiredError') {
      return res.status(403).json({
        success: false,
        message: 'Token expiré. Veuillez vous reconnecter.'
      });
    } else if (error.message.includes('invalide') || error.name === 'JsonWebTokenError') {
      return res.status(403).json({
        success: false,
        message: 'Token invalide. Veuillez vous reconnecter.'
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Erreur d\'authentification. Veuillez réessayer.'
    });
  }
};

// Middleware d'autorisation basé sur le rôle
const authorizeRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Rôle non défini.'
      });
    }

    if (!allowedRoles || !Array.isArray(allowedRoles)) {
      logger.error('INVALID_ROLE_CONFIG', {
        userId: req.user.id,
        attemptedRole: req.user.role,
        ip: req.ip || req.connection.remoteAddress
      });
      return res.status(500).json({
        success: false,
        message: 'Configuration de rôle invalide.'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      logger.warn('AUTHORIZATION_FAILED', {
        userId: req.user.id,
        attemptedRole: req.user.role,
        requiredRoles: allowedRoles,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });

      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Rôle non autorisé.'
      });
    }

    next();
  };
};

// Middleware pour vérifier si l'utilisateur est propriétaire de la ressource
const checkResourceOwnership = (resourceOwnerIdField = 'user_id') => {
  return (req, res, next) => {
    // Vérifier plusieurs emplacements pour l'ID du propriétaire
    let resourceOwnerId = req.params.id || req.body[resourceOwnerIdField] || req.query[resourceOwnerIdField];
    
    // Si l'ID est dans le corps, vérifier qu'il est une chaîne ou un nombre
    if (req.body[resourceOwnerIdField]) {
      if (typeof req.body[resourceOwnerIdField] === 'string' || typeof req.body[resourceOwnerIdField] === 'number') {
        resourceOwnerId = req.body[resourceOwnerIdField];
      }
    }

    if (!resourceOwnerId) {
      return res.status(400).json({
        success: false,
        message: 'ID de propriétaire de ressource non fourni.'
      });
    }

    // Conversion sécurisée pour comparaison
    const userId = parseInt(req.user.id);
    const ownerId = parseInt(resourceOwnerId);
    
    if (isNaN(userId) || isNaN(ownerId)) {
      logger.warn('INVALID_ID_FOR_OWNERSHIP_CHECK', {
        userId: req.user.id,
        resourceOwnerId: resourceOwnerId,
        ip: req.ip || req.connection.remoteAddress
      });
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Identifiants invalides.'
      });
    }

    if (userId !== ownerId && req.user.role !== 'admin') {
      logger.warn('OWNERSHIP_CHECK_FAILED', {
        userId: req.user.id,
        resourceOwnerId: resourceOwnerId,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });

      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Vous n\'êtes pas le propriétaire de cette ressource.'
      });
    }

    next();
  };
};

// Middleware de sécurité supplémentaire pour les routes sensibles
const sensitiveRouteProtection = (req, res, next) => {
  // Ajouter des vérifications supplémentaires pour les routes sensibles
  // Par exemple: vérifier le nombre de tentatives récentes, etc.
  logger.info('SENSITIVE_ROUTE_ACCESS', {
    userId: req.user.id,
    route: req.originalUrl,
    ip: req.ip || req.connection.remoteAddress,
    timestamp: new Date().toISOString()
  });

  // Ajouter des vérifications de fréquence d'accès si nécessaire
  next();
};

module.exports = {
  authenticateToken,
  authorizeRole,
  checkResourceOwnership,
  sensitiveRouteProtection
};