const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db.config');
const { check, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/authMiddleware');

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
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, role, profileData } = req.body;

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
          'INSERT INTO users (email, password, role) VALUES ($1, $2, $3) RETURNING id, email, role',
          [email, hashedPassword, role]
        );
        const newUser = newUserResult.rows[0];

        // Create profile based on role
        let profileTable;
        let profileColumns;

        switch (role) {
          case 'client':
            profileTable = 'client_profiles';
            profileColumns = ['nom_complet', 'sexe', 'location', 'telephone', 'adresse'];
            break;
          case 'artisan':
            profileTable = 'artisan_profiles';
            profileColumns = ['nom_complet', 'specialite', 'description', 'location', 'telephone', 'annees_experience', 'siret', 'site_web', 'horaires_ouverture', 'langues_parlees', 'assurance_professionnelle'];
            break;
          case 'commercant':
            profileTable = 'commercant_profiles';
            // Note: commercant_profiles has nom_entreprise, not nom_complet. Assuming it's passed in profileData.
            profileColumns = ['nom_entreprise', 'type_commerce', 'description', 'adresse', 'location', 'telephone', 'siret', 'site_web', 'horaires_ouverture', 'langues_parlees', 'assurance_professionnelle'];
            break;
        }

        if (profileTable) {
            const filteredProfileData = Object.keys(profileData)
                .filter(key => profileColumns.includes(key) && profileData[key] != null)
                .reduce((obj, key) => {
                    obj[key] = profileData[key];
                    return obj;
                }, {});

            const columns = ['user_id', ...Object.keys(filteredProfileData)];
            const values = [newUser.id, ...Object.values(filteredProfileData)];
            const valuePlaceholders = values.map((_, i) => `$${i + 1}`).join(', ');

            const profileInsertQuery = `INSERT INTO ${profileTable} (${columns.join(', ')}) VALUES (${valuePlaceholders})`;
            await client.query(profileInsertQuery, values);
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
          { expiresIn: '5h' },
          (err, token) => {
            if (err) throw err;
            res.status(201).json({ message: 'Utilisateur enregistré avec succès.', token, user: newUser });
          }
        );
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(err.message);
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
          { expiresIn: '5h' },
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

        res.status(200).json({ message: 'Mot de passe mis à jour avec succès.' });

      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
      }
    }
  );

  return router;
};
