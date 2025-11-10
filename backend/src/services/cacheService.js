const redis = require('redis');
require('dotenv').config();

// Variable pour vérifier si Redis est disponible
let isRedisAvailable = false;

// Création du client Redis avec gestion d'erreurs
let redisClient;

if (process.env.REDIS_HOST) {
  redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    socket: {
      connectTimeout: 5000,
      reconnectStrategy: (times) => {
        if (times >= 3) {
          console.error('Échec de connexion à Redis après 3 tentatives');
          return false; // Arrêter les tentatives
        }
        return 2000; // Réessayer après 2 secondes
      }
    }
  });

  // Gestion des erreurs Redis
  redisClient.on('error', (err) => {
    console.error('Erreur Redis:', err.message);
    isRedisAvailable = false;
  });

  redisClient.on('connect', () => {
    console.log('Connecté au serveur Redis');
    isRedisAvailable = true;
  });

  redisClient.on('ready', () => {
    console.log('Client Redis prêt');
    isRedisAvailable = true;
  });
} else {
  // Si REDIS_HOST n'est pas défini, on utilisera un cache en mémoire
  console.log('Redis non configuré - utilisation du cache en mémoire');
  redisClient = null;
  isRedisAvailable = false;
}

// Cache en mémoire pour les environnements sans Redis
const memoryCache = new Map();
const cacheTimeouts = new Map();

// Connexion au client Redis
const connectRedis = async () => {
  if (redisClient) {
    try {
      await redisClient.connect();
      console.log('Connecté au serveur Redis');
      isRedisAvailable = true;
    } catch (error) {
      console.error('Erreur de connexion à Redis:', error.message);
      console.log('Utilisation du cache en mémoire à la place');
      isRedisAvailable = false;
    }
  }
};

// Fonction pour récupérer une valeur du cache (Redis ou mémoire)
const getFromCache = async (key) => {
  try {
    if (isRedisAvailable && redisClient) {
      const cachedData = await redisClient.get(key);
      return cachedData ? JSON.parse(cachedData) : null;
    } else {
      // Utiliser le cache en mémoire
      const cachedItem = memoryCache.get(key);
      if (cachedItem) {
        // Vérifier si le cache est expiré
        if (Date.now() < cachedItem.expiry) {
          return cachedItem.data;
        } else {
          // Supprimer l'entrée expirée
          memoryCache.delete(key);
          cacheTimeouts.delete(key);
        }
      }
      return null;
    }
  } catch (error) {
    console.error('Erreur de récupération du cache:', error.message);
    return null;
  }
};

// Fonction pour sauvegarder une valeur dans le cache (Redis ou mémoire)
const saveToCache = async (key, data, expiration = 3600) => { // 1 heure par défaut
  try {
    if (isRedisAvailable && redisClient) {
      await redisClient.setEx(key, expiration, JSON.stringify(data));
    } else {
      // Sauvegarde dans le cache en mémoire
      const expiry = Date.now() + (expiration * 1000);
      memoryCache.set(key, { data, expiry });
      
      // Nettoyer automatiquement à l'expiration
      if (cacheTimeouts.has(key)) {
        clearTimeout(cacheTimeouts.get(key));
      }
      cacheTimeouts.set(key, setTimeout(() => {
        memoryCache.delete(key);
        cacheTimeouts.delete(key);
      }, expiration * 1000));
    }
  } catch (error) {
    console.error('Erreur de sauvegarde dans le cache:', error.message);
  }
};

// Fonction pour supprimer une clé du cache
const removeFromCache = async (key) => {
  try {
    if (isRedisAvailable && redisClient) {
      await redisClient.del(key);
    } else {
      memoryCache.delete(key);
      if (cacheTimeouts.has(key)) {
        clearTimeout(cacheTimeouts.get(key));
        cacheTimeouts.delete(key);
      }
    }
  } catch (error) {
    console.error('Erreur de suppression du cache:', error.message);
  }
};

// Fonction pour vider le cache
const clearCache = async () => {
  try {
    if (isRedisAvailable && redisClient) {
      await redisClient.flushDb();
    } else {
      memoryCache.clear();
      cacheTimeouts.forEach(timeout => clearTimeout(timeout));
      cacheTimeouts.clear();
    }
  } catch (error) {
    console.error('Erreur de vidage du cache:', error.message);
  }
};

module.exports = {
  connectRedis,
  redisClient,
  getFromCache,
  saveToCache,
  removeFromCache,
  clearCache,
  isRedisAvailable
};