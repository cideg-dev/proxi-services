const SecurityMonitoringService = require('../services/securityMonitoringService');

/**
 * Middleware de surveillance des accès sensibles
 */
const monitorSensitiveAccess = (req, res, next) => {
  // Détection des routes sensibles
  const sensitiveRoutes = [
    '/api/admin',
    '/api/auth/logout',
    '/api/auth/logout-all', 
    '/api/auth/logout-others',
    '/api/users',
    '/api/messages',
    '/api/profile'
  ];
  
  const isSensitiveRoute = sensitiveRoutes.some(route => req.path.startsWith(route));
  
  if (isSensitiveRoute) {
    SecurityMonitoringService.logSensitiveRouteAccess(req);
  }
  
  next();
};

module.exports = { monitorSensitiveAccess };