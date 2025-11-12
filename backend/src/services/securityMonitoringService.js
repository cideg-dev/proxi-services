const { logger } = require('../utils/logger');
const pool = require('../../db.config');
require('dotenv').config();

/**
 * Service de surveillance des événements de sécurité
 * Permet de détecter des comportements suspects
 */
class SecurityMonitoringService {
  /**
   * Vérifie les tentatives d'authentification répétées depuis la même IP
   * @param {string} ip - L'adresse IP
   * @param {number} timeWindow - Fenêtre de temps en secondes (par défaut: 300 = 5 minutes)
   * @param {number} maxAttempts - Nombre maximal de tentatives (par défaut: 5)
   * @returns {Promise<boolean>} - true si seuil dépassé, false sinon
   */
  static async checkFailedAuthAttempts(ip, timeWindow = 300, maxAttempts = 5) {
    try {
      // Cette vérification pourrait être faite avec Redis pour des performances optimales
      // Pour l'instant, nous allons utiliser la base de données
      
      // Note: Cette implémentation suppose que vous avez une table pour suivre les tentatives
      // En pratique, vous voudrez peut-être utiliser Redis pour cette fonctionnalité
      
      // Pour cette implémentation, nous allons juste logger le comportement
      logger.info('FAILED_AUTH_CHECK', {
        ip,
        timeWindow,
        maxAttempts,
        timestamp: new Date().toISOString()
      });
      
      return false; // Pour l'instant, pas de blocage automatique
    } catch (error) {
      logger.error('Erreur lors de la vérification des tentatives d\'authentification', {
        error: error.message,
        ip,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
  
  /**
   * Enregistre une tentative d'authentification échouée
   * @param {string} ip - L'adresse IP
   * @param {string} userAgent - Le User Agent
   * @param {string} reason - La raison de l'échec
   */
  static async logFailedAuthAttempt(ip, userAgent, reason) {
    logger.warn('FAILED_AUTH_ATTEMPT', {
      ip,
      userAgent,
      reason,
      timestamp: new Date().toISOString()
    });
  }
  
  /**
   * Vérifie les accès non autorisés répétés à des ressources
   * @param {number} userId - L'ID de l'utilisateur
   * @param {string} resource - La ressource ciblée
   * @param {number} timeWindow - Fenêtre de temps en secondes
   * @param {number} maxAttempts - Nombre maximal de tentatives
   * @returns {Promise<boolean>} - true si seuil dépassé, false sinon
   */
  static async checkUnauthorizedAccessAttempts(userId, resource, timeWindow = 300, maxAttempts = 5) {
    try {
      logger.info('UNAUTHORIZED_ACCESS_CHECK', {
        userId,
        resource,
        timeWindow,
        maxAttempts,
        timestamp: new Date().toISOString()
      });
      
      return false; // Pour l'instant, pas de blocage automatique
    } catch (error) {
      logger.error('Erreur lors de la vérification des accès non autorisés', {
        error: error.message,
        userId,
        resource,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
  
  /**
   * Enregistre un accès non autorisé
   * @param {number} userId - L'ID de l'utilisateur
   * @param {string} resource - La ressource ciblée
   * @param {string} action - L'action tentée
   */
  static async logUnauthorizedAccess(userId, resource, action) {
    logger.warn('UNAUTHORIZED_ACCESS_ATTEMPT', {
      userId,
      resource,
      action,
      timestamp: new Date().toISOString()
    });
    
    // Pourrait déclencher une alerte de sécurité dans un système plus avancé
  }
  
  /**
   * Détecte des comportements suspects dans les messages
   * @param {number} senderId - L'ID de l'expéditeur
   * @param {string} content - Le contenu du message
   * @returns {boolean} - true si comportement suspect, false sinon
   */
  static detectSuspiciousMessage(senderId, content) {
    // Exemples de détection de comportement suspect
    const suspiciousPatterns = [
      /<script/i, // Tentatives d'injection de script
      /<iframe/i,
      /javascript:/i,
      /on\w+\s*=/i, // Événements JavaScript dans les attributs
      /SELECT.*FROM/i, // Tentatives de SQL injection
      /DROP.*TABLE/i,
      /UNION.*SELECT/i,
      // Vous pouvez ajouter d'autres signatures de comportement suspect
    ];
    
    const isSuspicious = suspiciousPatterns.some(pattern => pattern.test(content));
    
    if (isSuspicious) {
      logger.warn('SUSPICIOUS_MESSAGE_CONTENT', {
        senderId,
        content: content.substring(0, 100) + '...', // Limiter la longueur pour les logs
        timestamp: new Date().toISOString()
      });
    }
    
    return isSuspicious;
  }
  
  /**
   * Enregistre un accès à une route sensible
   * @param {object} req - L'objet requête
   */
  static logSensitiveRouteAccess(req) {
    logger.info('SENSITIVE_ROUTE_ACCESS', {
      userId: req.user ? req.user.id : null,
      route: req.originalUrl,
      method: req.method,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
      timestamp: new Date().toISOString()
    });
  }
  
  /**
   * Vérifie si une requête semble être une attaque
   * @param {object} req - L'objet requête
   * @returns {boolean} - true si requête suspecte, false sinon
   */
  static detectSuspiciousRequest(req) {
    // Vérifier la taille du corps de la requête
    const contentLength = req.get('Content-Length');
    if (contentLength && parseInt(contentLength) > 1024 * 1024) { // 1MB
      logger.warn('LARGE_REQUEST_BODY', {
        ip: req.ip || req.connection.remoteAddress,
        contentLength: contentLength,
        route: req.originalUrl,
        timestamp: new Date().toISOString()
      });
      return true;
    }
    
    // Vérifier d'autres indicateurs d'attaque potentielle
    return false;
  }
}

module.exports = SecurityMonitoringService;