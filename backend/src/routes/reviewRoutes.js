const express = require('express');
const pool = require('../../db.config');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const { check, validationResult } = require('express-validator');

const router = express.Router();

module.exports = function(io, connectedUsers) {
  // Add a review for an artisan
  router.post(
    '/',
    [
      authenticateToken,
      authorizeRole(['client']),
      check('artisanId', 'L\'ID de l\'artisan est requis').not().isEmpty(),
      check('rating', 'La note est requise').isFloat({ min: 1, max: 5 }),
      check('comment', 'Le commentaire est requis').not().isEmpty(),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { artisanId, rating, comment } = req.body;
      const clientId = req.user.user.id;

      try {
        const newReviewResult = await pool.query(
          'INSERT INTO reviews (artisan_id, client_id, rating, comment) VALUES ($1, $2, $3, $4) RETURNING *',
          [artisanId, clientId, rating, comment]
        );
        const newReview = newReviewResult.rows[0];

        // Notify the artisan in real-time
        const artisanSocket = connectedUsers.get(artisanId.toString());
        if (artisanSocket) {
          io.to(artisanSocket.socketId).emit('new_review', newReview);
        }

        res.json(newReview);
      } catch (err) {
        console.error(err.message);
        res.status(500).send('Erreur du serveur');
      }
    }
  );

  return router;
};