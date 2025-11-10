const { verifyToken, verifyRefreshToken } = require('../services/jwtService');
const { logger, logError } = require('../utils/logger');
const { pool } = require('../../db.config');

// Middleware d'authentification
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      message: 'Accès refusé. Aucun token fourni.' 
    });
  }

  try {
    const decoded = verifyToken(token);
    
    // Vérifier si l'utilisateur existe encore dans la base
    const userResult = await pool.query('SELECT id, role, email, is_active, is_blocked FROM users WHERE id = $1', [decoded.userId]);
    
    if (userResult.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        message: 'Token invalide. Utilisateur introuvable.' 
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
      userAgent: req.get('User-Agent')
    });

    next();
  } catch (error) {
    logError(error, req, { operation: 'token_verification' });
    
    if (error.message === 'Token invalide ou expiré') {
      return res.status(403).json({ 
        success: false, 
        message: 'Token expiré ou invalide. Veuillez vous reconnecter.' 
      });
    }
    
    return res.status(500).json({ 
      success: false, 
      message: 'Erreur interne du serveur.' 
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

    if (!allowedRoles.includes(req.user.role)) {
      logger.warn('AUTHORIZATION_FAILED', {
        userId: req.user.id,
        attemptedRole: req.user.role,
        requiredRoles: allowedRoles,
        ip: req.ip || req.connection.remoteAddress
      });
      
      return res.status(403).json({ 
        success: false, 
        message: `Accès refusé. Rôle ${req.user.role} non autorisé.` 
      });
    }

    next();
  };
};

// Middleware pour vérifier si l'utilisateur est propriétaire de la ressource
const checkResourceOwnership = (resourceOwnerIdField = 'user_id') => {
  return (req, res, next) => {
    const resourceOwnerId = req.params.id || req.body[resourceOwnerIdField] || req.query[resourceOwnerIdField];
    
    if (!resourceOwnerId) {
      return res.status(400).json({ 
        success: false, 
        message: 'ID de propriétaire de ressource non fourni.' 
      });
    }

    if (req.user.id != resourceOwnerId && req.user.role !== 'admin') {
      logger.warn('OWNERSHIP_CHECK_FAILED', {
        userId: req.user.id,
        resourceOwnerId: resourceOwnerId,
        ip: req.ip || req.connection.remoteAddress
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

  next();
};

module.exports = {
  authenticateToken,
  authorizeRole,
  checkResourceOwnership,
  sensitiveRouteProtection
};