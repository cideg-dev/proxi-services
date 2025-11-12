const crypto = require('crypto');
require('dotenv').config();

const ENCRYPTION_ALGORITHM = 'aes-256-gcm';
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32).toString('hex');
const IV_LENGTH = 16; // Pour AES, ce doit être 16 octets

/**
 * Service de chiffrement/déchiffrement des données sensibles
 */
class EncryptionService {
  /**
   * Chiffre une donnée sensible
   * @param {string} text - Le texte à chiffrer
   * @returns {string} - La donnée chiffrée au format base64
   */
  static encrypt(text) {
    try {
      // Assurez-vous que la clé a la bonne longueur (32 octets pour AES-256)
      const key = this.normalizeKey(ENCRYPTION_KEY);
      
      // Générer un IV aléatoire
      const iv = crypto.randomBytes(IV_LENGTH);
      
      // Créer le chiffreur avec IV (méthode recommandée)
      const cipher = crypto.createCipheriv(ENCRYPTION_ALGORITHM, key, iv);
      
      // Chiffrer le texte
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Obtenir le tag d'authentification
      const authTag = cipher.getAuthTag();
      
      // Concaténer IV + tag d'authentification + données chiffrées
      const result = iv.toString('hex') + ':' + authTag.toString('hex') + ':' + encrypted;
      
      // Retourner en base64
      return Buffer.from(result).toString('base64');
    } catch (error) {
      console.error('Erreur lors du chiffrement :', error);
      throw new Error('Échec du chiffrement des données');
    }
  }
  
  /**
   * Déchiffre une donnée chiffrée
   * @param {string} encryptedText - Le texte chiffré au format base64
   * @returns {string} - La donnée déchiffrée
   */
  static decrypt(encryptedText) {
    try {
      // Convertir de base64 à hex
      const decodedText = Buffer.from(encryptedText, 'base64').toString('ascii');
      
      // Diviser en IV, tag d'authentification et données chiffrées
      const parts = decodedText.split(':');
      if (parts.length !== 3) {
        throw new Error('Format de texte chiffré invalide');
      }
      
      // Assurez-vous que la clé a la bonne longueur (32 octets pour AES-256)
      const key = this.normalizeKey(ENCRYPTION_KEY);
      
      const iv = Buffer.from(parts[0], 'hex');
      const authTag = Buffer.from(parts[1], 'hex');
      const encrypted = parts[2];
      
      // Créer le déchiffreur avec IV (méthode recommandée)
      const decipher = crypto.createDecipheriv(ENCRYPTION_ALGORITHM, key, iv);
      decipher.setAuthTag(authTag);
      
      // Déchiffrer
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      console.error('Erreur lors du déchiffrement :', error);
      throw new Error('Échec du déchiffrement des données');
    }
  }
  
  /**
   * Normalise une clé pour qu'elle ait la longueur requise
   * @param {string} key - La clé brute
   * @returns {Buffer} - La clé normalisée
   */
  static normalizeKey(key) {
    // Convertir la clé en buffer de 32 octets pour AES-256
    let keyBuffer;
    if (typeof key === 'string') {
      keyBuffer = Buffer.from(key, 'hex');
    } else {
      keyBuffer = key;
    }
    
    if (keyBuffer.length < 32) {
      // Étendre la clé avec du padding
      const extendedKey = Buffer.alloc(32);
      keyBuffer.copy(extendedKey);
      for (let i = keyBuffer.length; i < 32; i++) {
        extendedKey[i] = 0;
      }
      return extendedKey;
    } else if (keyBuffer.length > 32) {
      // Tronquer la clé
      return keyBuffer.slice(0, 32);
    }
    return keyBuffer;
  }
  
  /**
   * Vérifie si le service de chiffrement est correctement configuré
   * @returns {boolean} - true si configuré correctement
   */
  static isConfigured() {
    return !!ENCRYPTION_KEY && ENCRYPTION_KEY.length >= 32;
  }
  
  /**
   * Génère une clé de chiffrement sécurisée
   * @returns {string} - La clé générée au format hex
   */
  static generateEncryptionKey() {
    return crypto.randomBytes(32).toString('hex');
  }
}

// Vérification de la configuration
if (!EncryptionService.isConfigured() && process.env.NODE_ENV === 'production') {
  console.warn('ATTENTION: Aucune clé de chiffrement configurée. Génération d\'une clé temporaire.');
  console.warn('Veuillez définir la variable d\'environnement ENCRYPTION_KEY avec une clé de 32 octets.');
  console.warn('Générer une clé avec: require(\'crypto\').randomBytes(32).toString(\'hex\')');
}

module.exports = EncryptionService;