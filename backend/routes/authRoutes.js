const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db.config');
const { check, validationResult } = require('express-validator');

const router = express.Router();

module.exports = function() {
  // Register a new user
  router.post(
    '/register',
    [
      check('email', 'Veuillez inclure un email valide').isEmail(),
      check('password', 'Le mot de passe doit faire au moins 6 caractères').isLength({ min: 6 }),
      check('role', 'Le rôle est requis').isIn(['client', 'artisan', 'commercant']),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, role } = req.body;

      try {
        let user = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (user.rows.length > 0) {
          return res.status(400).json({ message: 'Cet utilisateur existe déjà.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUserResult = await pool.query(
          'INSERT INTO users (email, password, role) VALUES ($1, $2, $3) RETURNING id, email, role',
          [email, hashedPassword, role]
        );
        const newUser = newUserResult.rows[0];

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
            res.json({ token, user: newUser });
          }
        );
      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
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
          return res.status(400).json({ message: 'Identifiants invalides.' });
        }
        const user = userResult.rows[0];

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
          return res.status(400).json({ message: 'Identifiants invalides.' });
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
            res.json({ token, user: { id: user.id, role: user.role } });
          }
        );
      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
      }
    }
  );

  return router;
};
