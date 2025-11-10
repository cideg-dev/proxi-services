// Routes pour la gestion de la confidentialité et des données personnelles

const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/authMiddleware');
const { anonymizeUser, deleteUser, exportUserData } = require('../services/privacyService');

// @route   POST /api/privacy/anonymize-account
// @desc    Anonymiser le compte utilisateur
// @access  Private
router.post('/privacy/anonymize-account', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    
    await anonymizeUser(userId);
    
    res.json({ message: 'Votre compte a été anonymisé avec succès. Toutes vos données personnelles identifiables ont été supprimées.' });
  } catch (error) {
    console.error('Erreur lors de l\'anonymisation du compte:', error.message);
    res.status(500).json({ message: 'Erreur lors de l\'anonymisation de votre compte.' });
  }
});

// @route   POST /api/privacy/delete-account
// @desc    Supprimer complètement le compte utilisateur
// @access  Private
router.post('/privacy/delete-account', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    
    // Note: Vous voudrez peut-être ajouter une étape de confirmation supplémentaire
    // et conserver temporairement les données avant suppression définitive
    
    await deleteUser(userId);
    
    res.json({ message: 'Votre compte a été supprimé avec succès. Toutes vos données ont été supprimées de nos systèmes.' });
  } catch (error) {
    console.error('Erreur lors de la suppression du compte:', error.message);
    res.status(500).json({ message: 'Erreur lors de la suppression de votre compte.' });
  }
});

// @route   GET /api/privacy/export-data
// @desc    Exporter les données personnelles de l'utilisateur
// @access  Private
router.get('/privacy/export-data', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user.id;
    
    const userData = await exportUserData(userId);
    
    res.json(userData);
  } catch (error) {
    console.error('Erreur lors de l\'export des données:', error.message);
    res.status(500).json({ message: 'Erreur lors de l\'export de vos données.' });
  }
});

module.exports = router;