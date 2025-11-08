// Routes pour la gestion des signalements

const express = require('express');
const { check, validationResult, body } = require('express-validator');
const logger = require('../utils/logger');
const pool = require('../../db.config');

const router = express.Router();

// POST / - Soumettre un nouveau signalement
router.post('/', 
  [
    check('report_type', 'Le type de signalement est requis.').notEmpty(),
    check('reason', 'La raison du signalement est requise.').notEmpty(),
    // Au moins un des IDs signalés doit être présent
    body().custom((value, { req }) => {
      const { reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id } = req.body;
      if (!reported_user_id && !reported_message_id && !reported_review_id && !reported_portfolio_item_id) {
        throw new Error('Au moins un ID d\'entité signalée (utilisateur, message, avis, ou élément de portfolio) est requis.');
      }
      return true;
    }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const reporterId = req.user.user.id;
    const { report_type, reason, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id } = req.body;

    try {
      const result = await pool.query(
        `INSERT INTO reports (reporter_id, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id, report_type, reason, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending') RETURNING *`,
        [reporterId, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id, report_type, reason]
      );
      const newReport = result.rows[0];

      res.status(201).json({ message: 'Signalement soumis avec succès.', report: newReport });
    } catch (error) {
      logger.error('Erreur lors de la soumission du signalement :', { error: error.message });
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });

module.exports = router;