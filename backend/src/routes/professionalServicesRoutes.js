// Routes pour les services des professionnels

const express = require('express');
const router = express.Router();
const path = require('path');

// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);

const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const { 
  getServices,
  addService,
  updateService,
  deleteService
} = require('../controllers/serviceController');

// @route   GET /api/artisans/:artisanId/services
// @desc    Get all services for an artisan
// @access  Public
router.get('/artisans/:artisanId/services', (req, res) => {
  // On appelle la fonction sans authentification car c'est accessible publiquement
  getServices(req, res);
});

// @route   POST /api/artisans/:artisanId/services
// @desc    Add a service
// @access  Private (artisan only)
router.post('/artisans/:artisanId/services', authenticateToken, authorizeRole(['artisan', 'commercant']), (req, res) => {
  // Ici, artisanId dans l'URL doit correspondre à l'utilisateur authentifié
  if (parseInt(req.params.artisanId) !== req.user.user.id) {
    return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez ajouter des services que pour votre propre profil.' });
  }
  addService(req, res);
});

// @route   PUT /api/artisans/:artisanId/services/:serviceId
// @desc    Update a service
// @access  Private (artisan only)
router.put('/artisans/:artisanId/services/:serviceId', authenticateToken, authorizeRole(['artisan', 'commercant']), (req, res) => {
  if (parseInt(req.params.artisanId) !== req.user.user.id) {
    return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez modifier que vos propres services.' });
  }
  updateService(req, res);
});

// @route   DELETE /api/artisans/:artisanId/services/:serviceId
// @desc    Delete a service
// @access  Private (artisan only)
router.delete('/artisans/:artisanId/services/:serviceId', authenticateToken, authorizeRole(['artisan', 'commercant']), (req, res) => {
  if (parseInt(req.params.artisanId) !== req.user.user.id) {
    return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez supprimer que vos propres services.' });
  }
  deleteService(req, res);
});

module.exports = router;