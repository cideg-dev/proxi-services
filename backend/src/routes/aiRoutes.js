const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const authMiddleware = require('../middleware/auth'); // Middleware pour protéger la route

// @route   POST api/ai/generate-portfolio
// @desc    Générer le contenu du portfolio d'un artisan avec l'IA
// @access  Private
router.post('/generate-portfolio', authMiddleware, aiController.generatePortfolio);

module.exports = router;
