// Service d'authentification avec gestion de refresh token

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../../db.config');
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
    { expiresIn: '1h' } // Token valide pendant 1 heure
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

// Vérifier un refresh token
const verifyRefreshToken = async (refreshToken) => {
  try {
    const hashedToken = crypto.createHash('sha256').update(refreshToken).digest('hex');
    
    const result = await pool.query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [hashedToken]
    );
    
    if (result.rows.length === 0) {
      throw new Error('Refresh token invalide ou expiré');
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
  cleanupExpiredTokens
};