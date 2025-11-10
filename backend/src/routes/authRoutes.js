const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);
const { check, validationResult, body } = require('express-validator');
const { authenticateToken } = require('../middleware/authMiddleware');
const { refreshToken, logout } = require('../controllers/authController');
const { revokeAllUserRefreshTokens } = require('../services/authService');

const router = express.Router();

module.exports = function() {
  // Register a new user
  router.post(
    '/register',
    [
      check('email', 'Veuillez inclure un email valide').isEmail(),
      check('password', 'Le mot de passe doit faire au moins 6 caractères').isLength({ min: 6 }),
      check('role', 'Le rôle est requis').isIn(['client', 'artisan', 'commercant']),
      check('profileData', 'Les données de profil sont requises').isObject(),

      // Conditional validations for profileData based on role
      body('profileData.nom_complet', 'Le nom complet est requis').if(body('role').equals('client')).notEmpty(),
      body('profileData.location', 'La localisation est requise').if(body('role').equals('client')).optional(),
      body('profileData.telephone', 'Le numéro de téléphone est requis').if(body('role').equals('client')).optional(),
      body('profileData.sexe', 'Le sexe est requis').if(body('role').equals('client')).notEmpty(),

      body('profileData.nom_complet', 'Le nom complet est requis').if(body('role').equals('artisan')).notEmpty(),
      body('profileData.specialite', 'La spécialité est requise').if(body('role').equals('artisan')).optional(),
      body('profileData.location', 'La localisation est requise').if(body('role').equals('artisan')).optional(),
      body('profileData.telephone', 'Le numéro de téléphone est requis').if(body('role').equals('artisan')).optional(),
      body('profileData.annees_experience', 'Les années d\'expérience sont requises').if(body('role').equals('artisan')).notEmpty().isInt(),

      body('profileData.nom_entreprise', 'Le nom de l\'entreprise est requis').if(body('role').equals('commercant')).notEmpty(),
      body('profileData.type_commerce', 'Le type de commerce est requis').if(body('role').equals('commercant')).optional(),
      body('profileData.adresse', 'L\'adresse est requise').if(body('role').equals('commercant')).notEmpty(),
      body('profileData.location', 'La localisation est requise').if(body('role').equals('commercant')).optional(),
      body('profileData.telephone', 'Le numéro de téléphone est requis').if(body('role').equals('commercant')).notEmpty(),
      body('profileData.annees_experience', 'Les années d\'expérience sont requises').if(body('role').equals('commercant')).optional().isInt(),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, role, profileData, referralCode } = req.body;
      console.log('Registering user with profile data:', profileData);

      const client = await pool.connect();

      try {
        await client.query('BEGIN');

        let user = await client.query('SELECT * FROM users WHERE email = $1', [email]);
        if (user.rows.length > 0) {
          await client.query('ROLLBACK');
          return res.status(409).json({ message: 'Cet email est déjà utilisé.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUserResult = await client.query(
          'INSERT INTO users (email, password, role, referred_by) VALUES ($1, $2, $3, $4) RETURNING id, email, role',
          [email, hashedPassword, role, referralCode || null]
        );
        const newUser = newUserResult.rows[0];

        // Create profile based on role
        if (profileData) {
            switch(role) {
                case 'client':
                    await client.query('INSERT INTO client_profiles (user_id, nom_complet, sexe, location, telephone) VALUES ($1, $2, $3, $4, $5)', [
                        newUser.id,
                        profileData.nom_complet || null,
                        profileData.sexe || null,
                        profileData.location || null,
                        profileData.telephone || null
                    ]);
                    break;
                case 'artisan':
                    await client.query('INSERT INTO artisan_profiles (user_id, nom_complet, specialite, description, location, telephone, annees_experience, siret, site_web, horaires_ouverture, langues_parlees, assurance_professionnelle) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)', [
                        newUser.id,
                        profileData.nom_complet || null,
                        profileData.specialite || null,
                        profileData.description || null,
                        profileData.location || null,
                        profileData.telephone || null,
                        profileData.annees_experience || null,
                        profileData.siret || null,
                        profileData.site_web || null,
                        profileData.horaires_ouverture || null,
                        profileData.langues_parlees || null,
                        profileData.assurance_professionnelle || null
                    ]);
                    break;
                case 'commercant':
                    await client.query('INSERT INTO commercant_profiles (user_id, nom_entreprise, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, langues_parlees, assurance_professionnelle) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)', [
                        newUser.id,
                        profileData.nom_entreprise || null,
                        profileData.type_commerce || null,
                        profileData.description || null,
                        profileData.adresse || null,
                        profileData.location || null,
                        profileData.telephone || null,
                        profileData.siret || null,
                        profileData.site_web || null,
                        profileData.horaires_ouverture || null,
                        profileData.langues_parlees || null,
                        profileData.assurance_professionnelle || null
                    ]);
                    break;
            }
        }

        await client.query('COMMIT');

        const payload = {
          user: {
            id: newUser.id,
            role: newUser.role,
          },
        };

        jwt.sign(
          payload,
          process.env.JWT_SECRET,
          { expiresIn: '15m' }, // Token valide pendant 15 minutes seulement pour plus de sécurité
          (err, token) => {
            if (err) throw err;
            res.status(201).json({ message: 'Utilisateur enregistré avec succès.', token, user: newUser });
          }
        );
      } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error during registration:', err);
        res.status(500).send('Erreur du serveur lors de l\'inscription.');
      } finally {
        client.release();
      }
    }
  );

  // Authenticate user and get token (Login)
  router.post(
    '/login',
    [
      check('email', 'Veuillez inclure un email valide').isEmail(),
      check('password', 'Le mot de passe est requis').exists(),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      try {
        let userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
        }
        const user = userResult.rows[0];

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
        }

        const payload = {
          user: {
            id: user.id,
            role: user.role,
          },
        };

        jwt.sign(
          payload,
          process.env.JWT_SECRET,
          { expiresIn: '15m' }, // Token valide pendant 15 minutes seulement pour plus de sécurité
          (err, token) => {
            if (err) throw err;
            res.status(200).json({ message: 'Connexion réussie.', token, user: { id: user.id, email: user.email, role: user.role } });
          }
        );
      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
      }
    }
  );

  // Change user password
  router.post(
    '/change-password',
    [
      authenticateToken,
      check('currentPassword', 'Le mot de passe actuel est requis').not().isEmpty(),
      check('newPassword', 'Le nouveau mot de passe doit faire au moins 6 caractères').isLength({ min: 6 }),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { currentPassword, newPassword } = req.body;
      const userId = req.user.user.id; // From authenticateToken middleware

      try {
        const userResult = await pool.query('SELECT password FROM users WHERE id = $1', [userId]);
        if (userResult.rows.length === 0) {
          return res.status(404).json({ message: 'Utilisateur non trouvé.' });
        }
        const user = userResult.rows[0];

        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
          return res.status(401).json({ message: 'Le mot de passe actuel est incorrect.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);

        await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashedNewPassword, userId]);

        // Révoquer tous les refresh tokens de l'utilisateur pour forcer la déconnexion sur tous les appareils
        await revokeAllUserRefreshTokens(userId);

        res.status(200).json({ message: 'Mot de passe mis à jour avec succès.' });

      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
      }
    }
  );

  // Rafraîchir le token
  router.post('/refresh-token', refreshToken);

  // Déconnexion
  router.post('/logout', logout);

  return router;
};