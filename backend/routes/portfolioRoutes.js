const express = require('express');
const router = express.Router();
const portfolioController = require('../controllers/portfolioController');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const multer = require('multer');

// Configuration de Multer pour le stockage des images (en mémoire pour traitement Sharp)
const storage = multer.memoryStorage(); // Store in memory for Sharp processing
const upload = multer({ storage: storage });

// @route   GET /api/portfolio/recent
// @desc    Get 10 most recent portfolio items
// @access  Public
router.get('/portfolio/recent', portfolioController.getRecentPortfolioItems);

// @route   GET /api/artisans/:artisanId/portfolio
// @desc    Get all portfolio items for an artisan
// @access  Public
router.get('/:artisanId/portfolio', portfolioController.getPortfolioItems);

// @route   POST /api/artisans/:artisanId/portfolio
// @desc    Add a portfolio item
// @access  Private (artisan or commercant)
router.post('/:artisanId/portfolio', authenticateToken, authorizeRole(['artisan', 'commercant']), upload.single('portfolioImage'), portfolioController.addPortfolioItem);

// @route   PUT /api/artisans/:artisanId/portfolio/:portfolioId
// @desc    Update a portfolio item
// @access  Private (artisan or commercant)
router.put('/:artisanId/portfolio/:portfolioId', authenticateToken, authorizeRole(['artisan', 'commercant']), upload.single('portfolioImage'), portfolioController.updatePortfolioItem);

// @route   DELETE /api/artisans/:artisanId/portfolio/:portfolioId
// @desc    Delete a portfolio item
// @access  Private (artisan or commercant)
router.delete('/:artisanId/portfolio/:portfolioId', authenticateToken, authorizeRole(['artisan', 'commercant']), portfolioController.deletePortfolioItem);

module.exports = router;