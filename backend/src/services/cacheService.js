const redis = require('redis');
require('dotenv').config();

// Création du client Redis
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  retry_strategy: (options) => {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      console.error('Le serveur Redis refuse la connexion');
      return new Error('Redis connection refused');
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      return new Error('Retry time exhausted');
    }
    if (options.attempt > 10) {
      return undefined;
    }
    return Math.min(options.attempt * 100, 3000);
  }
});

// Gestion des erreurs Redis
redisClient.on('error', (err) => {
  console.error('Erreur Redis:', err);
});

// Connexion au client Redis
const connectRedis = async () => {
  try {
    await redisClient.connect();
    console.log('Connecté au serveur Redis');
  } catch (error) {
    console.error('Erreur de connexion à Redis:', error);
  }
};

// Fonction pour récupérer une valeur du cache
const getFromCache = async (key) => {
  try {
    const cachedData = await redisClient.get(key);
    return cachedData ? JSON.parse(cachedData) : null;
  } catch (error) {
    console.error('Erreur de récupération du cache:', error);
    return null;
  }
};

// Fonction pour sauvegarder une valeur dans le cache
const saveToCache = async (key, data, expiration = 3600) => { // 1 heure par défaut
  try {
    await redisClient.setEx(key, expiration, JSON.stringify(data));
  } catch (error) {
    console.error('Erreur de sauvegarde dans le cache:', error);
  }
};

// Fonction pour supprimer une clé du cache
const removeFromCache = async (key) => {
  try {
    await redisClient.del(key);
  } catch (error) {
    console.error('Erreur de suppression du cache:', error);
  }
};

// Fonction pour vider le cache
const clearCache = async () => {
  try {
    await redisClient.flushDb();
  } catch (error) {
    console.error('Erreur de vidage du cache:', error);
  }
};

module.exports = {
  connectRedis,
  redisClient,
  getFromCache,
  saveToCache,
  removeFromCache,
  clearCache
};