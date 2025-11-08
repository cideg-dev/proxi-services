// Application Express principale - Refactorisée

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const axios = require('axios');
const { check, validationResult, body } = require('express-validator');

// Importation des contrôleurs
const { healthCheck, getVersion } = require('./controllers/generalController');

// Importation des services
const { haversineDistance, logAuditAction } = require('./services/generalService');

// Importation des utilitaires
const logger = require('./utils/logger');

const sharp = require('sharp');
const multer = require('multer');
const { sendNotificationEmail } = require('./services/emailService');
const { handleValidationErrors } = require('./middleware/validationMiddleware');

// Importation de la base de données
const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', 'db.config');
const pool = require(dbConfigPath);
const { authenticateToken, authorizeRole } = require('./middleware/authMiddleware');
const { calculateProfileCompleteness } = require('./services/profileService');

// Importation des routes
const authRoutes = require('./routes/authRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const portfolioRoutes = require('./routes/portfolioRoutes');
const demacheurRoutes = require('./routes/demacheurRoutes');
const profileRoutes = require('./routes/profileRoutes');

// Vérification des variables d'environnement critiques
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  logger.error('JWT_SECRET must be defined in environment variables');
  process.exit(1);
}

// Initialisation de l'application Express
const app = express();
const server = require('http').createServer(app);
const { Server } = require('socket.io');
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Rendre l'instance Socket.IO disponible globalement
app.set('io', io);

// Configuration CORS
const allowedOrigins = [
    process.env.FRONTEND_URL, // Devrait être l'URL frontend en production
    'https://cideg-dev.github.io' // Autorisation explicite de GitHub Pages
];

app.use(cors({
  origin: function (origin, callback) {
    // Autoriser les requêtes sans origine (ex: mobile apps ou requêtes curl)
    if (!origin) return callback(null, true);

    // Autoriser toutes les origines localhost en développement
    if (process.env.NODE_ENV === 'development' && origin.startsWith('http://localhost:')) {
      return callback(null, true);
    }

    // Autoriser les origines définies explicitement
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      const msg = 'La politique CORS de ce site n\'autorise pas ' +
                'l\'accès depuis l\'origine spécifiée : ' + origin;
      callback(new Error(msg), false);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true
}));

app.use(express.json());

// Middleware de journalisation des requêtes
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// Middleware pour servir les fichiers uploadés
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), {
  maxAge: '1d' // Cache les images pendant 1 jour
}));

// Gestion des utilisateurs connectés via Socket.IO
const connectedUsers = new Map();

// Nettoyage des utilisateurs inactifs toutes les 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [userId, userData] of connectedUsers.entries()) {
    if (now - userData.lastActive > 1000 * 60 * 30) { // 30 minutes d'inactivité
      connectedUsers.delete(userId);
      io.emit('user-disconnected', { userId });
    }
  }
}, 1000 * 60 * 5);

