// Application Express principale - Refactorisée avec améliorations de sécurité

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const axios = require('axios');

// Importation des contrôleurs
const { healthCheck, getVersion } = require('./controllers/generalController');

// Importation des services
const { haversineDistance, logAuditAction } = require('./services/generalService');

// Importation des utilitaires avec journalisation structurée
const { logger, logError } = require('./utils/logger');
const { monitorSensitiveAccess } = require('./utils/securityMonitoring');

const sharp = require('sharp');
const multer = require('multer');
const { validateFile } = require('./utils/fileValidation');
const { sendNotificationEmail } = require('./services/emailService');

// Importation des middlewares de validation
const { 
  handleValidationErrors,
  userProfileValidator,
  artisanServiceValidator,
  reviewValidator,
  demandeValidator
} = require('./middleware/validationMiddleware');

// Importation de la base de données
const pool = require('../db.config');

// Importation des middlewares d'authentification améliorés
const { 
  authenticateToken, 
  authorizeRole, 
  checkResourceOwnership, 
  sensitiveRouteProtection 
} = require('./middleware/authMiddleware');

const { calculateProfileCompleteness } = require('./services/profileService');

// Importation des routes
const authRoutes = require('./routes/authRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const portfolioRoutes = require('./routes/portfolioRoutes');
const demacheurRoutes = require('./routes/demacheurRoutes');
const profileRoutes = require('./routes/profileRoutes');
const aiRoutes = require('./routes/aiRoutes');

// Vérification des variables d'environnement critiques
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  logger.error('JWT_SECRET must be defined in environment variables');
  process.exit(1);
}

// Le refresh token est optionnel dans certains environnements
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'fallback_refresh_secret_for_dev';

// Avertir si le secret par défaut est utilisé en production
if (!process.env.JWT_REFRESH_SECRET && process.env.NODE_ENV === 'production') {
  logger.warn('Utilisation du secret de refresh token par défaut - RECOMMANDÉ DE CONFIGURER UNE VARIABLE D\'ENVIRONNEMENT PROPRE');
}

// Initialisation de l'application Express
const app = express();
const server = require('http').createServer(app);
const { Server } = require('socket.io');

// Ajout de headers de sécurité HTTP
app.use((req, res, next) => {
  // Désactiver le header X-Powered-By pour masquer le framework utilisé
  res.removeHeader('X-Powered-By');
  
  // Ajouter des headers de sécurité
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  
  next();
});
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Rendre l'instance Socket.IO disponible globalement
app.set('io', io);

// Configuration CORS sécurisée
const allowedOrigins = [
    process.env.FRONTEND_URL || 'http://localhost:5173', // URL frontend en production ou développement
    'https://cideg-dev.github.io' // Autorisation explicite de GitHub Pages
];

