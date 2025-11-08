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
app.use(helmet());
app.use(express.json());

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV || 'development'}`);
});