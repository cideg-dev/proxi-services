const { Router } = require('express');
const { hashPassword, comparePassword, generateToken, generateRefreshToken } = require('../services/jwtService');
const { logger } = require('../utils/logger');
const TokenBlacklistService = require('../services/tokenBlacklistService');
const EncryptionService = require('../services/encryptionService');
const { pool } = require('../../db.config');
const { body, validationResult } = require('express-validator');

const router = Router();

// Middleware de validation pour les routes d'authentification
const { handleValidationErrors, authValidator } = require('../middleware/validationMiddleware');

/**
 * Endpoint d'inscription
 */
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('role').isIn(['client', 'artisan', 'commercant']),
  body('profileData').isObject()
], handleValidationErrors, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, role, profileData, referralCode } = req.body;

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ message: 'Un utilisateur avec cet email existe déjà.' });
    }

    // Hasher le mot de passe
    const hashedPassword = await hashPassword(password);

    // Commencer une transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Créer l'utilisateur
      const userResult = await client.query(
        'INSERT INTO users (email, password, role) VALUES ($1, $2, $3) RETURNING id, email, role',
        [email, hashedPassword, role]
      );
      const user = userResult.rows[0];

      // Créer le profil en fonction du rôle
      if (role === 'client') {
        await client.query(
          `INSERT INTO client_profiles (user_id, nom_complet, sexe, location, telephone, adresse)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            user.id,
            profileData.nom_complet || null,
            profileData.sexe || null,
            profileData.location || null,
            profileData.telephone || null,
            profileData.adresse || null
          ]
        );
      } else if (role === 'artisan') {
        await client.query(
          `INSERT INTO artisan_profiles (user_id, nom_complet, sexe, specialite, description, location,
           telephone, annees_experience, siret, site_web, horaires_ouverture, assurance_professionnelle)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
          [
            user.id,
            profileData.nom_complet || null,
            profileData.sexe || null,
            profileData.specialite || null,
            profileData.description || null,
            profileData.location || null,
            profileData.telephone || null,
            profileData.annees_experience ? parseInt(profileData.annees_experience) : null,
            profileData.siret || null,
            profileData.site_web || null,
            profileData.horaires_ouverture || null,
            profileData.assurance_professionnelle || false
          ]
        );
      } else if (role === 'commercant') {
        await client.query(
          `INSERT INTO commercant_profiles (user_id, nom_entreprise, sexe_contact, type_commerce, description,
           adresse, location, telephone, siret, site_web, horaires_ouverture, assurance_professionnelle)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
          [
            user.id,
            profileData.nom_entreprise || null,
            profileData.sexe_contact || null,
            profileData.type_commerce || null,
            profileData.description || null,
            profileData.adresse || null,
            profileData.location || null,
            profileData.telephone || null,
            profileData.siret || null,
            profileData.site_web || null,
            profileData.horaires_ouverture || null,
            profileData.assurance_professionnelle || false
          ]
        );
      }

      // Générer les tokens
      const token = generateToken({ id: user.id, email: user.email, role: user.role });
      const refreshToken = generateRefreshToken({ id: user.id, email: user.email, role: user.role });

      await client.query('COMMIT');

      logger.info('INSCRIPTION_REUSSIE', {
        userId: user.id,
        email: user.email,
        role: user.role,
        ip: req.ip || req.connection.remoteAddress,
        timestamp: new Date().toISOString()
      });

      res.status(201).json({
        token,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        }
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    logger.error('ERREUR_INSCRIPTION', {
      email: req.body?.email,
      role: req.body?.role,
      error: error.message,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });

    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'inscription'
    });
  }
});

/**
 * Endpoint de connexion
 */
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').exists()
], handleValidationErrors, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Rechercher l'utilisateur
    const userResult = await pool.query(
      'SELECT id, email, password, role, is_blocked FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    const user = userResult.rows[0];

    // Vérifier si l'utilisateur est bloqué
    if (user.is_blocked) {
      return res.status(401).json({ message: 'Votre compte a été bloqué.' });
    }

    // Vérifier le mot de passe
    const isPasswordValid = await comparePassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    // Générer les tokens
    const token = generateToken({ id: user.id, email: user.email, role: user.role });
    const refreshToken = generateRefreshToken({ id: user.id, email: user.email, role: user.role });

    logger.info('CONNEXION_REUSSIE', {
      userId: user.id,
      email: user.email,
      role: user.role,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });

    res.json({
      token,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    logger.error('ERREUR_CONNEXION', {
      email: req.body?.email,
      error: error.message,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });

    res.status(500).json({
      success: false,
      message: 'Erreur lors de la connexion'
    });
  }
});

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