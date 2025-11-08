const express = require('express');
const router = express.Router();
const pool = require('../db.config');
const { authenticateToken } = require('../middleware/authMiddleware');

// For now, we will just define the structure. The logic will be added later.

// @route   POST /api/demacheur/subscribe
// @desc    Initiate a subscription to become a demacheur
// @access  Private
router.post('/subscribe', authenticateToken, (req, res) => {
  // TODO: Integrate with Kkiapay to process the subscription payment.
  // 1. Get user ID from req.user.user.id
  // 2. Define subscription price (e.g., 2000 F CFA)
  // 3. Initiate payment with Kkiapay
  // 4. On successful payment webhook, update the demacheur_subscriptions table.
  res.status(501).json({ message: 'Endpoint not fully implemented yet.' });
});

// @route   GET /api/demacheur/status
// @desc    Get the current user's demacheur subscription status
// @access  Private
router.get('/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    const result = await pool.query(
      'SELECT * FROM demacheur_subscriptions WHERE user_id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.json({ status: 'inactive' });
    }

    const subscription = result.rows[0];
    const isActive = new Date(subscription.expires_at) > new Date();

    res.json({
      status: isActive ? subscription.status : 'expired',
      expires_at: subscription.expires_at,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
});

module.exports = router;
