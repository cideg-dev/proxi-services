// Routes pour la gestion des demandes de service

const express = require('express');
const { check, validationResult } = require('express-validator');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const logger = require('../utils/logger');
const pool = require('../../db.config');

const router = express.Router();

// POST / - Créer une nouvelle demande de service
router.post('/', authorizeRole(['client']),
  [
    check('artisanId', 'L\'ID de l\'artisan est requis et doit être un entier').isInt(),
    check('serviceDescription', 'La description du service est requise').optional().isLength({ min: 1, max: 1000 }),
    check('serviceIds', 'Les IDs de service doivent être un tableau d\'entiers').optional().isArray()
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { artisanId, serviceDescription, serviceIds } = req.body;
    const clientId = req.user.user.id;

    try {
      // Vérifier que l'artisan existe et a le bon rôle
      const artisanCheck = await pool.query('SELECT id FROM users WHERE id = $1 AND role = \'artisan\'', [artisanId]);
      if (artisanCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Artisan non trouvé.' });
      }

      // Si serviceIds est fourni, vérifier qu'ils existent pour l'artisan donné
      if (serviceIds && serviceIds.length > 0) {
        const serviceCheck = await pool.query(
          'SELECT id FROM services WHERE artisan_id = $1 AND id = ANY($2::int[])',
          [artisanId, serviceIds]
        );
        if (serviceCheck.rows.length !== serviceIds.length) {
          return res.status(400).json({ message: 'Un ou plusieurs services demandés n\'existent pas pour cet artisan.' });
        }
      }

      const result = await pool.query(
        `INSERT INTO demandes (client_id, artisan_id, service_ids, service_description, status)
         VALUES ($1, $2, $3, $4, $5) RETURNING id, client_id, artisan_id, service_ids, service_description, status, created_at, updated_at`,
        [
          clientId,
          artisanId,
          serviceIds || null, // Stocker en tant que tableau ou null
          serviceDescription || null,
          'pending'
        ]
      );
      const newDemande = result.rows[0];

      // Notifier le professionnel en temps réel
      const professionalSocketData = req.connectedUsers.get(artisanId.toString());
      if (professionalSocketData) {
        req.io.to(professionalSocketData.socketId).emit('new-demand', newDemande);
      }

      res.status(201).json({ message: 'Demande de service créée avec succès.', demande: newDemande });
    } catch (error) {
      logger.error('Erreur lors de la création de la demande :', { error: error.message });
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });

module.exports = router;