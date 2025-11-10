const express = require('express');
const router = express.Router();
const portfolioController = require('../controllers/portfolioController');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const multer = require('multer');

// Configuration sécurisée de Multer pour le stockage des images
const fileFilter = (req, file, cb) => {
  // Autoriser uniquement les images
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Type de fichier non supporté. Seules les images sont autorisées.'), false);
  }
};

// Configuration de Multer avec limitations de taille et filtres
const upload = multer({ 
  storage: multer.memoryStorage(), // Store in memory for Sharp processing
  limits: {
    fileSize: 5 * 1024 * 1024, // Limite de 5 Mo
  },
  fileFilter: fileFilter
});

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