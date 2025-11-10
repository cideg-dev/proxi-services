const { check, validationResult, param } = require('express-validator');

// Middleware pour valider les requêtes et renvoyer les erreurs
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// Validation pour les IDs numériques
const validateIdParam = (paramName, fieldName) => [
  param(paramName).isInt().withMessage(`${fieldName} doit être un entier valide`).toInt()
];

// Validation pour les IDs dans le body
const validateIdBody = (paramName, fieldName) => [
  check(paramName).isInt().withMessage(`${fieldName} doit être un entier valide`).toInt()
];

// Validation pour les chaînes de caractères
const validateString = (paramName, fieldName, options = {}) => {
  const { min = 1, max = 255, nullable = false } = options;
  let validator = check(paramName);
  
  if (!nullable) {
    validator = validator.notEmpty().withMessage(`${fieldName} est requis`);
  }
  
  return [
    validator.isLength({ min, max }).withMessage(`${fieldName} doit contenir entre ${min} et ${max} caractères`)
  ];
};

// Validation pour les emails
const validateEmail = (paramName, fieldName) => [
  check(paramName).isEmail().withMessage(`${fieldName} doit être une adresse email valide`)
];

// Validation pour les montants
const validateAmount = (paramName, fieldName) => [
  check(paramName).isFloat({ min: 0.01 }).withMessage(`${fieldName} doit être un nombre positif`).toFloat()
];

// Validation pour les numéros de téléphone
const validatePhone = (paramName, fieldName) => [
  check(paramName).optional().isMobilePhone(['fr-FR']).withMessage(`${fieldName} doit être un numéro de téléphone valide`)
];

// Validation pour les URLs
const validateUrl = (paramName, fieldName) => [
  check(paramName).optional().isURL().withMessage(`${fieldName} doit être une URL valide`)
];

// Validation pour les données de profil
const validateProfileData = (role) => {
  const validations = [];
  
  switch (role) {
    case 'client':
      validations.push(
        check('profileData.nom_complet').notEmpty().withMessage('Le nom complet est requis').isLength({ max: 255 }),
        check('profileData.sexe').optional().isIn(['homme', 'femme', 'autre']).withMessage('Le sexe doit être "homme", "femme" ou "autre"'),
        check('profileData.location').optional().isLength({ max: 255 }),
        check('profileData.telephone').optional().isMobilePhone(['fr-FR']).withMessage('Le numéro de téléphone doit être valide')
      );
      break;
    case 'artisan':
      validations.push(
        check('profileData.nom_complet').notEmpty().withMessage('Le nom complet est requis').isLength({ max: 255 }),
        check('profileData.specialite').optional().isLength({ max: 255 }),
        check('profileData.location').optional().isLength({ max: 255 }),
        check('profileData.telephone').optional().isMobilePhone(['fr-FR']).withMessage('Le numéro de téléphone doit être valide'),
        check('profileData.annees_experience').optional().isInt({ min: 0 }).withMessage('Les années d\'expérience doivent être un entier positif'),
        check('profileData.siret').optional().matches(/^\d{14}$/).withMessage('Le SIRET doit être composé de 14 chiffres'),
        check('profileData.site_web').optional().isURL().withMessage('L\'URL du site web doit être valide'),
        check('profileData.description').optional().isLength({ max: 1000 })
      );
      break;
    case 'commercant':
      validations.push(
        check('profileData.nom_entreprise').notEmpty().withMessage('Le nom de l\'entreprise est requis').isLength({ max: 255 }),
        check('profileData.type_commerce').optional().isLength({ max: 255 }),
        check('profileData.adresse').optional().isLength({ max: 500 }),
        check('profileData.location').optional().isLength({ max: 255 }),
        check('profileData.telephone').isMobilePhone(['fr-FR']).withMessage('Le numéro de téléphone est requis et doit être valide'),
        check('profileData.annees_experience').optional().isInt({ min: 0 }).withMessage('Les années d\'expérience doivent être un entier positif'),
        check('profileData.siret').optional().matches(/^\d{14}$/).withMessage('Le SIRET doit être composé de 14 chiffres'),
        check('profileData.site_web').optional().isURL().withMessage('L\'URL du site web doit être valide'),
        check('profileData.description').optional().isLength({ max: 1000 })
      );
      break;
  }
  
  return validations;
};

module.exports = {
  handleValidationErrors,
  validateIdParam,
  validateIdBody,
  validateString,
  validateEmail,
  validateAmount,
  validatePhone,
  validateUrl,
  validateProfileData
};