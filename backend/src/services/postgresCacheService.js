// service-cache-postgres.js - Service de cache utilisant PostgreSQL au lieu de Redis
const db = require('../db.config');
const crypto = require('crypto');

// Fonction d'échappement basique pour les clés de cache
const sanitizeCacheKey = (key) => {
  if (typeof key !== 'string') {
    key = String(key);
  }
  // Échapper les caractères potentiellement dangereux
  return key.replace(/[^a-zA-Z0-9-_:.]/g, '_');
};

// Fonction pour générer un hash sécurisé pour les clés de cache longues
const hashCacheKey = (key) => {
  if (key.length > 250) {
    return crypto.createHash('sha256').update(key).digest('hex');
  }
  return sanitizeCacheKey(key);
};

// Fonction pour récupérer une valeur du cache PostgreSQL
const getFromCache = async (key) => {
  try {
    const hashedKey = hashCacheKey(key);
    
    // Suppression des entrées expirées avant la récupération
    await db.query('DELETE FROM cache WHERE key = $1 AND expires_at < NOW()', [hashedKey]);
    
    const result = await db.query(
      'SELECT value FROM cache WHERE key = $1 AND expires_at >= NOW()', 
      [hashedKey]
    );
    
    if (result.rows.length > 0) {
      const cachedData = result.rows[0].value;
      return JSON.parse(cachedData);
    }
    
    return null;
  } catch (error) {
    console.error('Erreur de récupération du cache PostgreSQL:', error.message);
    return null;
  }
};

// Fonction pour sauvegarder une valeur dans le cache PostgreSQL
const saveToCache = async (key, data, expiration = 3600) => { // 1 heure par défaut
  try {
    const hashedKey = hashCacheKey(key);

    // Limiter la taille des données pour éviter la surcharge mémoire
    if (JSON.stringify(data).length > 1024 * 1024) { // 1MB limit
      console.warn('Données de cache trop volumineuses, non sauvegardées:', hashedKey);
      return;
    }

    // Convertir l'expiration (en secondes) en interval pour PostgreSQL
    const expiresAt = `NOW() + INTERVAL '${expiration} seconds'`;
    
    // Insertion ou mise à jour de la valeur de cache
    const query = `
      INSERT INTO cache (key, value, expires_at) 
      VALUES ($1, $2, ${expiresAt})
      ON CONFLICT (key) 
      DO UPDATE SET 
        value = EXCLUDED.value,
        expires_at = ${expiresAt},
        updated_at = NOW()
    `;
    
    await db.query(query, [hashedKey, JSON.stringify(data)]);
  } catch (error) {
    console.error('Erreur de sauvegarde dans le cache PostgreSQL:', error.message);
  }
};

// Fonction pour supprimer une clé du cache PostgreSQL
const removeFromCache = async (key) => {
  try {
    const hashedKey = hashCacheKey(key);
    await db.query('DELETE FROM cache WHERE key = $1', [hashedKey]);
  } catch (error) {
    console.error('Erreur de suppression du cache PostgreSQL:', error.message);
  }
};

// Fonction pour vider le cache PostgreSQL
const clearCache = async () => {
  try {
    await db.query('DELETE FROM cache');
  } catch (error) {
    console.error('Erreur de vidage du cache PostgreSQL:', error.message);
  }
};

// Fonction pour nettoyer les entrées expirées du cache PostgreSQL
const cleanupExpiredCache = async () => {
  try {
    await db.query('DELETE FROM cache WHERE expires_at < NOW()');
  } catch (error) {
    console.error('Erreur de nettoyage du cache PostgreSQL:', error.message);
  }
};

module.exports = {
  getFromCache,
  saveToCache,
  removeFromCache,
  clearCache,
  cleanupExpiredCache
};