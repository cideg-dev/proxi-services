const jwt = require('jsonwebtoken');
const crypto = require('crypto');
require('dotenv').config();

// Fonction pour générer un token JWT
const generateToken = (payload, expiresIn = '15m') => {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn });
};

// Fonction pour générer un refresh token
const generateRefreshToken = (payload) => {
  // Le refresh token est plus long que le token d'accès
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
  return refreshToken;
};

// Fonction pour vérifier un token JWT
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new Error('Token invalide ou expiré');
  }
};

// Fonction pour vérifier un refresh token
const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch (error) {
    throw new Error('Refresh token invalide ou expiré');
  }
};

// Fonction pour hacher un mot de passe
const hashPassword = (password) => {
  return crypto.createHash('sha256').update(password).digest('hex');
};

// Fonction pour comparer un mot de passe avec son hash
const comparePassword = (password, hashedPassword) => {
  const hashedInput = hashPassword(password);
  return hashedInput === hashedPassword;
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  verifyRefreshToken,
  hashPassword,
  comparePassword
};