// Routes pour les fonctionnalités d'administration

const express = require('express');
const { check, validationResult } = require('express-validator');
const logger = require('../utils/logger');
const pool = require('../../db.config');

const router = express.Router();

// GET /reports - Récupérer tous les signalements (pour le panneau d'administration)
router.get('/reports', [
  check('page').optional().isInt({ min: 1 }).withMessage('Page doit être un entier positif').toInt(),
  check('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limite doit être un entier entre 1 et 100').toInt(),
  check('status').optional().isIn(['pending', 'resolved', 'rejected']).withMessage('Statut invalide'),
  check('report_type').optional().isString().withMessage('Type de rapport doit être une chaîne'),
  check('search').optional().isString().withMessage('Recherche doit être une chaîne').trim().escape(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const { status, report_type, search = '' } = req.query;
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT
        r.id,
        r.reason,
        r.status,
        r.report_type,
        r.created_at,
        r.resolved_at,
        r.reporter_id,
        r.reported_user_id,
        r.reported_message_id,
        r.reported_review_id,
        r.reported_portfolio_item_id,
        reporter.email AS reporter_email,
        COALESCE(reporter_cp.nom_complet, reporter_ap.nom_complet, reporter_comp.nom_entreprise) AS reporter_name,
        reported_user.email AS reported_user_email,
        COALESCE(reported_user_cp.nom_complet, reported_user_ap.nom_complet, reported_user_comp.nom_entreprise) AS reported_user_name
      FROM reports r
      JOIN users reporter ON r.reporter_id = reporter.id
      LEFT JOIN client_profiles reporter_cp ON reporter.id = reporter_cp.user_id
      LEFT JOIN artisan_profiles reporter_ap ON reporter.id = reporter_ap.user_id
      LEFT JOIN commercant_profiles reporter_comp ON reporter.id = reporter_comp.user_id
      LEFT JOIN users reported_user ON r.reported_user_id = reported_user.id
      LEFT JOIN client_profiles reported_user_cp ON reported_user.id = reported_user_cp.user_id
      LEFT JOIN artisan_profiles reported_user_ap ON reported_user.id = reported_user_ap.user_id
      LEFT JOIN commercant_profiles reported_user_comp ON reported_user.id = reported_user_comp.user_id
      WHERE 1=1
    `;

    let countQuery = `
      SELECT COUNT(*) 
      FROM reports r
      JOIN users reporter ON r.reporter_id = reporter.id
      LEFT JOIN client_profiles reporter_cp ON reporter.id = reporter_cp.user_id
      LEFT JOIN artisan_profiles reporter_ap ON reporter.id = reporter_ap.user_id
      LEFT JOIN commercant_profiles reporter_comp ON reporter.id = reporter_comp.user_id
      LEFT JOIN users reported_user ON r.reported_user_id = reported_user.id
      LEFT JOIN client_profiles reported_user_cp ON reported_user.id = reported_user_cp.user_id
      LEFT JOIN artisan_profiles reported_user_ap ON reported_user.id = reported_user_ap.user_id
      LEFT JOIN commercant_profiles reported_user_comp ON reported_user.id = reported_user_comp.user_id
      WHERE 1=1
    `;

    const params = [];
    const countParams = [];

    if (status) {
      query += ` AND r.status = $${params.length + 1}`;
      countQuery += ` AND r.status = $${countParams.length + 1}`;
      params.push(status);
      countParams.push(status);
    }

    if (report_type) {
      query += ` AND r.report_type = $${params.length + 1}`;
      countQuery += ` AND r.report_type = $${countParams.length + 1}`;
      params.push(report_type);
      countParams.push(report_type);
    }

    if (search) {
      query += ` AND (r.reason ILIKE $${params.length + 1} OR reporter.email ILIKE $${params.length + 2} OR reported_user.email ILIKE $${params.length + 3})`;
      countQuery += ` AND (r.reason ILIKE $${countParams.length + 1} OR reporter.email ILIKE $${countParams.length + 2} OR reported_user.email ILIKE $${countParams.length + 3})`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
      countParams.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY r.created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(limit, offset);

    const [reportsResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, countParams)
    ]);

    const reports = reportsResult.rows;
    const total = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(total / limit);

    res.json({
      reports,
      pagination: {
        current: page,
        pages: totalPages,
        total: total,
        limit: limit,
      }
    });
  } catch (error) {
    logger.error('Erreur lors de la récupération des signalements :', { error: error.message });
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

module.exports = router;