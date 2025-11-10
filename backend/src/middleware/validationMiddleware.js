const { body, param, query, validationResult } = require('express-validator');
const validator = require('validator');

// Validation générique pour les identifiants
const idValidator = (field = 'id') => [
  param(field).exists().withMessage(`${field} est requis`)
    .isInt({ min: 1 }).withMessage(`${field} doit être un entier positif`)
];

// Validation générique pour l'email
const emailValidator = (field = 'email') => [
  body(field).exists().withMessage(`${field} est requis`)
    .isEmail().withMessage('Format d\'email invalide')
    .normalizeEmail()
];

// Validation générique pour le mot de passe
const passwordValidator = (field = 'password') => [
  body(field).exists().withMessage(`${field} est requis`)
    .isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre')
];

// Validation pour les données de profil utilisateur
const userProfileValidator = [
  body('nom_complet')
    .optional()
    .isLength({ min: 2, max: 100 }).withMessage('Le nom complet doit contenir entre 2 et 100 caractères')
    .trim()
    .escape(),
  body('prenom')
    .optional()
    .isLength({ min: 2, max: 50 }).withMessage('Le prénom doit contenir entre 2 et 50 caractères')
    .trim()
    .escape(),
  body('telephone')
    .optional()
    .matches(/^(\+229)?[0-9]{8,12}$/).withMessage('Numéro de téléphone invalide')
    .trim(),
  body('adresse')
    .optional()
    .isLength({ max: 255 }).withMessage('L\'adresse est trop longue')
    .trim()
    .escape(),
  body('sexe')
    .optional()
    .isIn(['Homme', 'Femme', 'Autre']).withMessage('Valeur de sexe invalide')
];

// Validation pour les services d'artisan
const artisanServiceValidator = [
  body('title')
    .exists().withMessage('Le titre est requis')
    .isLength({ min: 3, max: 100 }).withMessage('Le titre doit contenir entre 3 et 100 caractères')
    .trim()
    .escape(),
  body('description')
    .exists().withMessage('La description est requise')
    .isLength({ min: 10, max: 1000 }).withMessage('La description doit contenir entre 10 et 1000 caractères')
    .trim()
    .escape(),
  body('price')
    .optional()
    .isFloat({ min: 0 }).withMessage('Le prix doit être un nombre positif')
];

// Validation pour les avis/reviews
const reviewValidator = [
  body('rating')
    .exists().withMessage('La note est requise')
    .isInt({ min: 1, max: 5 }).withMessage('La note doit être comprise entre 1 et 5'),
  body('comment')
    .optional()
    .isLength({ max: 500 }).withMessage('Le commentaire est trop long')
    .trim()
    .escape(),
];

// Validation pour les demandes de service
const demandeValidator = [
  body('title')
    .exists().withMessage('Le titre est requis')
    .isLength({ min: 5, max: 100 }).withMessage('Le titre doit contenir entre 5 et 100 caractères')
    .trim()
    .escape(),
  body('description')
    .exists().withMessage('La description est requise')
    .isLength({ min: 10, max: 1000 }).withMessage('La description doit contenir entre 10 et 1000 caractères')
    .trim()
    .escape(),
  body('budget')
    .optional()
    .isFloat({ min: 0 }).withMessage('Le budget doit être un nombre positif'),
  body('localisation')
    .optional()
    .isLength({ max: 255 }).withMessage('La localisation est trop longue')
    .trim()
    .escape(),
];

// Middleware pour vérifier les erreurs de validation
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Erreur de validation',
      errors: errors.array()
    });
  }
  next();
};

module.exports = {
  idValidator,
  emailValidator,
  passwordValidator,
  userProfileValidator,
  artisanServiceValidator,
  reviewValidator,
  demandeValidator,
  handleValidationErrors
};