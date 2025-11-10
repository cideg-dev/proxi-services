// Routes pour l'accès aux logs d'audit (réservées aux administrateurs)

const express = require('express');
const router = express.Router();
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const { body, validationResult } = require('express-validator');
const path = require('path');
const dbConfigPath = path.join(__dirname, '..', 'db.config');
const pool = require(dbConfigPath);

// @route   GET /api/audit/logs
// @desc    Récupérer les logs d'audit (admin seulement)
// @access  Private - Admin
router.get('/audit/logs', [
  authenticateToken,
  authorizeRole(['admin'])
], async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;
    
    // Filtres optionnels
    const userId = req.query.userId ? parseInt(req.query.userId) : null;
    const actionType = req.query.actionType || null;
    const dateFrom = req.query.dateFrom || null;
    const dateTo = req.query.dateTo || null;
    
    let query = `
      SELECT al.*, COALESCE(ap.nom_complet, cp.nom_entreprise, u.email) as user_display_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles cp ON u.id = cp.user_id
    `;
    
    const params = [];
    let whereClause = [];
    
    if (userId) {
      whereClause.push(`al.user_id = $${params.length + 1}`);
      params.push(userId);
    }
    
    if (actionType) {
      whereClause.push(`al.action_type = $${params.length + 1}`);
      params.push(actionType);
    }
    
    if (dateFrom) {
      whereClause.push(`al.timestamp >= $${params.length + 1}`);
      params.push(dateFrom);
    }
    
    if (dateTo) {
      whereClause.push(`al.timestamp <= $${params.length + 1}`);
      params.push(dateTo);
    }
    
    if (whereClause.length > 0) {
      query += ' WHERE ' + whereClause.join(' AND ');
    }
    
    query += ' ORDER BY al.timestamp DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(limit, offset);
    
    const result = await pool.query(query, params);
    
    // Compter le nombre total de logs pour la pagination
    let countQuery = 'SELECT COUNT(*) FROM audit_logs';
    let countParams = [];
    if (whereClause.length > 0) {
      countQuery += ' WHERE ' + whereClause.join(' AND ');
    }
    const countResult = await pool.query(countQuery, countParams);
    const totalLogs = parseInt(countResult.rows[0].count);
    
    res.json({
      logs: result.rows,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalLogs / limit),
        totalLogs: totalLogs,
        hasNext: page * limit < totalLogs,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des logs d\'audit:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des logs d\'audit.' });
  }
});

// @route   GET /api/audit/user/:userId
// @desc    Récupérer les logs d'audit pour un utilisateur spécifique
// @access  Private - Admin
router.get('/audit/user/:userId', [
  authenticateToken,
  authorizeRole(['admin']),
  body('userId', 'ID utilisateur invalide').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = parseInt(req.params.userId);
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;
    
    const result = await pool.query(`
      SELECT al.*, COALESCE(ap.nom_complet, cp.nom_entreprise, u.email) as user_display_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles cp ON u.id = cp.user_id
      WHERE al.user_id = $1
      ORDER BY al.timestamp DESC
      LIMIT $2 OFFSET $3
    `, [userId, limit, offset]);
    
    // Compter le nombre total de logs pour la pagination
    const countResult = await pool.query(
      'SELECT COUNT(*) FROM audit_logs WHERE user_id = $1', 
      [userId]
    );
    const totalLogs = parseInt(countResult.rows[0].count);
    
    res.json({
      logs: result.rows,
      user: { id: userId },
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalLogs / limit),
        totalLogs: totalLogs,
        hasNext: page * limit < totalLogs,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des logs utilisateur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des logs utilisateur.' });
  }
});

module.exports = router;