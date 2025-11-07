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

module.exports = {
  handleValidationErrors,
  validateIdParam,
  validateIdBody,
  validateString,
  validateEmail,
  validateAmount
};