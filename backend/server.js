// Point d'entrée principal de l'application
// Ce fichier configure et démarre le serveur Express

require('dotenv').config();
const express = require('express');
const compression = require('compression');
const http = require('http');

// Importation des middlewares de sécurité
const { 
  limiter, 
  helmetConfig, 
  sanitize, 
  xssProtection, 
  hppProtection 
} = require('./src/middleware/securityMiddleware');

// Importation du service de cache
const { connectRedis } = require('./src/services/cacheService');

// Importation de l'application principale
const app = require('./src/app');

// Application des middlewares de performance et de sécurité
app.use(compression()); // Compression des réponses
app.use(limiter); // Rate limiting
app.use(helmetConfig); // Sécurité HTTP
app.use(sanitize); // Protection contre les injections NoSQL
app.use(xssProtection); // Protection contre XSS
app.use(hppProtection); // Protection contre la pollution de paramètres

// Trust proxy pour Render - Configuration sécurisée
app.set('trust proxy', 1); // Seulement le premier proxy (le load balancer de Render)

// Connexion au service de cache Redis (géré de manière asynchrone)
connectRedis().catch(err => {
  console.error('Erreur lors de la connexion à Redis:', err.message);
  console.log('L\'application continuera à fonctionner sans cache Redis');
});

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

server.listen(PORT, async () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV || 'development'}`);
  
  // Vérification de la connexion au cache
  try {
    const redis = require('./src/services/cacheService');
    if (redis.redisClient.isReady) {
      console.log('Redis client is connected and ready');
    } else {
      console.log('Waiting for Redis client to connect...');
    }
  } catch (error) {
    console.error('Erreur lors de la vérification de Redis:', error);
  }
});