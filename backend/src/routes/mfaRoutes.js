// Routes pour la gestion de l'authentification multifactorielle (MFA)

const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware');
const { 
  generateMFASecret, 
  verifyMFACode, 
  enableMFA, 
  disableMFA,
  isMFAEnabled 
} = require('../services/mfaService');
const { body, validationResult } = require('express-validator');

// @route   POST /api/mfa/setup
// @desc    Générer une clé secrète pour la configuration MFA
// @access  Private
router.post('/mfa/setup', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    const email = req.user.user.email;

    const mfaSetup = await generateMFASecret(userId, email);

    res.json({
      message: 'Clé MFA générée avec succès',
      qrCodeUrl: mfaSetup.qrCodeUrl
    });
  } catch (error) {
    console.error('Erreur lors de la configuration MFA:', error.message);
    res.status(500).json({ message: 'Erreur lors de la configuration de la MFA.' });
  }
});

// @route   POST /api/mfa/verify
// @desc    Vérifier le code MFA et activer la fonctionalité
// @access  Private
router.post('/mfa/verify', [
  authenticateToken,
  body('token', 'Le code MFA est requis').isLength({ min: 6, max: 6 }).isNumeric()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.user.user.id;
    const { token } = req.body;

    // Récupérer la clé secrète de l'utilisateur
    const userQuery = await pool.query('SELECT mfa_secret FROM users WHERE id = $1', [userId]);
    
    if (!userQuery.rows[0] || !userQuery.rows[0].mfa_secret) {
      return res.status(400).json({ message: 'Aucune clé MFA configurée. Veuillez d\'abord configurer la MFA.' });
    }

    const secret = userQuery.rows[0].mfa_secret;
    
    // Vérifier le code
    const isValid = verifyMFACode(secret, token);
    
    if (!isValid) {
      return res.status(400).json({ message: 'Code MFA invalide.' });
    }

    // Activer la MFA
    await enableMFA(userId);

    res.json({ message: 'MFA activée avec succès.' });
  } catch (error) {
    console.error('Erreur lors de la vérification MFA:', error.message);
    res.status(500).json({ message: 'Erreur lors de la vérification du code MFA.' });
  }
});

// @route   POST /api/mfa/disable
// @desc    Désactiver l'authentification MFA
// @access  Private
router.post('/mfa/disable', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    
    await disableMFA(userId);

    res.json({ message: 'MFA désactivée avec succès.' });
  } catch (error) {
    console.error('Erreur lors de la désactivation MFA:', error.message);
    res.status(500).json({ message: 'Erreur lors de la désactivation de la MFA.' });
  }
});

// @route   GET /api/mfa/status
// @desc    Obtenir le statut de la MFA pour l'utilisateur
// @access  Private
router.get('/mfa/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    
    const isEnabled = await isMFAEnabled(userId);

    res.json({ mfaEnabled: isEnabled });
  } catch (error) {
    console.error('Erreur lors de l\'obtention du statut MFA:', error.message);
    res.status(500).json({ message: 'Erreur lors de l\'obtention du statut MFA.' });
  }
});

module.exports = router;