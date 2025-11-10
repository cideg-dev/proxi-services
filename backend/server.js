// Point d'entrée principal de l'application
// Ce fichier configure et démarre le serveur Express

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const http = require('http');

// Importation de l'application principale
const app = require('./src/app');

// Configuration du rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limite chaque IP à 100 requêtes par windowMs
  message: 'Trop de demandes depuis cette adresse IP, veuillez réessayer plus tard.'
});

// Application des middlewares de performance et de sécurité
app.use(compression()); // Compression des réponses
app.use(limiter);

// Configuration renforcée de Helmet pour améliorer la sécurité
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://*.kkiapay.net", "wss:"], // Ajout des domaines nécessaires pour les paiements et WebSocket
      frameSrc: ["https://www.kkiapay.tg"], // Autoriser kkiapay
      objectSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000, // 1 an
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'DENY'
  },
  referrerPolicy: {
    policy: 'same-origin'
  }
}));

app.use(express.json());

// Trust proxy pour Render - Configuration sécurisée
app.set('trust proxy', 1); // Seulement le premier proxy (le load balancer de Render)

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV || 'development'}`);
});