// Gestion des connexions Socket.IO
io.on('connection', (socket) => {
  console.log('Nouvelle connexion socket :', socket.id);

  // Lorsqu'un utilisateur se connecte avec son ID
  socket.on('user connected', async ({ userId }) => {
    console.log(`L'utilisateur ${userId} tente de se connecter.`);
    connectedUsers.set(userId.toString(), { socketId: socket.id, lastActive: Date.now() });
    socket.userId = userId;
    socket.broadcast.emit('user-connected', { userId: userId });
    io.emit('update online users', Array.from(connectedUsers.keys()));
    console.log(`L'utilisateur ${userId} connecté avec l'ID socket ${socket.id}`);

    try {
      await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [userId]);
    } catch (error) {
      logger.error('Échec de la mise à jour de lastSeen lors de la connexion :', { error: error.message });
    }
  });

  // Gestion des messages de chat
  socket.on('chat message', async (msg) => {
    console.log(`Nouveau message de ${msg.senderId} à ${msg.receiverId}: "${msg.content}"`);

    try {
      const result = await pool.query(
        'INSERT INTO messages (sender_id, receiver_id, content, status) VALUES ($1, $2, $3, $4) RETURNING id, sender_id, receiver_id, content, status, created_at AS timestamp',
        [msg.senderId, msg.receiverId, msg.content, 'sent']
      );
      const newMessage = result.rows[0];

      socket.emit('chat message', newMessage); // Émettre au sender avec statut 'sent'

      // Récupération du nom de l'expéditeur pour la notification
      const senderUserResult = await pool.query('SELECT role FROM users WHERE id = $1', [newMessage.sender_id]);
      const senderRole = senderUserResult.rows[0] ? senderUserResult.rows[0].role : null;

      let senderName = 'Utilisateur inconnu';
      if (senderRole) {
        let profileQuery;
        if (senderRole === 'client') {
          profileQuery = 'SELECT nom_complet FROM client_profiles WHERE user_id = $1';
        } else if (senderRole === 'artisan') {
          profileQuery = 'SELECT nom_complet FROM artisan_profiles WHERE user_id = $1';
        } else if (senderRole === 'commercant') {
          profileQuery = 'SELECT nom_entreprise FROM commercant_profiles WHERE user_id = $1';
        }

        if (profileQuery) {
          const senderProfileResult = await pool.query(profileQuery, [newMessage.sender_id]);
          if (senderProfileResult.rows[0]) {
            senderName = senderProfileResult.rows[0].nom_complet || senderProfileResult.rows[0].nom_entreprise;
          }
        }
      }

      const receiverUserData = connectedUsers.get(newMessage.receiver_id.toString());
      if (receiverUserData && receiverUserData.socketId !== socket.id) {
        console.log(`Le destinataire ${newMessage.receiverId} est connecté. Envoi du message et de la notification.`);
        io.to(receiverUserData.socketId).emit('chat message', newMessage);
        io.to(receiverUserData.socketId).emit('new-message-notification', {
          senderId: newMessage.sender_id,
          senderName: senderName,
          message: newMessage.content
        });
        // Mise à jour du statut du message à 'delivered' dans la base
        await pool.query('UPDATE messages SET status = $1 WHERE id = $2', ['delivered', newMessage.id]);
        newMessage.status = 'delivered'; // Mise à jour du statut dans l'objet envoyé au destinataire
        io.to(receiverUserData.socketId).emit('message-status-updated', newMessage); // Notifier le destinataire du changement de statut
      } else {
        console.log(`Le destinataire ${newMessage.receiverId} n'est pas connecté.`);
      }
    } catch (error) {
      logger.error('Erreur lors de la gestion du message de chat :', { error: error.message });
    }
  });

  // Gestion des déconnexions
  socket.on('disconnect', async () => {
    if (socket.userId) {
      console.log(`L'utilisateur ${socket.userId} s'est déconnecté.`);
      connectedUsers.delete(socket.userId.toString());
      socket.broadcast.emit('user-disconnected', { userId: socket.userId });
      io.emit('update online users', Array.from(connectedUsers.keys()));

      try {
        await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [socket.userId]);
      } catch (error) {
        logger.error('Échec de la mise à jour de lastSeen lors de la déconnexion :', { error: error.message });
      }
    } else {
      logger.info('Un utilisateur s\'est déconnecté (userId non défini sur le socket).');
    }
  });
});

// Configuration de Multer pour le stockage des images
const storage = multer.memoryStorage(); // Stockage en mémoire pour le traitement Sharp
const upload = multer({ storage: storage });

// Routes générales
app.get('/', healthCheck);
app.get('/api/system/version', getVersion);

// Routes API
app.use('/api/auth', authRoutes());
app.use('/api/reviews', reviewRoutes(io, connectedUsers));
app.use('/api/artisans', portfolioRoutes);
app.use('/api/demacheur', demacheurRoutes);
app.use('/api/profile', profileRoutes());

// Importation du contrôleur artisan
const artisanController = require('./controllers/artisanController');

// Routes Artisan
app.get('/api/artisans', authenticateToken, (req, res) => artisanController.getArtisans(req, res, connectedUsers));
app.get('/api/artisans/:id', (req, res) => artisanController.getArtisan(req, res, connectedUsers));

// Routes de messagerie
const messageRoutes = require('./routes/messageRoutes');
app.use('/api/messages', authenticateToken, (req, res, next) => {
  req.io = io;
  req.connectedUsers = connectedUsers;
  next();
}, messageRoutes);

// Routes de demandes de service
const demandeRoutes = require('./routes/demandeRoutes');
app.use('/api/demandes', authenticateToken, (req, res, next) => {
  req.io = io;
  req.connectedUsers = connectedUsers;
  next();
}, demandeRoutes);

// Routes de signalement
const reportRoutes = require('./routes/reportRoutes');
app.use('/api/reports', authenticateToken, reportRoutes);

// Routes admin
app.use('/api/admin', authenticateToken, authorizeRole(['admin']), require('./routes/adminRoutes'));

module.exports = app;