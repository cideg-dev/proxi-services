// Service d'authentification avec gestion de refresh token

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);
const logger = require('../utils/logger');

// Générer un token JWT
const generateToken = (user) => {
  return jwt.sign(
    { 
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      }
    },
    process.env.JWT_SECRET,
    { expiresIn: '15m' } // Token valide pendant 15 minutes seulement pour plus de sécurité
  );
};

// Générer un refresh token
const generateRefreshToken = (user) => {
  const refreshToken = crypto.randomBytes(64).toString('hex');
  
  // Sauvegarder le refresh token dans la base de données
  // En production, vous voudrez peut-être utiliser Redis pour une meilleure performance
  const hashedToken = crypto.createHash('sha256').update(refreshToken).digest('hex');
  
  // Stocker le refresh token avec l'utilisateur
  pool.query(
    'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, NOW() + INTERVAL \'7 days\')',
    [user.id, hashedToken]
  ).catch(err => {
    logger.error('Erreur lors de la sauvegarde du refresh token:', err.message);
  });
  
  return refreshToken;
};

// Vérifier un refresh token et l'utilisateur associé
const verifyRefreshToken = async (refreshToken) => {
  try {
    const hashedToken = crypto.createHash('sha256').update(refreshToken).digest('hex');

    // Vérifiez que le refresh token existe et n'est pas expiré
    const result = await pool.query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [hashedToken]
    );

    if (result.rows.length === 0) {
      throw new Error('Refresh token invalide ou expiré');
    }

    // Vérifiez que l'utilisateur existe et n'est pas bloqué
    const userResult = await pool.query(
      'SELECT id, email, role, is_blocked FROM users WHERE id = $1',
      [result.rows[0].user_id]
    );

    if (userResult.rows.length === 0 || userResult.rows[0].is_blocked) {
      // Si l'utilisateur n'existe plus ou est bloqué, supprimez le refresh token
      await pool.query('DELETE FROM refresh_tokens WHERE token = $1', [hashedToken]);
      throw new Error('Compte utilisateur invalide ou bloqué');
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Erreur lors de la vérification du refresh token:', error.message);
    throw error;
  }
};

// Révoquer un refresh token (lors de la déconnexion)
const revokeRefreshToken = async (refreshToken) => {
  try {
    const hashedToken = crypto.createHash('sha256').update(refreshToken).digest('hex');
    
    await pool.query(
      'DELETE FROM refresh_tokens WHERE token = $1',
      [hashedToken]
    );
  } catch (error) {
    logger.error('Erreur lors de la révocation du refresh token:', error.message);
  }
};

// Révoquer tous les refresh tokens d'un utilisateur (par exemple lors de la modification du mot de passe)
const revokeAllUserRefreshTokens = async (userId) => {
  try {
    await pool.query(
      'DELETE FROM refresh_tokens WHERE user_id = $1',
      [userId]
    );
    logger.info(`Tous les refresh tokens révoqués pour l'utilisateur ${userId}`);
  } catch (error) {
    logger.error('Erreur lors de la révocation de tous les refresh tokens:', error.message);
  }
};

// Supprimer les refresh tokens expirés
const cleanupExpiredTokens = async () => {
  try {
    await pool.query('DELETE FROM refresh_tokens WHERE expires_at <= NOW()');
  } catch (error) {
    logger.error('Erreur lors du nettoyage des refresh tokens expirés:', error.message);
  }
};

// Exécuter le nettoyage toutes les 24 heures
setInterval(cleanupExpiredTokens, 24 * 60 * 60 * 1000); // 24 heures

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
  revokeAllUserRefreshTokens, // Ajout de cette nouvelle fonction
  cleanupExpiredTokens
};