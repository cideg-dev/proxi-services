// Service pour la gestion de l'authentification multifactorielle (MFA)
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const path = require('path');
const dbConfigPath = path.join(__dirname, '..', 'db.config');
const pool = require(dbConfigPath);
const logger = require('../utils/logger');

/**
 * Générer une clé secrète MFA pour un utilisateur
 * @param {number} userId - ID de l'utilisateur
 * @param {string} email - Email de l'utilisateur pour l'identifiant QR
 * @returns {Promise<Object>} - L'objet contenant la clé secrète et l'URL QR
 */
const generateMFASecret = async (userId, email) => {
  try {
    // Générer une nouvelle clé secrète
    const secret = speakeasy.generateSecret({
      name: `Proxi-Services:${email}`,
      issuer: 'Proxi-Services',
      length: 32
    });

    // Mettre à jour le profil utilisateur avec la clé secrète
    await pool.query(
      'UPDATE users SET mfa_secret = $1 WHERE id = $2',
      [secret.base32, userId]
    );

    // Générer l'URL pour le QR code
    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

    return {
      secret: secret.base32,
      qrCodeUrl: qrCodeUrl,
      otpauthUrl: secret.otpauth_url
    };
  } catch (error) {
    logger.error('Erreur lors de la génération de la clé MFA:', error.message);
    throw error;
  }
};

/**
 * Vérifier un code MFA
 * @param {string} secret - Clé secrète de l'utilisateur
 * @param {string} token - Code à 6 chiffres fourni par l'utilisateur
 * @returns {boolean} - Si le code est valide
 */
const verifyMFACode = (secret, token) => {
  try {
    const verified = speakeasy.totp.verify({
      secret: secret,
      encoding: 'base32',
      token: token,
      window: 2 // Tolérance de 2 périodes (30 secondes chacune)
    });
    return verified;
  } catch (error) {
    logger.error('Erreur lors de la vérification du code MFA:', error.message);
    return false;
  }
};

/**
 * Activer l'authentification MFA pour un utilisateur
 * @param {number} userId - ID de l'utilisateur
 * @returns {Promise<boolean>} - Si l'activation a réussi
 */
const enableMFA = async (userId) => {
  try {
    // Vérifier que la clé secrète existe
    const userResult = await pool.query(
      'SELECT mfa_secret FROM users WHERE id = $1',
      [userId]
    );

    if (!userResult.rows[0] || !userResult.rows[0].mfa_secret) {
      throw new Error('Aucune clé MFA configurée pour cet utilisateur');
    }

    // Activer la vérification MFA
    await pool.query(
      'UPDATE users SET mfa_enabled = true WHERE id = $1',
      [userId]
    );

    logger.info(`MFA activé pour l'utilisateur ${userId}`);
    return true;
  } catch (error) {
    logger.error('Erreur lors de l\'activation de la MFA:', error.message);
    throw error;
  }
};

/**
 * Désactiver l'authentification MFA pour un utilisateur
 * @param {number} userId - ID de l'utilisateur
 * @returns {Promise<boolean>} - Si la désactivation a réussi
 */
const disableMFA = async (userId) => {
  try {
    await pool.query(
      'UPDATE users SET mfa_enabled = false WHERE id = $1',
      [userId]
    );

    logger.info(`MFA désactivé pour l'utilisateur ${userId}`);
    return true;
  } catch (error) {
    logger.error('Erreur lors de la désactivation de la MFA:', error.message);
    throw error;
  }
};

/**
 * Vérifier si l'utilisateur a MFA activé
 * @param {number} userId - ID de l'utilisateur
 * @returns {Promise<boolean>} - Si MFA est activé
 */
const isMFAEnabled = async (userId) => {
  try {
    const userResult = await pool.query(
      'SELECT mfa_enabled FROM users WHERE id = $1',
      [userId]
    );

    return userResult.rows[0] && userResult.rows[0].mfa_enabled;
  } catch (error) {
    logger.error('Erreur lors de la vérification de l\'état MFA:', error.message);
    return false;
  }
};

module.exports = {
  generateMFASecret,
  verifyMFACode,
  enableMFA,
  disableMFA,
  isMFAEnabled
};