// Configuration CORS avec restrictions
app.use(cors({
  origin: function (origin, callback) {
    // Autoriser les requêtes sans origine (ex: mobile apps ou requêtes curl)
    if (!origin) return callback(null, true);

    // Vérifier si l'origine est dans la liste blanche
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      // En développement, autoriser les origines localhost
      if (process.env.NODE_ENV === 'development' && origin && origin.startsWith('http://localhost:')) {
        return callback(null, true);
      }
      const msg = 'La politique CORS de ce site n\'autorise pas ' +
                'l\'accès depuis l\'origine spécifiée : ' + origin;
      callback(new Error(msg), false);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true,
  optionsSuccessStatus: 200 // Pour les requêtes préflight
}));

app.use(express.json());

// Middleware de surveillance des accès sensibles
app.use(monitorSensitiveAccess);

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
    // Vérification que l'utilisateur existe et n'est pas bloqué
    const userResult = await pool.query('SELECT id, is_blocked FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0 || userResult.rows[0].is_blocked) {
      socket.emit('auth-error', { message: 'Accès refusé. Compte invalide ou bloqué.' });
      socket.disconnect();
      return;
    }

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
    try {
      // Vérifier que l'utilisateur est connecté
      if (!socket.userId) {
        socket.emit('error', { message: 'Utilisateur non connecté.' });
        return;
      }

      // Vérifier que l'expéditeur est bien l'utilisateur connecté
      if (socket.userId !== msg.senderId) {
        socket.emit('error', { message: 'Non autorisé à envoyer ce message.' });
        return;
      }

      // Vérifier que le destinataire existe et n'est pas bloqué
      const receiverResult = await pool.query('SELECT id, is_blocked FROM users WHERE id = $1', [msg.receiverId]);
      if (receiverResult.rows.length === 0 || receiverResult.rows[0].is_blocked) {
        socket.emit('error', { message: 'Destinataire invalide ou bloqué.' });
        return;
      }

      // Validation du contenu du message
      if (!msg.content || typeof msg.content !== 'string' || msg.content.trim().length === 0) {
        socket.emit('error', { message: 'Contenu du message requis et valide.' });
        return;
      }

      // Limiter la longueur du message
      if (msg.content.length > 1000) { // Limite de 1000 caractères
        socket.emit('error', { message: 'Message trop long (maximum 1000 caractères).' });
        return;
      }

      console.log(`Nouveau message de ${msg.senderId} à ${msg.receiverId}: "${msg.content}"`);

      // Insérer le message dans la base de données
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
        console.log(`Le destinataire ${newMessage.receiver_id} est connecté. Envoi du message et de la notification.`);
        io.to(receiverUserData.socketId).emit('chat message', newMessage);
        io.to(receiverUserData.socketId).emit('new-message-notification', {
          senderId: newMessage.sender_id,
          senderName: senderName,
          message: newMessage.content
        });
        // Mise à jour du statut du message à 'delivered' dans la base
        await pool.query('UPDATE messages SET status = $1 WHERE id = $2', ['delivered', newMessage.id]);
        newMessage.status = 'delivered'; // Mise à jour du statut dans l'objet envoyé au destinataire
        if (receiverUserData && receiverUserData.socketId) {
          io.to(receiverUserData.socketId).emit('message-status-updated', newMessage); // Notifier le destinataire du changement de statut
        }
      } else {
        console.log(`Le destinataire ${newMessage.receiver_id} n'est pas connecté.`);
      }
    } catch (error) {
      logger.error('Erreur lors de la gestion du message de chat :', { error: error.message });
      socket.emit('error', { message: 'Erreur lors de l\'envoi du message.' });
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
app.use('/api/ai', aiRoutes);

// Importation du contrôleur artisan
const artisanController = require('./controllers/artisanController');

// Routes Artisan
app.get('/api/artisans', (req, res) => artisanController.getArtisans(req, res, connectedUsers));
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

// Routes fonctionnalités générales
app.use('/api', require('./routes/generalFeaturesRoutes'));

// Routes des services professionnels
app.use('/api', require('./routes/professionalServicesRoutes'));

// Routes de confidentialité
app.use('/api', require('./routes/privacyRoutes'));

// Routes de gestion de la sécurité (MFA, audit)
app.use('/api', require('./routes/mfaRoutes'));
app.use('/api', require('./routes/auditRoutes'));

// Gestion des erreurs globales, y compris les erreurs de Multer
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'La taille du fichier est trop grande. Maximum 5 Mo autorisés.' });
    }
    if (error.code === 'LIMIT_UNEXPECTED_FILE') {
      return res.status(400).json({ message: 'Nom de champ de fichier incorrect.' });
    }
    return res.status(400).json({ message: 'Erreur lors de l\'upload du fichier.' });
  }
  
  if (error.message && error.message.includes('Type de fichier')) {
    return res.status(400).json({ message: error.message });
  }
  
  console.error('Erreur non gérée:', error);
  res.status(500).json({ message: 'Une erreur inattendue est survenue.' });
});

// Middleware pour Swagger UI - documentation API
if (process.env.NODE_ENV !== 'production') {
  const swaggerUi = require('swagger-ui-express');
  const swaggerSpecs = require('./utils/swagger');
  
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
    explorer: true,
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'Proxi-Services API Documentation'
  }));
}

// Gestion des erreurs globales avec le middleware centralisé
const { errorHandler } = require('./middleware/errorHandler');
app.use(errorHandler);

module.exports = app;