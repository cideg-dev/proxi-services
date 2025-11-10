const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
require('dotenv').config();

const SALT_ROUNDS = 12;

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
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token expiré');
    } else if (error.name === 'JsonWebTokenError') {
      throw new Error('Token invalide');
    } else {
      throw new Error('Erreur de vérification du token');
    }
  }
};

// Fonction pour vérifier un refresh token
const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Refresh token expiré');
    } else if (error.name === 'JsonWebTokenError') {
      throw new Error('Refresh token invalide');
    } else {
      throw new Error('Erreur de vérification du refresh token');
    }
  }
};

// Fonction pour hacher un mot de passe
const hashPassword = async (password) => {
  if (!password || typeof password !== 'string') {
    throw new Error('Mot de passe invalide');
  }
  return await bcrypt.hash(password, SALT_ROUNDS);
};

// Fonction pour comparer un mot de passe avec son hash
const comparePassword = async (password, hashedPassword) => {
  if (!password || !hashedPassword) {
    throw new Error('Paramètres invalides pour la comparaison de mot de passe');
  }
  return await bcrypt.compare(password, hashedPassword);
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  verifyRefreshToken,
  hashPassword,
  comparePassword
};