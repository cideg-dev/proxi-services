// Routes pour les fonctionnalités générales de l'application

const express = require('express');
const router = express.Router();
const path = require('path');

// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);

const { authenticateToken } = require('../middleware/authMiddleware');
const { 
  getAllUsers, 
  getFeaturedProfessionals, 
  getProfessionalDemandes 
} = require('../controllers/generalFeaturesController');

// GET /api/users/all - Récupérer tous les utilisateurs
router.get('/users/all', authenticateToken, getAllUsers);

// GET /api/professionals/featured - Récupérer les professionnels mis en avant
router.get('/professionals/featured', getFeaturedProfessionals);

// GET /api/professional/demandes - Récupérer les demandes pour un professionnel
router.get('/professional/demandes', authenticateToken, getProfessionalDemandes);

module.exports = router;