// backend/src/controllers/authController.js
const { generateToken, generateRefreshToken, verifyToken, verifyRefreshToken } = require('../services/jwtService');
const { logger } = require('../utils/logger');
const TokenBlacklistService = require('../services/tokenBlacklistService');
const pool = require('../../db.config');

const authController = {
  // Contrôleur pour rafraîchir le token
  async refreshToken(req, res) {
    const refreshToken = req.body.refreshToken || req.query.refreshToken || req.headers['x-refresh-token'];

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token requis'
      });
    }

    try {
      // Vérifier si le refresh token est dans la liste noire
      const isBlacklisted = await TokenBlacklistService.isBlacklisted(refreshToken);
      if (isBlacklisted) {
        return res.status(401).json({
          success: false,
          message: 'Refresh token révoqué'
        });
      }

      // Vérifier le refresh token
      const decoded = verifyRefreshToken(refreshToken);

      // Vérifier que l'utilisateur existe toujours
      const userResult = await pool.query('SELECT id, role, email, is_active, is_blocked FROM users WHERE id = $1', [decoded.userId]);

      if (userResult.rows.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Utilisateur non trouvé'
        });
      }

      const user = userResult.rows[0];

      // Vérifier si l'utilisateur est bloqué
      if (user.is_blocked) {
        return res.status(401).json({
          success: false,
          message: 'Votre compte est bloqué'
        });
      }

      // Générer un nouveau token d'accès
      const newToken = generateToken({ id: user.id, email: user.email, role: user.role });

      logger.info('TOKEN_REFRESHED', {
        userId: user.id,
        ip: req.ip || req.connection.remoteAddress,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString()
      });

      return res.json({
        success: true,
        token: newToken,
        refreshToken: refreshToken // Peut être le même ou un nouveau selon la stratégie
      });

    } catch (error) {
      logger.error('TOKEN_REFRESH_ERROR', {
        error: error.message,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });

      return res.status(401).json({
        success: false,
        message: 'Refresh token invalide'
      });
    }
  },

  // Contrôleur pour déconnexion avec révocation du token
  async logout(req, res) {
    try {
      // Récupérer le token de la requête
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

      if (token) {
        // Déterminer le temps restant avant l'expiration du token
        const decoded = require('jsonwebtoken').decode(token);
        const expirationTime = decoded.exp - Math.floor(Date.now() / 1000);

        // Ajouter le token à la liste noire
        const success = await TokenBlacklistService.addToBlacklist(token, expirationTime);

        if (success) {
          logger.info('LOGOUT_SUCCESS', {
            userId: req.user.id,
            ip: req.ip || req.connection.remoteAddress,
            timestamp: new Date().toISOString()
          });

          return res.status(200).json({
            success: true,
            message: 'Déconnexion réussie'
          });
        }
      }

      res.status(200).json({
        success: true,
        message: 'Déconnexion réussie'
      });
    } catch (error) {
      logger.error('LOGOUT_ERROR', {
        userId: req.user ? req.user.id : 'unknown',
        error: error.message,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });

      res.status(500).json({
        success: false,
        message: 'Erreur lors de la déconnexion'
      });
    }
  }
};

module.exports = authController;