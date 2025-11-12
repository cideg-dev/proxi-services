const redis = require('redis');
require('dotenv').config();

// Variables pour le cache en mémoire
const memoryCache = new Map();
const cacheTimeouts = new Map();

// Variable pour vérifier si Redis est disponible
let isRedisAvailable = false;
let usePostgresCache = false;

// Création du client Redis avec gestion d'erreurs et paramètres de sécurité
let redisClient;

if (process.env.REDIS_HOST) {
  // Configuration sécurisée du client Redis
  const redisOptions = {
    socket: {
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      connectTimeout: 5000,
      reconnectStrategy: (times) => {
        if (times >= 3) {
          console.error('Échec de connexion à Redis après 3 tentatives');
          return false; // Arrêter les tentatives
        }
        return 2000; // Réessayer après 2 secondes
      }
    }
  };

  // Ajouter l'authentification si disponible
  if (process.env.REDIS_PASSWORD) {
    redisOptions.password = process.env.REDIS_PASSWORD;
  }

  redisClient = redis.createClient(redisOptions);

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
  // Si REDIS_HOST n'est pas défini, on utilisera PostgreSQL pour le cache
  console.log('Redis non configuré - utilisation de PostgreSQL pour le cache');
  isRedisAvailable = false;
  usePostgresCache = true;
}

// Fonction d'échappement basique pour les clés de cache
const sanitizeCacheKey = (key) => {
  if (typeof key !== 'string') {
    key = String(key);
  }
  // Échapper les caractères potentiellement dangereux
  return key.replace(/[^a-zA-Z0-9-_:.]/g, '_');
};

// Connexion au client Redis
const connectRedis = async () => {
  if (redisClient) {
    try {
      await redisClient.connect();
      console.log('Connecté au serveur Redis');
      isRedisAvailable = true;
    } catch (error) {
      console.error('Erreur de connexion à Redis:', error.message);
      console.log('Utilisation du cache PostgreSQL à la place');
      isRedisAvailable = false;
      usePostgresCache = true;
    }
  }
};

// Charger le service de cache PostgreSQL si nécessaire
let postgresCacheService;
if (usePostgresCache) {
  postgresCacheService = require('./postgresCacheService');
}

// Fonction pour récupérer une valeur du cache (Redis ou PostgreSQL)
const getFromCache = async (key) => {
  if (usePostgresCache) {
    // Utiliser le service de cache PostgreSQL
    return await postgresCacheService.getFromCache(key);
  }

  // Sinon, utiliser Redis
  // Sanitize la clé pour éviter les injections
  const sanitizedKey = sanitizeCacheKey(key);

  try {
    if (isRedisAvailable && redisClient) {
      const cachedData = await redisClient.get(sanitizedKey);
      return cachedData ? JSON.parse(cachedData) : null;
    } else {
      // Utiliser le cache en mémoire
      const cachedItem = memoryCache.get(sanitizedKey);
      if (cachedItem) {
        // Vérifier si le cache est expiré
        if (Date.now() < cachedItem.expiry) {
          return cachedItem.data;
        } else {
          // Supprimer l'entrée expirée
          memoryCache.delete(sanitizedKey);
          if (cacheTimeouts.has(sanitizedKey)) {
            clearTimeout(cacheTimeouts.get(sanitizedKey));
            cacheTimeouts.delete(sanitizedKey);
          }
        }
      }
      return null;
    }
  } catch (error) {
    console.error('Erreur de récupération du cache:', error.message);
    return null;
  }
};

// Fonction pour sauvegarder une valeur dans le cache (Redis ou PostgreSQL)
const saveToCache = async (key, data, expiration = 3600) => { // 1 heure par défaut
  if (usePostgresCache) {
    // Utiliser le service de cache PostgreSQL
    return await postgresCacheService.saveToCache(key, data, expiration);
  }

  // Récupérer la fonction définie plus bas dans le fichier
  // (la déclaration de fonction est hoistée, donc disponible ici)
  return _saveToCacheRedis(key, data, expiration);
};

// Fonction pour supprimer une clé du cache (Redis ou PostgreSQL)
const removeFromCache = async (key) => {
  if (usePostgresCache) {
    // Utiliser le service de cache PostgreSQL
    return await postgresCacheService.removeFromCache(key);
  }

  // Récupérer la fonction définie plus bas dans le fichier
  // (la déclaration de fonction est hoistée, donc disponible ici)
  return _removeFromCacheRedis(key);
};

// Fonction pour vider le cache (Redis ou PostgreSQL)
const clearCache = async () => {
  if (usePostgresCache) {
    // Utiliser le service de cache PostgreSQL
    return await postgresCacheService.clearCache();
  }

  // Récupérer la fonction définie plus bas dans le fichier
  // (la déclaration de fonction est hoistée, donc disponible ici)
  return _clearCacheRedis();
};

// Déclaration des fonctions Redis avec un préfixe pour les distinguer des versions PostgreSQL
const _saveToCacheRedis = async (key, data, expiration = 3600) => { // 1 heure par défaut
  // Sanitize la clé pour éviter les injections
  const sanitizedKey = sanitizeCacheKey(key);

  // Limer la taille des données pour éviter la surcharge mémoire
  if (JSON.stringify(data).length > 1024 * 1024) { // 1MB limit
    console.warn('Données de cache trop volumineuses, non sauvegardées:', sanitizedKey);
    return;
  }

  try {
    if (isRedisAvailable && redisClient) {
      // Sauvegarder dans Redis
      await redisClient.setEx(sanitizedKey, expiration, JSON.stringify(data));
    } else {
      // Sauvegarde dans le cache en mémoire
      const expiry = Date.now() + (expiration * 1000);
      memoryCache.set(sanitizedKey, { data, expiry });

      // Nettoyer automatiquement à l'expiration
      if (cacheTimeouts.has(sanitizedKey)) {
        clearTimeout(cacheTimeouts.get(sanitizedKey));
      }
      cacheTimeouts.set(sanitizedKey, setTimeout(() => {
        memoryCache.delete(sanitizedKey);
        cacheTimeouts.delete(sanitizedKey);
      }, expiration * 1000));
    }
  } catch (error) {
    console.error('Erreur de sauvegarde dans le cache:', error.message);
  }
};

const _removeFromCacheRedis = async (key) => {
  // Sanitize la clé pour éviter les injections
  const sanitizedKey = sanitizeCacheKey(key);

  try {
    if (isRedisAvailable && redisClient) {
      await redisClient.del(sanitizedKey);
    } else {
      memoryCache.delete(sanitizedKey);
      if (cacheTimeouts.has(sanitizedKey)) {
        clearTimeout(cacheTimeouts.get(sanitizedKey));
        cacheTimeouts.delete(sanitizedKey);
      }
    }
  } catch (error) {
    console.error('Erreur de suppression du cache:', error.message);
  }
};

const _clearCacheRedis = async () => {
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