// Middleware pour la surveillance des activités suspectes

const { checkSuspiciousActivity, logFailedLoginAttempt, logFailedMFATry } = require('../services/auditService');
const logger = require('../utils/logger');

/**
 * Middleware pour surveiller les activités suspectes
 * @param {string} actionType - Type d'action à surveiller
 */
const monitorSuspiciousActivity = (actionType) => {
  return async (req, res, next) => {
    try {
      // Ne s'applique que si l'utilisateur est authentifié
      if (req.user && req.user.user) {
        const userId = req.user.user.id;
        
        // Vérifier si l'utilisateur a une activité suspecte
        const isSuspicious = await checkSuspiciousActivity(userId, actionType);
        
        if (isSuspicious) {
          logger.warn(`Activité suspecte détectée pour l'utilisateur ${userId} lors de l'action ${actionType}`);
          
          // Vous pouvez décider ici de bloquer l'action ou d'envoyer une alerte
          // Pour le moment, nous allons enregistrer l'activité et poursuivre
        }
      }
      
      next();
    } catch (error) {
      logger.error('Erreur dans le middleware de surveillance:', error.message);
      next(); // Continuer malgré l'erreur pour ne pas interrompre la fonctionnalité
    }
  };
};

/**
 * Middleware spécifique pour les tentatives de connexion
 */
const loginAttemptMiddleware = async (req, res, next) => {
  // Enregistrer les tentatives de connexion échouées
  res.on('finish', async () => {
    // Si la requête a échoué avec un code 401 ou 403, c'est probablement une tentative échouée
    if (res.statusCode === 401 || res.statusCode === 403) {
      const email = req.body.email || req.query.email;
      const ip = req.headers['x-forwarded-for'] || 
                 req.connection.remoteAddress || 
                 req.socket.remoteAddress ||
                 (req.connection.socket ? req.connection.socket.remoteAddress : null);
      const userAgent = req.headers['user-agent'];
      
      if (email) {  // On ne loggue que si un email a été fourni
        await logFailedLoginAttempt(email, ip, userAgent);
      }
    }
  });
  
  next();
};

module.exports = {
  monitorSuspiciousActivity,
  loginAttemptMiddleware
};