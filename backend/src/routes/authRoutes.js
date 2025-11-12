const { Router } = require('express');
const { hashPassword, comparePassword, generateToken, generateRefreshToken } = require('../services/jwtService');
const { logger } = require('../utils/logger');
const TokenBlacklistService = require('../services/tokenBlacklistService');
const EncryptionService = require('../services/encryptionService');
const { pool } = require('../../db.config');

const router = Router();

// Middleware de validation pour les routes d'authentification
const { handleValidationErrors, authValidator } = require('../middleware/validationMiddleware');

/**
 * Endpoint de déconnexion
 */
router.post('/logout', require('../middleware/authMiddleware').authenticateToken, async (req, res) => {
  try {
    // Récupérer le token de l'en-tête
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
});

/**
 * Endpoint de déconnexion de toutes les sessions
 */
router.post('/logout-all', require('../middleware/authMiddleware').authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Révoquer tous les tokens de l'utilisateur
    const success = await TokenBlacklistService.revokeAllTokens(userId);
    
    if (success) {
      logger.info('LOGOUT_ALL_SESSIONS_SUCCESS', {
        userId: req.user.id,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });
      
      return res.status(200).json({
        success: true,
        message: 'Déconnexion de toutes les sessions réussie'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la déconnexion de toutes les sessions'
    });
  } catch (error) {
    logger.error('LOGOUT_ALL_SESSIONS_ERROR', {
      userId: req.user ? req.user.id : 'unknown',
      error: error.message,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la déconnexion de toutes les sessions'
    });
  }
});

/**
 * Endpoint pour déconnecter les autres sessions (garde la session actuelle)
 */
router.post('/logout-others', require('../middleware/authMiddleware').authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Récupérer le token actuel de la requête
    const authHeader = req.headers['authorization'];
    const currentToken = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
    
    // Révoquer tous les tokens sauf le token actuel
    const success = await TokenBlacklistService.revokeOtherTokens(userId, currentToken);
    
    if (success) {
      logger.info('LOGOUT_OTHER_SESSIONS_SUCCESS', {
        userId: req.user.id,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });
      
      return res.status(200).json({
        success: true,
        message: 'Déconnexion des autres sessions réussie'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la déconnexion des autres sessions'
    });
  } catch (error) {
    logger.error('LOGOUT_OTHER_SESSIONS_ERROR', {
      userId: req.user ? req.user.id : 'unknown',
      error: error.message,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la déconnexion des autres sessions'
    });
  }
});

module.exports = () => {
  return router;
};