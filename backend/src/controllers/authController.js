// Contrôleur pour les fonctionnalités d'authentification

const bcrypt = require('bcrypt');
const { generateToken, generateRefreshToken, verifyRefreshToken, revokeRefreshToken } = require('../services/authService');
const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);
const logger = require('../utils/logger');

// Rafraîchir un token JWT à partir d'un refresh token
const refreshToken = async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ message: 'Refresh token requis.' });
  }

  try {
    // Vérifier le refresh token
    const tokenRecord = await verifyRefreshToken(refreshToken);
    
    // Récupérer l'utilisateur
    const userResult = await pool.query(
      'SELECT id, email, role FROM users WHERE id = $1',
      [tokenRecord.user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(403).json({ message: 'Utilisateur non trouvé.' });
    }

    const user = userResult.rows[0];

    // Générer un nouveau token d'accès
    const newAccessToken = generateToken({ id: user.id, email: user.email, role: user.role });
    
    // Générer un nouveau refresh token (optionnel - pour une sécurité renforcée)
    const newRefreshToken = generateRefreshToken(user);

    // Révoquer l'ancien refresh token
    await revokeRefreshToken(refreshToken);

    res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });

  } catch (error) {
    logger.error('Erreur lors du rafraîchissement du token:', { error: error.message });
    res.status(403).json({ message: 'Impossible de rafraîchir le token.' });
  }
};

// Déconnexion (révoque le refresh token)
const logout = async (req, res) => {
  const { refreshToken } = req.body;

  if (refreshToken) {
    try {
      await revokeRefreshToken(refreshToken);
    } catch (error) {
      logger.error('Erreur lors de la révocation du refresh token:', { error: error.message });
      // On continue même en cas d'erreur
    }
  }

  res.status(200).json({ message: 'Déconnexion réussie.' });
};

module.exports = {
  refreshToken,
  logout
};