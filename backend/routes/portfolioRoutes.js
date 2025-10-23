const express = require('express');
const router = express.Router();
const portfolioController = require('../controllers/portfolioController');
const authMiddleware = require('../middleware/authMiddleware');

// @route   GET /api/portfolio/recent
// @desc    Get 10 most recent portfolio items
// @access  Public
router.get('/recent', portfolioController.getRecentPortfolioItems);

module.exports = router;
