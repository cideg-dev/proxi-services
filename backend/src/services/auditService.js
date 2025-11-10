// Service pour la gestion des logs d'audit et de surveillance de sécurité

const path = require('path');
const dbConfigPath = path.join(__dirname, '..', 'db.config');
const pool = require(dbConfigPath);
const logger = require('../utils/logger');

/**
 * Enregistrer une action dans les logs d'audit
 * @param {number|null} userId - ID de l'utilisateur qui a effectué l'action
 * @param {string} actionType - Type d'action (ex: 'user_login', 'profile_updated', 'mfa_enabled')
 * @param {string|null} entityType - Type d'entité concernée (ex: 'user', 'profile', 'message')
 * @param {number|null} entityId - ID de l'entité concernée
 * @param {Object} details - Détails supplémentaires sur l'action
 * @param {Object} req - Objet request pour obtenir les détails IP et navigateur
 */
const logAuditAction = async (userId, actionType, entityType = null, entityId = null, details = {}, req = null) => {
  try {
    let ip = null;
    let userAgent = null;

    if (req) {
      // Obtenir l'IP du client de manière sécurisée
      ip = req.headers['x-forwarded-for'] || 
           req.connection.remoteAddress || 
           req.socket.remoteAddress ||
           (req.connection.socket ? req.connection.socket.remoteAddress : null);
           
      userAgent = req.headers['user-agent'];
    }

    // Ajouter des détails de requête aux logs si disponibles
    const logDetails = {
      ...details,
      ip: ip,
      userAgent: userAgent,
      timestamp: new Date()
    };

    await pool.query(`
      INSERT INTO audit_logs (user_id, action_type, entity_type, entity_id, details)
      VALUES ($1, $2, $3, $4, $5)
    `, [userId, actionType, entityType, entityId, JSON.stringify(logDetails)]);

    // Log additionnel pour la surveillance de sécurité
    logger.info(`Audit log: ${actionType} by user ${userId}`, {
      userId,
      actionType,
      entityType,
      entityId,
      ip,
      userAgent
    });
  } catch (error) {
    logger.error('Erreur lors de l\'enregistrement du log d\'audit:', error.message);
  }
};

/**
 * Vérifier les activités suspectes pour un utilisateur
 * @param {number} userId - ID de l'utilisateur à vérifier
 * @param {string} actionType - Type d'action à surveiller
 * @param {number} minutes - Nombre de minutes à vérifier en arrière
 * @param {number} threshold - Nombre de fois où l'action peut être effectuée avant d'être suspecte
 * @returns {Promise<boolean>} - Si l'activité est suspecte
 */
const checkSuspiciousActivity = async (userId, actionType, minutes = 5, threshold = 5) => {
  try {
    const result = await pool.query(`
      SELECT COUNT(*) as count
      FROM audit_logs
      WHERE user_id = $1
        AND action_type = $2
        AND timestamp >= NOW() - INTERVAL '$3 minutes'
    `, [userId, actionType, minutes]);

    const count = parseInt(result.rows[0].count);
    return count >= threshold;
  } catch (error) {
    logger.error('Erreur lors de la vérification de l\'activité suspecte:', error.message);
    return false;  // En cas d'erreur, on ne considère pas comme suspect
  }
};

/**
 * Enregistrer une tentative de connexion échouée
 * @param {string} email - Email de l'utilisateur tentant de se connecter
 * @param {string} ip - Adresse IP de la tentative
 * @param {string} userAgent - Navigateur de l'utilisateur
 */
const logFailedLoginAttempt = async (email, ip, userAgent) => {
  try {
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    const userId = userResult.rows.length > 0 ? userResult.rows[0].id : null;

    await pool.query(`
      INSERT INTO audit_logs (user_id, action_type, details)
      VALUES ($1, 'failed_login', $2)
    `, [userId, JSON.stringify({ email, ip, userAgent, timestamp: new Date() })]);
  } catch (error) {
    logger.error('Erreur lors de l\'enregistrement de la tentative de connexion échouée:', error.message);
  }
};

/**
 * Enregistrer une tentative d'authentification MFA échouée
 * @param {number} userId - ID de l'utilisateur
 * @param {string} ip - Adresse IP
 * @param {string} userAgent - Navigateur
 */
const logFailedMFATry = async (userId, ip, userAgent) => {
  try {
    await pool.query(`
      INSERT INTO audit_logs (user_id, action_type, details)
      VALUES ($1, 'failed_mfa_attempt', $2)
    `, [userId, JSON.stringify({ ip, userAgent, timestamp: new Date() })]);
    
    // Vérifier si l'utilisateur a trop de tentatives échouées
    const isSuspicious = await checkSuspiciousActivity(userId, 'failed_mfa_attempt', 5, 5);
    
    if (isSuspicious) {
      logger.warn(`Activité suspecte détectée pour l'utilisateur ${userId} - trop de tentatives MFA échouées`);
      // Ici, vous pourriez envisager de bloquer temporairement l'utilisateur
    }
  } catch (error) {
    logger.error('Erreur lors de l\'enregistrement de la tentative MFA échouée:', error.message);
  }
};

module.exports = {
  logAuditAction,
  checkSuspiciousActivity,
  logFailedLoginAttempt,
  logFailedMFATry
};