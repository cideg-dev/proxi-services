// Service pour le chiffrement/déchiffrement des données sensibles

const crypto = require('crypto');
const logger = require('../utils/logger');

// Utiliser une clé de chiffrement depuis les variables d'environnement
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY; // 32 caractères pour AES-256
const IV_LENGTH = 16; // Longueur pour AES

if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length !== 32) {
  logger.error('La clé de chiffrement n\'est pas correctement configurée dans les variables d\'environnement (doit être de 32 caractères)');
  throw new Error('Configuration de chiffrement invalide');
}

/**
 * Chiffrer une chaîne de caractères
 * @param {string} text - Le texte à chiffrer
 * @returns {string} - Le texte chiffré (format hex)
 */
const encrypt = (text) => {
  try {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipher('aes-256-cbc', ENCRYPTION_KEY);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    // Retourner IV + ':' + encrypted pour permettre le déchiffrement
    return iv.toString('hex') + ':' + encrypted;
  } catch (error) {
    logger.error('Erreur lors du chiffrement:', error.message);
    throw error;
  }
};

/**
 * Déchiffrer une chaîne de caractères
 * @param {string} text - Le texte chiffré (format hex)
 * @returns {string} - Le texte déchiffré
 */
const decrypt = (text) => {
  try {
    const parts = text.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];
    
    const decipher = crypto.createDecipher('aes-256-cbc', ENCRYPTION_KEY);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  } catch (error) {
    logger.error('Erreur lors du déchiffrement:', error.message);
    throw error;
  }
};

/**
 * Chiffrer les données personnelles sensibles
 * @param {Object} profileData - Les données de profil à chiffrer
 * @returns {Object} - Les données avec les champs sensibles chiffrés
 */
const encryptSensitiveData = (profileData) => {
  const encryptedData = { ...profileData };
  
  // Chiffrer les données sensibles
  if (encryptedData.telephone) {
    encryptedData.telephone = encrypt(encryptedData.telephone);
  }
  
  if (encryptedData.adresse) {
    encryptedData.adresse = encrypt(encryptedData.adresse);
  }
  
  // Ajouter d'autres champs sensibles au besoin
  return encryptedData;
};

/**
 * Déchiffrer les données personnelles sensibles
 * @param {Object} profileData - Les données de profil avec champs chiffrés
 * @returns {Object} - Les données avec les champs sensibles déchiffrés
 */
const decryptSensitiveData = (profileData) => {
  const decryptedData = { ...profileData };
  
  // Déchiffrer les données sensibles
  if (decryptedData.telephone && typeof decryptedData.telephone === 'string' && decryptedData.telephone.includes(':')) {
    decryptedData.telephone = decrypt(decryptedData.telephone);
  }
  
  if (decryptedData.adresse && typeof decryptedData.adresse === 'string' && decryptedData.adresse.includes(':')) {
    decryptedData.adresse = decrypt(decryptedData.adresse);
  }
  
  return decryptedData;
};

module.exports = {
  encrypt,
  decrypt,
  encryptSensitiveData,
  decryptSensitiveData
};