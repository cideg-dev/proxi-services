

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto'); // Added for Kkiapay webhook signature verification



const { check, validationResult, body } = require('express-validator');
const { sendNotificationEmail } = require('./services/emailService');

const sharp = require('sharp'); // Added for image optimization
// const { sendPasswordResetEmail } = require('./services/emailService.js'); // Not used in this file
const multer = require('multer');

// Haversine formula to calculate distance between two lat/lon points
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of Earth in kilometers

  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km
  return distance;
}

// Helper function to log audit actions
async function logAuditAction(userId, actionType, entityType, entityId, details) {
  try {
    await pool.query(
      `INSERT INTO audit_logs (user_id, action_type, entity_type, entity_id, details)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, actionType, entityType, entityId, details]
    );
  } catch (error) {
    console.error('Error logging audit action:', error);
  }
}

// Helper function to calculate profile completeness
const calculateProfileCompleteness = (profile, role) => {
  if (!profile) return 0;

  let totalFields = 0;
  let filledFields = 0;

  const checkField = (field) => {
    if (field !== null && field !== undefined && field !== '') {
      filledFields++;
    }
  };

  if (role === 'client') {
    const fields = ['nom_complet', 'location', 'telephone', 'photo_url'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  } else if (role === 'artisan') {
    const fields = ['nom_complet', 'specialite', 'description', 'location', 'telephone', 'annees_experience', 'photo_url', 'site_web'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  } else if (role === 'commercant') {
    const fields = ['nom_entreprise', 'type_commerce', 'description', 'adresse', 'location', 'telephone', 'photo_url', 'site_web'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  }

  if (totalFields === 0) return 100;
  return Math.round((filledFields / totalFields) * 100);
};
const pool = require('./db.config');
const { authenticateToken, authorizeRole } = require('./middleware/authMiddleware');
const authRoutes = require('./routes/authRoutes'); // Import auth routes
const reviewRoutes = require('./routes/reviewRoutes'); // Import review routes

// Vérification des variables d'environnement critiques
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('JWT_SECRET must be defined in environment variables');
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

// Middlewares
const corsOptions = {
  origin: 'https://cideg-dev.github.io',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));
app.use(express.json());

// Create a write stream for logging
const logStream = fs.createWriteStream(path.join(__dirname, 'request_log.txt'), { flags: 'a' });

// Temporary logging middleware
app.use((req, res, next) => {
  const log = `${new Date().toISOString()} - ${req.method} ${req.path}\n`;
  logStream.write(log);
  next();
});

app.use((req, res, next) => {
  const oldWrite = res.write;
  const oldEnd = res.end;
  const chunks = [];

  res.write = (...restArgs) => {
    chunks.push(Buffer.from(restArgs[0]));
    oldWrite.apply(res, restArgs);
  };

  res.end = (...restArgs) => {
    if (restArgs[0]) {
      chunks.push(Buffer.from(restArgs[0]));
    }
    const body = Buffer.concat(chunks).toString('utf8');

    const log = `${new Date().toISOString()} - ${req.method} ${req.originalUrl} ${res.statusCode} ${body}\n`;
    logStream.write(log);
    oldEnd.apply(res, restArgs);
  };

  next();
});
app.use('/uploads', express.static(__dirname + '/uploads', {
  maxAge: '1d' // Cache images for 1 day
}));



// Store connected users with timestamps
const connectedUsers = new Map();

// Clean up inactive users every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [userId, userData] of connectedUsers.entries()) {
    if (now - userData.lastActive > 1000 * 60 * 30) { // 30 minutes timeout
      connectedUsers.delete(userId);
      io.emit('user-disconnected', { userId });
    }
  }
}, 1000 * 60 * 5);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('New socket connection:', socket.id);

  // When a user sends their ID
  socket.on('user connected', async ({ userId }) => {
    connectedUsers.set(userId.toString(), { socketId: socket.id, lastActive: Date.now() });
    socket.userId = userId; // store userId on the socket object
    socket.broadcast.emit('user-connected', { userId: userId });
    io.emit('update online users', Array.from(connectedUsers.keys()));
    console.log(`User ${userId} connected with socket ID ${socket.id}`);

    try {
      await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [userId]);
    } catch (error) {
      console.error('Failed to update lastSeen on connect:', error);
    }
  });

  socket.on('chat message', async (msg) => {
    console.log('message: ' + msg.content);

    try {
      const result = await pool.query(
        'INSERT INTO messages (sender_id, receiver_id, content, status) VALUES ($1, $2, $3, $4) RETURNING id, sender_id, receiver_id, content, status, created_at AS timestamp',
        [msg.senderId, msg.receiverId, msg.content, 'sent']
      );
      const newMessage = result.rows[0];

      socket.emit('chat message', newMessage); // Emit to sender with 'sent' status

      // Fetch sender name for notification
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
        io.to(receiverUserData.socketId).emit('chat message', newMessage);
        io.to(receiverUserData.socketId).emit('new-message-notification', {
          senderId: newMessage.sender_id,
          senderName: senderName,
          message: newMessage.content
        });
        // Update message status to 'delivered' in DB
        await pool.query('UPDATE messages SET status = $1 WHERE id = $2', ['delivered', newMessage.id]);
        newMessage.status = 'delivered'; // Update status in the object sent to receiver
        io.to(receiverUserData.socketId).emit('message-status-updated', newMessage); // Notify receiver of status change
      }
    } catch (error) {
      console.error('Error handling chat message:', error);
    }
  });

  socket.on('disconnect', async () => {
    if (socket.userId) {
      console.log(`User ${socket.userId} disconnected.`);
      connectedUsers.delete(socket.userId.toString());
      socket.broadcast.emit('user-disconnected', { userId: socket.userId });
      io.emit('update online users', Array.from(connectedUsers.keys()));

      try {
        await pool.query('UPDATE users SET last_seen = NOW() WHERE id = $1', [socket.userId]);
      } catch (error) {
        console.error('Failed to update lastSeen on disconnect:', error);
      }
    } else {
      console.log('user disconnected');
    }
  });
});

// Configuration de Multer pour le stockage des images (en mémoire pour traitement Sharp)
const storage = multer.memoryStorage(); // Store in memory for Sharp processing

const upload = multer({ storage: storage });

// Route de test pour vérifier que le serveur fonctionne
app.get('/', (req, res) => {
  res.send('Le serveur backend Proxi-Services fonctionne !');
});

// --- API Routes --- 

app.use('/api/auth', authRoutes()); // Use auth routes
app.use('/api/reviews', reviewRoutes(io, connectedUsers)); // Use review routes

const artisanController = require('./controllers/artisanController');

// Artisan Routes
app.get('/api/artisans', (req, res) => artisanController.getArtisans(req, res, connectedUsers));
app.get('/api/artisans/:id', (req, res) => artisanController.getArtisan(req, res, connectedUsers));


// GET /api/messages/:user1Id/:user2Id - Get historical messages between two users
app.get('/api/messages/:user1Id/:user2Id', authenticateToken, async (req, res) => {
  const { user1Id, user2Id } = req.params;
  const loggedInUserId = req.user.id.toString();

  // Authorization: Ensure the logged-in user is one of the participants
  if (loggedInUserId !== user1Id && loggedInUserId !== user2Id) {
    return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez voir que vos propres messages.' });
  }

  try {
    const result = await pool.query(
      'SELECT id, sender_id, receiver_id, content, status, created_at AS timestamp FROM messages WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1) ORDER BY created_at ASC',
      [user1Id, user2Id]
    );
    res.json(result.rows);

  } catch (error) {
    console.error('Error fetching historical messages:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/conversations - Get all conversations for the logged-in user
app.get('/api/conversations', authenticateToken, async (req, res) => {
  const loggedInUserId = req.user.id;

  try {
    const messagesResult = await pool.query(
      'SELECT id, sender_id, receiver_id, content, created_at AS timestamp FROM messages WHERE sender_id = $1 OR receiver_id = $1 ORDER BY created_at ASC',
      [loggedInUserId]
    );
    const messages = messagesResult.rows;

    // Fetch all profiles and create a map
    const clientProfilesResult = await pool.query('SELECT user_id, nom_complet, photo_url FROM client_profiles');
    const artisanProfilesResult = await pool.query('SELECT user_id, nom_complet, photo_url FROM artisan_profiles');
    const commercantProfilesResult = await pool.query('SELECT user_id, nom_entreprise, photo_url FROM commercant_profiles');

    const profilesMap = new Map();
    clientProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_complet, imageUrl: p.photo_url }));
    artisanProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_complet, imageUrl: p.photo_url }));
    commercantProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_entreprise, imageUrl: p.photo_url }));

    // Fetch last_seen status for all users
    const usersResult = await pool.query('SELECT id, last_seen FROM users');
    const usersMap = new Map(usersResult.rows.map(user => [user.id, user]));


    const conversations = {};
    messages.forEach((msg) => {
      const partnerId = msg.sender_id === loggedInUserId ? msg.receiver_id : msg.sender_id;
      if (!conversations[partnerId]) {
        conversations[partnerId] = [];
      }
      conversations[partnerId].push(msg);
    });

    const conversationList = Object.keys(conversations).map((partnerId) => {
      const partnerProfile = profilesMap.get(parseInt(partnerId));
      const partnerUser = usersMap.get(parseInt(partnerId));
      const conversationMessages = conversations[partnerId];
      const lastMessage = conversationMessages.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))[0];
      const isOnline = connectedUsers.has(partnerId.toString());

      return {
        partner: {
          id: parseInt(partnerId),
          nom: partnerProfile ? partnerProfile.nom : 'Utilisateur inconnu',
          imageUrl: partnerProfile ? partnerProfile.imageUrl : null,
          isOnline: isOnline,
          lastSeen: partnerUser ? partnerUser.last_seen : null,
        },
        lastMessage: lastMessage,
      };
    });

    const sortedConversations = conversationList.sort((a, b) => new Date(b.lastMessage.timestamp) - new Date(a.lastMessage.timestamp));

    res.json(sortedConversations);

  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// DELETE /api/messages/:user1Id/:user2Id - Delete all messages between two users
app.delete('/api/messages/:user1Id/:user2Id', authenticateToken, async (req, res) => {
  const { user1Id, user2Id } = req.params;
  const loggedInUserId = req.user.id.toString();

  // Authorization: Ensure the logged-in user is one of the participants
  if (loggedInUserId !== user1Id && loggedInUserId !== user2Id) {
    return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez supprimer que vos propres conversations.' });
  }

  try {
    const result = await pool.query(
      'DELETE FROM messages WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)',
      [user1Id, user2Id]
    );

    if (result.rowCount === 0) {
      return res.status(200).json({ message: 'Aucun message à supprimer pour cette conversation.' });
    }

    res.status(200).json({ message: 'Historique de la conversation effacé avec succès.' });

  } catch (error) {
    console.error('Error deleting messages:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// PUT /api/messages/:messageId/read - Mark a message as read
app.put('/api/messages/:messageId/read', authenticateToken, async (req, res) => {
  const messageId = parseInt(req.params.messageId);
  const userId = req.user.id; // The user who is marking the message as read

  try {
    // Verify the message exists and the current user is the receiver
    const messageCheck = await pool.query(
      'SELECT sender_id, receiver_id, status FROM messages WHERE id = $1',
      [messageId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ message: 'Message non trouvé.' });
    }

    const message = messageCheck.rows[0];

    if (message.receiver_id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez marquer comme lu que les messages qui vous sont destinés.' });
    }

    // Only update if status is not already 'read'
    if (message.status !== 'read') {
      const result = await pool.query(
        'UPDATE messages SET status = $1 WHERE id = $2 RETURNING id, sender_id, receiver_id, content, status, created_at AS timestamp',
        ['read', messageId]
      );
      const updatedMessage = result.rows[0];

      // Emit a Socket.IO event to the sender to notify them that their message has been read
      const senderUserData = connectedUsers.get(updatedMessage.sender_id.toString());
      if (senderUserData) {
        io.to(senderUserData.socketId).emit('message-status-updated', updatedMessage);
      }

      return res.status(200).json({ message: 'Message marqué comme lu.', message: updatedMessage });
    }

    res.status(200).json({ message: 'Message déjà marqué comme lu.' });

  } catch (error) {
    console.error('Error marking message as read:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});




// POST /api/demandes - Create a new service request
// POST /api/demandes - Create a new service request
app.post('/api/demandes', authenticateToken, authorizeRole(['client']),
  [
    check('artisanId', 'L\'ID de l\'artisan est requis et doit être un entier').isInt(),
    check('serviceDescription', 'La description du service est requise').notEmpty().optional(),
    check('serviceIds', 'Les IDs de service doivent être un tableau d\'entiers').isArray().optional(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { artisanId, serviceDescription, serviceIds } = req.body;
    const clientId = req.user.id;

    try {
      // Verify artisan exists and has the correct role
      const artisanCheck = await pool.query('SELECT id FROM users WHERE id = $1 AND role = \'artisan\'', [artisanId]);
      if (artisanCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Artisan non trouvé.' });
      }

      // If serviceIds are provided, verify they exist for the given artisan
      if (serviceIds && serviceIds.length > 0) {
        const serviceCheck = await pool.query(
          'SELECT id FROM services WHERE artisan_id = $1 AND id = ANY($2::int[])',
          [artisanId, serviceIds]
        );
        if (serviceCheck.rows.length !== serviceIds.length) {
          return res.status(400).json({ message: 'Un ou plusieurs services demandés n\'existent pas pour cet artisan.' });
        }
      }
      
      const result = await pool.query(
        `INSERT INTO demandes (client_id, artisan_id, service_ids, service_description, status)
         VALUES ($1, $2, $3, $4, $5) RETURNING id, client_id, artisan_id, service_ids, service_description, status, created_at, updated_at`,
        [
          clientId,
          artisanId,
          serviceIds || null, // Store as array or null
          serviceDescription || null,
          'pending'
        ]
      );
      const newDemande = result.rows[0];

      // Notify the professional in real-time
      const professionalSocketData = connectedUsers.get(artisanId.toString());
      if (professionalSocketData) {
        io.to(professionalSocketData.socketId).emit('new-demand', newDemande);
      }

      res.status(201).json({ message: 'Demande de service créée avec succès.', demande: newDemande });

    } catch (error) {
      console.error('Error creating demand:', error);
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });

// POST /api/reports - Submit a new report
app.post('/api/reports', authenticateToken,
  [
    check('report_type', 'Le type de signalement est requis.').notEmpty(),
    check('reason', 'La raison du signalement est requise.').notEmpty(),
    // At least one of the reported IDs must be present
    body().custom((value, { req }) => {
      const { reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id } = req.body;
      if (!reported_user_id && !reported_message_id && !reported_review_id && !reported_portfolio_item_id) {
        throw new Error('Au moins un ID d\'entité signalée (utilisateur, message, avis, ou élément de portfolio) est requis.');
      }
      return true;
    }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const reporterId = req.user.id;
    const { report_type, reason, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id } = req.body;

    try {
      const result = await pool.query(
        `INSERT INTO reports (reporter_id, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id, report_type, reason, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending') RETURNING *`,
        [reporterId, reported_user_id, reported_message_id, reported_review_id, reported_portfolio_item_id, report_type, reason]
      );
      const newReport = result.rows[0];

      res.status(201).json({ message: 'Signalement soumis avec succès.', report: newReport });

    } catch (error) {
      console.error('Error submitting report:', error);
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });

// GET /api/admin/reports - Get all reports (for admin panel)
app.get('/api/admin/reports', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const { page = 1, limit = 10, status, report_type, search = '' } = req.query;
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT
        r.id,
        r.reason,
        r.status,
        r.report_type,
        r.created_at,
        r.resolved_at,
        r.reporter_id,
        r.reported_user_id,
        r.reported_message_id,
        r.reported_review_id,
        r.reported_portfolio_item_id,
        reporter.email AS reporter_email,
        COALESCE(reporter_cp.nom_complet, reporter_ap.nom_complet, reporter_comp.nom_entreprise) AS reporter_name,
        reported_user.email AS reported_user_email,
        COALESCE(reported_user_cp.nom_complet, reported_user_ap.nom_complet, reported_user_comp.nom_entreprise) AS reported_user_name
      FROM reports r
      JOIN users reporter ON r.reporter_id = reporter.id
      LEFT JOIN client_profiles reporter_cp ON reporter.id = reporter_cp.user_id
      LEFT JOIN artisan_profiles reporter_ap ON reporter.id = reporter_ap.user_id
      LEFT JOIN commercant_profiles reporter_comp ON reporter.id = reporter_comp.user_id
      LEFT JOIN users reported_user ON r.reported_user_id = reported_user.id
      LEFT JOIN client_profiles reported_user_cp ON reported_user.id = reported_user_cp.user_id
      LEFT JOIN artisan_profiles reported_user_ap ON reported_user.id = reported_user_ap.user_id
      LEFT JOIN commercant_profiles reported_user_comp ON reported_user.id = reported_user_comp.user_id
      WHERE 1=1
    `;

    let countQuery = `
      SELECT COUNT(r.id)
      FROM reports r
      JOIN users reporter ON r.reporter_id = reporter.id
      LEFT JOIN client_profiles reporter_cp ON reporter.id = reporter_cp.user_id
      LEFT JOIN artisan_profiles reporter_ap ON reporter.id = reporter_ap.user_id
      LEFT JOIN commercant_profiles reporter_comp ON reporter.id = reporter_comp.user_id
      LEFT JOIN users reported_user ON r.reported_user_id = reported_user.id
      LEFT JOIN client_profiles reported_user_cp ON reported_user.id = reported_user_cp.user_id
      LEFT JOIN artisan_profiles reported_user_ap ON reported_user.id = reported_user_ap.user_id
      LEFT JOIN commercant_profiles reported_user_comp ON reported_user.id = reported_user_comp.user_id
      WHERE 1=1
    `;

    const queryParams = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND r.status = $${paramIndex}`;
      countQuery += ` AND r.status = $${paramIndex}`;
      queryParams.push(status);
      paramIndex++;
    }
    if (report_type) {
      query += ` AND r.report_type = $${paramIndex}`;
      countQuery += ` AND r.report_type = $${paramIndex}`;
      queryParams.push(report_type);
      paramIndex++;
    }
    if (search) {
      query += ` AND LOWER(r.reason) LIKE $${paramIndex}`;
      countQuery += ` AND LOWER(r.reason) LIKE $${paramIndex}`;
      queryParams.push(`%${search.toLowerCase()}%`);
      paramIndex++;
    }

    query += ` ORDER BY r.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    const reportsResult = await pool.query(query, queryParams);
    const countResult = await pool.query(countQuery, queryParams.slice(0, queryParams.length - 2)); // Remove limit/offset for count

    res.json({
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit),
      reports: reportsResult.rows,
    });

  } catch (error) {
    console.error('Error fetching reports for admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// PUT /api/admin/reports/:id/resolve - Resolve or reject a report
app.put('/api/admin/reports/:id/resolve', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const reportId = parseInt(req.params.id);
  const { status } = req.body; // 'resolved' or 'rejected'
  const adminId = req.user.id;

  if (!['resolved', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'Statut de résolution invalide.' });
  }

  try {
    const result = await pool.query(
      'UPDATE reports SET status = $1, resolved_at = CURRENT_TIMESTAMP, resolved_by_admin_id = $2 WHERE id = $3 RETURNING *',
      [status, adminId, reportId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Signalement non trouvé.' });
    }

    res.status(200).json({ message: `Signalement marqué comme ${status} avec succès.`, report: result.rows[0] });

  } catch (error) {
    console.error('Error resolving report:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// DELETE /api/admin/reports/:id - Delete a report
app.delete('/api/admin/reports/:id', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const reportId = parseInt(req.params.id);

  try {
    const result = await pool.query('DELETE FROM reports WHERE id = $1 RETURNING id', [reportId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Signalement non trouvé.' });
    }

    res.status(200).json({ message: 'Signalement supprimé avec succès.' });

  } catch (error) {
    console.error('Error deleting report:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// POST /api/audit-logs - Log an audit action (internal use)
app.post('/api/audit-logs', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const { userId, actionType, entityType, entityId, details } = req.body;
  try {
    await logAuditAction(userId, actionType, entityType, entityId, details);
    res.status(200).json({ message: 'Audit action logged successfully.' });
  } catch (error) {
    console.error('Error logging audit action via API:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/admin/audit-logs - Get all audit logs (for admin panel)
app.get('/api/admin/audit-logs', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const { page = 1, limit = 10, userId, actionType, entityType, search = '' } = req.query;
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT
        al.id,
        al.user_id,
        al.action_type,
        al.entity_type,
        al.entity_id,
        al.details,
        al.timestamp,
        u.email AS user_email,
        COALESCE(cp.nom_complet, ap.nom_complet, comp.nom_entreprise) AS user_name
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles comp ON u.id = comp.user_id
      WHERE 1=1
    `;

    let countQuery = `
      SELECT COUNT(al.id)
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles comp ON u.id = comp.user_id
      WHERE 1=1
    `;

    const queryParams = [];
    let paramIndex = 1;

    if (userId) {
      query += ` AND al.user_id = $${paramIndex}`;
      countQuery += ` AND al.user_id = $${paramIndex}`;
      queryParams.push(parseInt(userId));
      paramIndex++;
    }
    if (actionType) {
      query += ` AND al.action_type = $${paramIndex}`;
      countQuery += ` AND al.action_type = $${paramIndex}`;
      queryParams.push(actionType);
      paramIndex++;
    }
    if (entityType) {
      query += ` AND al.entity_type = $${paramIndex}`;
      countQuery += ` AND al.entity_type = $${paramIndex}`;
      queryParams.push(entityType);
      paramIndex++;
    }
    if (search) {
      query += ` AND LOWER(al.details::text) LIKE $${paramIndex}`;
      countQuery += ` AND LOWER(al.details::text) LIKE $${paramIndex}`;
      queryParams.push(`%${search.toLowerCase()}%`);
      paramIndex++;
    }

    query += ` ORDER BY al.timestamp DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    const logsResult = await pool.query(query, queryParams);
    const countResult = await pool.query(countQuery, queryParams.slice(0, queryParams.length - 2)); // Remove limit/offset for count

    res.json({
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit),
      logs: logsResult.rows,
    });

  } catch (error) {
    console.error('Error fetching audit logs for admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// POST /api/payments/kkiapay/initiate - Initiate a Kkiapay payment
app.post('/api/payments/kkiapay/initiate', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { amount, reason } = req.body;

  if (!amount || amount <= 0 || !reason) {
    return res.status(400).json({ message: 'Montant et raison du paiement requis.' });
  }

  try {
    // Generate a unique transaction ID for our system
    const ourTransactionId = `kkiapay-${userId}-${Date.now()}`;

    // Store the transaction in our database with 'pending' status
    await pool.query(
      `INSERT INTO payments (user_id, amount, reason, kkiapay_transaction_id, status)
       VALUES ($1, $2, $3, $4, 'pending')`,
      [userId, amount, reason, ourTransactionId]
    );

    // Call Kkiapay API to initiate payment
    // You would typically make an HTTP POST request to Kkiapay's initiation endpoint.
    const kkiapayResponse = await axios.post('https://api.kkiapay.me/v1/initiate', {
      amount: amount,
      reason: reason,
      transactionId: ourTransactionId, // Ensure this is passed if Kkiapay requires it
      callBackUrl: `${process.env.FRONTEND_URL}/payment-callback`, // URL Kkiapay redirects to
      // Add other Kkiapay specific parameters like phone, email, etc.
    }, {
      headers: {
        'X-API-KEY': process.env.KKIAPAY_PUBLIC_KEY, // Or Secret Key depending on Kkiapay API
        'X-SECRET-KEY': process.env.KKIAPAY_SECRET_KEY,
        'Content-Type': 'application/json'
      }
    });
    const kkiapayPaymentUrl = kkiapayResponse.data.paymentUrl;

    res.status(200).json({ message: 'Paiement initié.', paymentUrl: kkiapayPaymentUrl, ourTransactionId: ourTransactionId });

  } catch (error) {
    console.error('Error initiating Kkiapay payment:', error);
    res.status(500).json({ message: 'Erreur interne du serveur lors de l\'initiation du paiement.' });
  }
});

// POST /api/payments/kkiapay/webhook - Kkiapay webhook endpoint
app.post('/api/payments/kkiapay/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const kkiapaySecret = process.env.KKIAPAY_SECRET_KEY;
  const signature = req.headers['x-kkiapay-signature']; // Kkiapay's signature header
  const rawBody = req.body.toString(); // Raw body for signature verification
  const expectedSignature = crypto.createHmac('sha256', kkiapaySecret)
                                  .update(rawBody)
                                  .digest('hex');

  if (signature !== expectedSignature) {
    console.error('Kkiapay webhook: Invalid signature.');
    return res.status(403).json({ message: 'Invalid webhook signature.' });
  }

  const event = JSON.parse(rawBody); // Kkiapay's event payload
  const kkiapayTransactionId = event.transactionId;
  const kkiapayStatus = event.status; // 'SUCCESS', 'FAILED', 'PENDING', 'CANCELED'
  const ourTransactionId = event.metadata?.ourTransactionId; // Assuming we pass this in metadata

  if (!ourTransactionId || !kkiapayTransactionId || !kkiapayStatus) {
    console.error('Kkiapay webhook: Missing essential transaction data in payload.', event);
    return res.status(400).json({ message: 'Missing essential transaction data in payload.' });
  }

  try {
    // Update our payment record
    const result = await pool.query(
      'UPDATE payments SET status = $1, kkiapay_transaction_id = $2, webhook_event = $3 WHERE kkiapay_transaction_id = $4 RETURNING *',
      [kkiapayStatus.toLowerCase(), kkiapayTransactionId, event, ourTransactionId]
    );

    if (result.rows.length === 0) {
      console.error('Kkiapay webhook: Our transaction ID not found:', ourTransactionId);
      return res.status(404).json({ message: 'Our transaction ID not found.' });
    }

    const updatedPayment = result.rows[0];

    // If payment is successful, trigger any post-payment actions (e.g., update user's profile boost)
    if (updatedPayment.status === 'success') {
      // Example: Update user's profile boost status
      // await pool.query('UPDATE user_profiles SET profile_boost_expires = NOW() + INTERVAL \'30 days\' WHERE user_id = $1', [updatedPayment.user_id]);
      console.log(`Payment ${updatedPayment.kkiapay_transaction_id} for user ${updatedPayment.user_id} successful.`);
    }

    res.status(200).json({ message: 'Webhook received and processed.' });

  } catch (error) {
    console.error('Error processing Kkiapay webhook:', error);
    res.status(500).json({ message: 'Erreur interne du serveur lors du traitement du webhook.' });
  }
});

// GET /api/payments/kkiapay/verify/:ourTransactionId - Verify Kkiapay payment status
app.get('/api/payments/kkiapay/verify/:ourTransactionId', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { ourTransactionId } = req.params;

  try {
    const result = await pool.query(
      'SELECT id, user_id, amount, status, kkiapay_transaction_id, created_at FROM payments WHERE kkiapay_transaction_id = $1 AND user_id = $2',
      [ourTransactionId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Transaction non trouvée ou non autorisée.' });
    }

    res.status(200).json({ message: 'Statut de paiement récupéré avec succès.', payment: result.rows[0] });

  } catch (error) {
    console.error('Error verifying Kkiapay payment:', error);
    res.status(500).json({ message: 'Erreur interne du serveur lors de la vérification du paiement.' });
  }
});

// GET /api/subscriptions - Get user's subscriptions
app.get('/api/subscriptions', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'SELECT id, subscription_type, start_date, end_date, status, created_at FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.status(200).json({ subscriptions: result.rows });

  } catch (error) {
    console.error('Error fetching user subscriptions:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// POST /api/subscriptions/subscribe - Create a new subscription
app.post('/api/subscriptions/subscribe', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { subscriptionType, paymentId } = req.body; // paymentId is our internal payment ID

  if (!subscriptionType || !paymentId) {
    return res.status(400).json({ message: 'Type d\'abonnement et ID de paiement requis.' });
  }

  try {
    // 1. Verify the payment
    const paymentResult = await pool.query(
      'SELECT id, user_id, amount, status, reason FROM payments WHERE id = $1 AND user_id = $2',
      [paymentId, userId]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({ message: 'Paiement non trouvé ou non autorisé.' });
    }
    const payment = paymentResult.rows[0];

    if (payment.status !== 'success') {
      return res.status(400).json({ message: 'Le paiement n\'a pas été effectué avec succès.' });
    }

    // 2. Create the subscription
    // Determine end date based on subscriptionType (example logic)
    let endDate = new Date();
    if (subscriptionType === 'profile_boost_1_week') {
      endDate.setDate(endDate.getDate() + 7);
    } else if (subscriptionType === 'profile_boost_1_month') {
      endDate.setMonth(endDate.getMonth() + 1);
    } else if (subscriptionType === 'profile_boost_3_months') {
      endDate.setMonth(endDate.getMonth() + 3);
    } else {
      return res.status(400).json({ message: 'Type d\'abonnement invalide.' });
    }

    const subscriptionResult = await pool.query(
      `INSERT INTO subscriptions (user_id, subscription_type, start_date, end_date, status)
       VALUES ($1, $2, CURRENT_TIMESTAMP, $3, 'active') RETURNING *`,
      [userId, subscriptionType, endDate]
    );
    const newSubscription = subscriptionResult.rows[0];

    // 3. Update user's profile (e.g., set profile boost expiry)
    // This depends on the actual profile structure. Example for artisan/commercant:
    // await pool.query('UPDATE artisan_profiles SET profile_boost_expires = $1 WHERE user_id = $2', [endDate, userId]);
    // await pool.query('UPDATE commercant_profiles SET profile_boost_expires = $1 WHERE user_id = $2', [endDate, userId]);

    res.status(201).json({ message: 'Abonnement créé avec succès.', subscription: newSubscription });

  } catch (error) {
    console.error('Error creating subscription:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// POST /api/subscriptions/cancel - Cancel an existing subscription
app.post('/api/subscriptions/cancel', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { subscriptionId } = req.body;

  if (!subscriptionId) {
    return res.status(400).json({ message: 'ID d\'abonnement requis.' });
  }

  try {
    // Verify the subscription exists and belongs to the user
    const subscriptionCheck = await pool.query(
      'SELECT id FROM subscriptions WHERE id = $1 AND user_id = $2',
      [subscriptionId, userId]
    );

    if (subscriptionCheck.rows.length === 0) {
      return res.status(404).json({ message: 'Abonnement non trouvé ou non autorisé.' });
    }

    const result = await pool.query(
      'UPDATE subscriptions SET status = \'canceled\', updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *' ,
      [subscriptionId]
    );
    const canceledSubscription = result.rows[0];

    res.status(200).json({ message: 'Abonnement annulé avec succès.', subscription: canceledSubscription });

  } catch (error) {
    console.error('Error canceling subscription:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/invoices - Get user's payment history (invoices)
app.get('/api/invoices', authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'SELECT id, amount, currency, reason, kkiapay_transaction_id, status, payment_method, created_at FROM payments WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.status(200).json({ invoices: result.rows });

  } catch (error) {
    console.error('Error fetching user invoices:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// POST /api/payments/kkiapay/initiate - Initiate a Kkiapay payment
app.post('/api/payments/kkiapay/initiate', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { amount, reason } = req.body;

  if (!amount || amount <= 0 || !reason) {
    return res.status(400).json({ message: 'Montant et raison du paiement requis.' });
  }

  try {
    // Generate a unique transaction ID for our system
    const ourTransactionId = `kkiapay-${userId}-${Date.now()}`;

    // Store the transaction in our database with 'pending' status
    await pool.query(
      `INSERT INTO payments (user_id, amount, reason, kkiapay_transaction_id, status)
       VALUES ($1, $2, $3, $4, 'pending')`,
      [userId, amount, reason, ourTransactionId]
    );

    // Call Kkiapay API to initiate payment
    // You would typically make an HTTP POST request to Kkiapay's initiation endpoint.
    const kkiapayResponse = await axios.post('https://api.kkiapay.me/v1/initiate', {
      amount: amount,
      reason: reason,
      transactionId: ourTransactionId, // Ensure this is passed if Kkiapay requires it
      callBackUrl: `${process.env.FRONTEND_URL}/payment-callback`, // URL Kkiapay redirects to
      // Add other Kkiapay specific parameters like phone, email, etc.
    }, {
      headers: {
        'X-API-KEY': process.env.KKIAPAY_PUBLIC_KEY, // Or Secret Key depending on Kkiapay API
        'X-SECRET-KEY': process.env.KKIAPAY_SECRET_KEY,
        'Content-Type': 'application/json'
      }
    });
    const kkiapayPaymentUrl = kkiapayResponse.data.paymentUrl;

    res.status(200).json({ message: 'Paiement initié.', paymentUrl: kkiapayPaymentUrl, ourTransactionId: ourTransactionId });

  } catch (error) {
    console.error('Error initiating Kkiapay payment:', error);
    res.status(500).json({ message: 'Erreur interne du serveur lors de l\'initiation du paiement.' });
  }
});




// The helper function recalculateAverageRating is no longer needed as logic is in the route
// const recalculateAverageRating = (artisan) => {
//   if (!artisan.reviews || artisan.reviews.length === 0) {
//     return 0;
//   }
//   const totalRating = artisan.reviews.reduce((sum, review) => sum + review.rating, 0);
//   return totalRating / artisan.reviews.length;
// };






// GET /api/clients/featured - Get a few clients for the homepage
app.get('/api/clients/featured', async (req, res) => {
  try {
    const result = await pool.query(
      `
        SELECT u.id, u.email, u.role, cp.*
        FROM users u
        JOIN client_profiles cp ON u.id = cp.user_id
        WHERE u.role = 'client'
        LIMIT 4
      `
    );
    const featuredClients = result.rows;
    
    res.json(featuredClients);

  } catch (error) {
    console.error('Error fetching featured clients:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});





// POST /api/artisans/:artisanId/favorites/:favoriteArtisanId - Add an artisan to favorites
app.post('/api/artisans/:artisanId/favorites/:favoriteArtisanId', authenticateToken,
  [
    check('artisanId', 'L\'ID utilisateur est requis et doit être un entier').isInt(),
    check('favoriteArtisanId', 'L\'ID de l\'artisan favori est requis et doit être un entier').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = parseInt(req.params.artisanId); // ID of the logged-in user (client or artisan)
    const favoriteArtisanId = parseInt(req.params.favoriteArtisanId); // ID of the artisan to favorite

    // Authorization: Ensure the logged-in user is the one whose favorites are being modified
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez modifier que vos propres favoris.' });
    }

    try {
      // Verify that both users exist
      const userCheck = await pool.query('SELECT id FROM users WHERE id = $1', [userId]);
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }
      const favoriteArtisanCheck = await pool.query('SELECT id FROM users WHERE id = $1 AND role = \'artisan\'', [favoriteArtisanId]);
      if (favoriteArtisanCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Artisan à ajouter aux favoris non trouvé.' });
      }

      const result = await pool.query(
        'INSERT INTO favorites (user_id, favorite_artisan_id) VALUES ($1, $2) ON CONFLICT (user_id, favorite_artisan_id) DO NOTHING',
        [userId, favoriteArtisanId]
      );

      if (result.rowCount === 0) {
        // No row was inserted, meaning it already existed due to ON CONFLICT DO NOTHING
        return res.status(409).json({ message: 'Cet artisan est déjà dans vos favoris.' });
      }

      res.status(200).json({ message: 'Artisan ajouté aux favoris avec succès !' });

    } catch (error) {
      console.error('Error adding favorite:', error);
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });

// DELETE /api/artisans/:artisanId/favorites/:favoriteArtisanId - Remove an artisan from favorites
app.delete('/api/artisans/:artisanId/favorites/:favoriteArtisanId', authenticateToken,
  [
    check('artisanId', 'L\'ID utilisateur est requis et doit être un entier').isInt(),
    check('favoriteArtisanId', 'L\'ID de l\'artisan favori est requis et doit être un entier').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = parseInt(req.params.artisanId); // ID of the logged-in user (client or artisan)
    const favoriteArtisanId = parseInt(req.params.favoriteArtisanId); // ID of the artisan to remove

    // Authorization: Ensure the logged-in user is the one whose favorites are being modified
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez modifier que vos propres favoris.' });
    }

    try {
      // Verify that the user exists
      const userCheck = await pool.query('SELECT id FROM users WHERE id = $1', [userId]);
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      const result = await pool.query(
        'DELETE FROM favorites WHERE user_id = $1 AND favorite_artisan_id = $2',
        [userId, favoriteArtisanId]
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ message: 'Artisan non trouvé dans les favoris.' });
      }

      res.status(200).json({ message: 'Artisan supprimé des favoris avec succès !' });

    } catch (error) {
      console.error('Error deleting favorite:', error);
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });


// GET /api/artisans/:artisanId/favorites - Get a user\'s favorite artisans
app.get('/api/artisans/:artisanId/favorites', authenticateToken,
  [
    check('artisanId', 'L\'ID utilisateur est requis et doit être un entier').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = parseInt(req.params.artisanId); // ID of the logged-in user (client or artisan)
    const { sortBy, latitude, longitude } = req.query; // New query parameters

    // Authorization: Ensure the logged-in user is the one whose favorites are being requested
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez voir que vos propres favoris.' });
    }

    try {
      // Verify that the user exists
      const userCheck = await pool.query('SELECT id FROM users WHERE id = $1', [userId]);
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      const result = await pool.query(
        `SELECT
         f.favorite_artisan_id AS id,
         u.email,
         u.role,
         COALESCE(ap.nom_complet, cp.nom_entreprise) AS name,
         COALESCE(ap.specialite, cp.type_commerce) AS specialty,
         COALESCE(ap.location, cp.location) AS location,
         COALESCE(ap.photo_url, cp.photo_url) AS photo_url
       FROM favorites f
       JOIN users u ON f.favorite_artisan_id = u.id
       LEFT JOIN artisan_profiles ap ON f.favorite_artisan_id = ap.user_id
       LEFT JOIN commercant_profiles cp ON f.favorite_artisan_id = cp.user_id
       WHERE f.user_id = $1`,
        [userId]
      );
      let favorites = result.rows;

      // Implement sorting by distance if requested
      if (sortBy === 'distance' && latitude && longitude) {
        const userLat = parseFloat(latitude);
        const userLon = parseFloat(longitude);

        if (isNaN(userLat) || isNaN(userLon)) {
          return res.status(400).json({ message: 'Latitude et longitude invalides pour le tri par distance.' });
        }

        favorites = favorites.map(fav => {
          if (fav.location) {
            // Assuming location is stored as 'latitude,longitude' string
            const [profLat, profLon] = fav.location.split(',').map(parseFloat);
            if (!isNaN(profLat) && !isNaN(profLon)) {
              fav.distance = haversineDistance(userLat, userLon, profLat, profLon);
            } else {
              fav.distance = Infinity; // Cannot calculate distance
            }
          } else {
            fav.distance = Infinity; // No location data
          }
          return fav;
        });

        favorites.sort((a, b) => a.distance - b.distance);
      }

      res.json(favorites);

    } catch (error) {
      console.error('Error fetching favorites:', error);
      res.status(500).json({ message: 'Erreur interne du serveur.' });
    }
  });




// GET /api/clients - Get all clients or search by name/location
app.get('/api/clients', authenticateToken, authorizeRole(['artisan']), async (req, res) => {
  const { name, location } = req.query;

  try {
    let query = `
      SELECT u.id, u.email, u.role, cp.*
      FROM users u
      JOIN client_profiles cp ON u.id = cp.user_id
      WHERE u.role = 'client'
    `;
    const values = [];
    let paramIndex = 1;

    if (name) {
      const searchTerm = `%${name.toLowerCase()}%`;
      query += ` AND LOWER(cp.nom_complet) LIKE $${paramIndex}`;
      values.push(searchTerm);
      paramIndex++;
    }

    if (location) {
      const locationSearchTerm = `%${location.toLowerCase()}%`;
      query += ` AND LOWER(cp.location) LIKE $${paramIndex}`;
      values.push(locationSearchTerm);
      paramIndex++;
    }

    const result = await pool.query(query, values);
    const clients = result.rows;

    res.json(clients);

  } catch (error) {
    console.error('Error fetching clients:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/client/demandes - Get all service requests made by the logged-in client
app.get('/api/client/demandes', authenticateToken, authorizeRole(['client']), async (req, res) => {
  const clientId = req.user.id;

  try {
    const result = await pool.query(
      `SELECT
        d.id,
        d.client_id,
        d.artisan_id,
        d.service_ids,
        d.service_description,
        d.status,
        d.created_at,
        d.updated_at,
        COALESCE(ap.nom_complet, cp.nom_entreprise) AS professional_name
      FROM demandes d
      LEFT JOIN artisan_profiles ap ON d.artisan_id = ap.user_id
      LEFT JOIN commercant_profiles cp ON d.artisan_id = cp.user_id
      WHERE d.client_id = $1`,
      [clientId]
    );
    res.json(result.rows);

  } catch (error) {
    console.error('Error fetching client demands:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});



// GET /api/artisan/demandes - Get all service requests made to the logged-in artisan
app.get('/api/artisan/demandes', authenticateToken, authorizeRole(['artisan']), async (req, res) => {
  const artisanId = req.user.id;

  try {
    const result = await pool.query(
      `SELECT 
         d.id, 
         d.client_id, 
         d.artisan_id, 
         d.service_ids, 
         d.service_description, 
         d.status, 
         d.created_at, 
         d.updated_at, 
         cp.nom_complet AS clientNom 
       FROM demandes d
       JOIN client_profiles cp ON d.client_id = cp.user_id
       WHERE d.artisan_id = $1`,
      [artisanId]
    );
    res.json(result.rows);

  } catch (error) {
    console.error('Error fetching artisan demands:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});




// POST /api/profile - Create a new profile for the logged-in user
app.post('/api/profile', authenticateToken,
  [
    // General email validation (optional as email is from user token)
    check('email', 'Veuillez inclure un email valide').optional().isEmail(),

    // Client profile validation
    body('nom_complet', 'Le nom complet est requis').if(body('role').equals('client')).notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('client')).notEmpty(),

    // Artisan profile validation
    body('nom_complet', 'Le nom complet est requis').if(body('role').equals('artisan')).notEmpty(),
    body('specialite', 'La spécialité est requise').if(body('role').equals('artisan')).notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('artisan')).notEmpty(),

    // Commercant profile validation
    body('nom_entreprise', 'Le nom de l\'entreprise est requis').if(body('role').equals('commercant')).notEmpty(),
    body('adresse', 'L\'adresse est requise').if(body('role').equals('commercant')).notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('commercant')).notEmpty(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.user.id;
    const userRole = req.user.role;
    const profileData = req.body;

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Check if a profile already exists
      let profileCheck;
      if (userRole === 'client') {
        profileCheck = await client.query('SELECT user_id FROM client_profiles WHERE user_id = $1', [userId]);
      } else if (userRole === 'artisan') {
        profileCheck = await client.query('SELECT user_id FROM artisan_profiles WHERE user_id = $1', [userId]);
      } else if (userRole === 'commercant') {
        profileCheck = await client.query('SELECT user_id FROM commercant_profiles WHERE user_id = $1', [userId]);
      }

      if (profileCheck.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ message: 'Un profil existe déjà pour cet utilisateur.' });
      }

      let newProfile;

      if (userRole === 'client') {
        const { nom_complet, sexe, location, telephone, photo_url } = profileData;
        const result = await client.query(
          'INSERT INTO client_profiles (user_id, nom_complet, sexe, location, telephone, photo_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
          [userId, nom_complet, sexe, location, telephone, photo_url]
        );
        newProfile = result.rows[0];
      } else if (userRole === 'artisan') {
        const { nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url } = profileData;
        const result = await client.query(
          'INSERT INTO artisan_profiles (user_id, nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *',
          [userId, nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url]
        );
        newProfile = result.rows[0];
      } else if (userRole === 'commercant') {
        const { nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url } = profileData;
        const result = await client.query(
          'INSERT INTO commercant_profiles (user_id, nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *',
          [userId, nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url]
        );
        newProfile = result.rows[0];
      } else {
        await client.query('ROLLBACK');
        return res.status(400).json({ message: 'Rôle utilisateur inconnu.' });
      }

      await client.query('COMMIT');

      res.status(201).json({ message: 'Profil créé avec succès.', profile: newProfile });

    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error creating user profile:', error);
      res.status(500).json({ message: 'Erreur lors de la création du profil.' });
    } finally {
      client.release();
    }
  });

// PUT /api/profile - Update logged-in user\'s profile
app.put('/api/profile', authenticateToken,
  [
    // General email validation
    check('email', 'Veuillez inclure un email valide').optional().isEmail(),

    // Client profile validation
    body('nom_complet', 'Le nom complet est requis').if(body('role').equals('client')).optional().notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('client')).optional().notEmpty(),

    // Artisan profile validation
    body('nom_complet', 'Le nom complet est requis').if(body('role').equals('artisan')).optional().notEmpty(),
    body('specialite', 'La spécialité est requise').if(body('role').equals('artisan')).optional().notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('artisan')).optional().notEmpty(),

    // Commercant profile validation
    body('nom_entreprise', 'Le nom de l\'entreprise est requis').if(body('role').equals('commercant')).optional().notEmpty(),
    body('adresse', 'L\'adresse est requise').if(body('role').equals('commercant')).optional().notEmpty(),
    body('location', 'La localisation est requise').if(body('role').equals('commercant')).optional().notEmpty(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.user.id;
    const userRole = req.user.role;
    const { email, ...profileData } = req.body;

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Update email in users table if provided
      if (email !== undefined) {
        const emailCheck = await client.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]);
        if (emailCheck.rows.length > 0) {
          await client.query('ROLLBACK');
          return res.status(400).json({ message: 'Cet email est déjà utilisé par un autre utilisateur.' });
        }
        await client.query('UPDATE users SET email = $1 WHERE id = $2', [email, userId]);
      }

      let updatedProfile;
      let profileCompletenessPercentage = 0;

      // Update profile table based on role
      const updates = [];
      const values = [];
      let paramIndex = 1;

      if (userRole === 'client') {
        if (profileData.nom_complet !== undefined) { updates.push(`nom_complet = $${paramIndex++}`); values.push(profileData.nom_complet); }
        if (profileData.sexe !== undefined) { updates.push(`sexe = $${paramIndex++}`); values.push(profileData.sexe); }
        if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
        if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
        if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }

        if (updates.length > 0) {
          values.push(userId);
          const profileUpdateQuery = `UPDATE client_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
          const result = await client.query(profileUpdateQuery, values);
          updatedProfile = result.rows[0];
        }
        // Recalculate completeness based on the updated profile data
        const currentProfileResult = await client.query('SELECT * FROM client_profiles WHERE user_id = $1', [userId]);
        profileCompletenessPercentage = calculateProfileCompleteness(currentProfileResult.rows[0], userRole);

      } else if (userRole === 'artisan') {
        if (profileData.nom_complet !== undefined) { updates.push(`nom_complet = $${paramIndex++}`); values.push(profileData.nom_complet); }
        if (profileData.sexe !== undefined) { updates.push(`sexe = $${paramIndex++}`); values.push(profileData.sexe); }
        if (profileData.specialite !== undefined) { updates.push(`specialite = $${paramIndex++}`); values.push(profileData.specialite); }
        if (profileData.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(profileData.description); }
        if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
        if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
        if (profileData.annees_experience !== undefined) { updates.push(`annees_experience = $${paramIndex++}`); values.push(profileData.annees_experience); }
        if (profileData.siret !== undefined) { updates.push(`siret = $${paramIndex++}`); values.push(profileData.siret); }
        if (profileData.site_web !== undefined) { updates.push(`site_web = $${paramIndex++}`); values.push(profileData.site_web); }
        if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }
        if (profileData.document_verification_url !== undefined) { updates.push(`document_verification_url = $${paramIndex++}`); values.push(profileData.document_verification_url); }

        if (updates.length > 0) {
          values.push(userId);
          const profileUpdateQuery = `UPDATE artisan_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
          const result = await client.query(profileUpdateQuery, values);
          updatedProfile = result.rows[0];
        }
        // Recalculate completeness based on the updated profile data
        const currentProfileResult = await client.query('SELECT * FROM artisan_profiles WHERE user_id = $1', [userId]);
        profileCompletenessPercentage = calculateProfileCompleteness(currentProfileResult.rows[0], userRole);

      } else if (userRole === 'commercant') {
        if (profileData.nom_entreprise !== undefined) { updates.push(`nom_entreprise = $${paramIndex++}`); values.push(profileData.nom_entreprise); }
        if (profileData.sexe_contact !== undefined) { updates.push(`sexe_contact = $${paramIndex++}`); values.push(profileData.sexe_contact); }
        if (profileData.type_commerce !== undefined) { updates.push(`type_commerce = $${paramIndex++}`); values.push(profileData.type_commerce); }
        if (profileData.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(profileData.description); }
        if (profileData.adresse !== undefined) { updates.push(`adresse = $${paramIndex++}`); values.push(profileData.adresse); }
        if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
        if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
        if (profileData.siret !== undefined) { updates.push(`siret = $${paramIndex++}`); values.push(profileData.siret); }
        if (profileData.site_web !== undefined) { updates.push(`site_web = $${paramIndex++}`); values.push(profileData.site_web); }
        if (profileData.horaires_ouverture !== undefined) { updates.push(`horaires_ouverture = $${paramIndex++}`); values.push(profileData.horaires_ouverture); }
        if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }
        if (profileData.document_verification_url !== undefined) { updates.push(`document_verification_url = $${paramIndex++}`); values.push(profileData.document_verification_url); }

        if (updates.length > 0) {
          values.push(userId);
          const profileUpdateQuery = `UPDATE commercant_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
          const result = await client.query(profileUpdateQuery, values);
          updatedProfile = result.rows[0];
        }
        // Recalculate completeness based on the updated profile data
        const currentProfileResult = await client.query('SELECT * FROM commercant_profiles WHERE user_id = $1', [userId]);
        profileCompletenessPercentage = calculateProfileCompleteness(currentProfileResult.rows[0], userRole);

      } else {
        await client.query('ROLLBACK');
        return res.status(400).json({ message: 'Rôle utilisateur inconnu.' });
      }

      await client.query('COMMIT');

      res.json({ message: 'Profil mis à jour avec succès.', profile: updatedProfile, completeness: profileCompletenessPercentage });

    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Error updating user profile:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour du profil.' });
    } finally {
      client.release();
    }
  });

// PUT /api/demandes/:id/status - Update status of a service request (by artisan)
app.put('/api/demandes/:id/status', authenticateToken, authorizeRole(['artisan']), async (req, res) => {
  const demandeId = parseInt(req.params.id);
  const { status } = req.body; // e.g., 'accepted', 'declined', 'completed'
  const artisanId = req.user.id; // Artisan ID from authenticated token

  if (!status) {
    return res.status(400).json({ message: 'Le statut est requis.' });
  }

  try {
    const result = await pool.query(
      'UPDATE demandes SET status = $1, updated_at = NOW() WHERE id = $2 AND artisan_id = $3 RETURNING id, client_id, artisan_id, service_ids, service_description, status, created_at, updated_at',
      [status, demandeId, artisanId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Demande de service non trouvée ou non autorisée.' });
    }

    const updatedDemande = result.rows[0];
    // Emit a Socket.IO event to the client whose demand status has changed
    io.to(connectedUsers.get(updatedDemande.client_id.toString())?.socketId).emit('demand-status-updated', updatedDemande);

    res.json({ message: 'Statut de la demande mis à jour avec succès.', demande: updatedDemande });

  } catch (error) {
    console.error('Error updating demand status:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// DELETE /api/demandes/:id - Cancel a service request (by client)
app.delete('/api/demandes/:id', authenticateToken, authorizeRole(['client']), async (req, res) => {
  const demandeId = parseInt(req.params.id);
  const clientId = req.user.id; // Client ID from authenticated token

  try {
    // First, get the demand to check its status and owner
    const demandQuery = await pool.query('SELECT * FROM demandes WHERE id = $1', [demandeId]);

    if (demandQuery.rows.length === 0) {
      return res.status(404).json({ message: 'Demande non trouvée.' });
    }

    const demand = demandQuery.rows[0];

    // Check if the user is the owner of the demand
    if (demand.client_id !== clientId) {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez annuler que vos propres demandes.' });
    }

    // Check if the demand is still pending
    if (demand.status !== 'pending') {
      return res.status(400).json({ message: `Impossible d\'annuler une demande qui est déjà "${demand.status}".` });
    }

    // If all checks pass, delete the demand
    await pool.query('DELETE FROM demandes WHERE id = $1', [demandeId]);

    res.status(200).json({ message: 'Demande annulée avec succès.' });

  } catch (error) {
    console.error('Error cancelling demand:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/demandes/:id - Get details of a specific service request
app.get('/api/demandes/:id', authenticateToken, async (req, res) => {
  const demandeId = parseInt(req.params.id);
  const userId = req.user.id;

  try {
    const result = await pool.query(`
      SELECT
        d.*,
        cp.nom_complet as client_name,
        ap.nom_complet as artisan_name
      FROM demandes d
      LEFT JOIN client_profiles cp ON d.client_id = cp.user_id
      LEFT JOIN artisan_profiles ap ON d.artisan_id = ap.user_id
      WHERE d.id = $1
    `, [demandeId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Demande non trouvée.' });
    }

    const demand = result.rows[0];

    // Security check: only the client or the artisan involved can see the demand
    if (userId !== demand.client_id && userId !== demand.artisan_id) {
      return res.status(403).json({ message: 'Action non autorisée.' });
    }

    res.json(demand);

  } catch (error) {
    console.error('Error fetching demand details:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});




// POST /api/users/:id/upload-photo
app.post('/api/users/:id/upload-photo', authenticateToken, upload.single('profileImage'), async (req, res) => {
  const userId = parseInt(req.params.id);
  const userRole = req.user.role;

  if (req.user.id !== userId) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  if (!req.file) {
    return res.status(400).json({ message: 'Aucun fichier n\'a été téléversé.' });
  }

  try {
    // Generate a unique filename with .webp extension
    const filename = `profile-${userId}-${Date.now()}.webp`;
    const outputPath = path.join(__dirname, 'uploads', filename);

    // Process image with sharp: resize, convert to webp, and save
    await sharp(req.file.buffer)
      .resize(200, 200, {
        fit: sharp.fit.cover,
        withoutEnlargement: true,
      })
      .webp({ quality: 80 })
      .toFile(outputPath);

    const photoUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;

    let updateQuery = '';
    if (userRole === 'client') {
      updateQuery = 'UPDATE client_profiles SET photo_url = $1 WHERE user_id = $2 RETURNING *';
    } else if (userRole === 'artisan') {
      updateQuery = 'UPDATE artisan_profiles SET photo_url = $1 WHERE user_id = $2 RETURNING *';
    } else if (userRole === 'commercant') {
      updateQuery = 'UPDATE commercant_profiles SET photo_url = $1 WHERE user_id = $2 RETURNING *';
    } else {
      return res.status(400).json({ message: 'Rôle utilisateur inconnu.' });
    }

    const result = await pool.query(updateQuery, [photoUrl, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Profil utilisateur non trouvé ou non autorisé.' });
    }

    res.json({ message: 'Image téléversée avec succès !', profile: result.rows[0] });

  } catch (error) {
    console.error('Error uploading profile image:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});


// Configuration de Multer pour le stockage des documents de vérification (en mémoire pour traitement Sharp)
const documentStorage = multer.memoryStorage(); // Store in memory for Sharp processing

const uploadDocument = multer({ storage: documentStorage });

// POST /api/users/:id/upload-document
app.post('/api/users/:id/upload-document', authenticateToken, uploadDocument.single('verificationDocument'), async (req, res) => {
  const userId = parseInt(req.params.id);
  const userRole = req.user.role;

  if (req.user.id !== userId) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  if (!req.file) {
    return res.status(400).json({ message: 'Aucun document n\'a été téléversé.' });
  }

  try {
    // Generate a unique filename with .webp extension
    const filename = `document-${userId}-${Date.now()}.webp`;
    const outputPath = path.join(__dirname, 'uploads', filename);

    // Process image with sharp: resize (max width 800), convert to webp, and save
    await sharp(req.file.buffer)
      .resize({ width: 800, withoutEnlargement: true }) // Resize to max width 800, maintain aspect ratio
      .webp({ quality: 80 })
      .toFile(outputPath);

    const documentUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;

    let updateQuery = '';
    if (userRole === 'artisan') {
      updateQuery = 'UPDATE artisan_profiles SET document_verification_url = $1, verification_status = \'pending\' WHERE user_id = $2 RETURNING *';
    } else if (userRole === 'commercant') {
      updateQuery = 'UPDATE commercant_profiles SET document_verification_url = $1, verification_status = \'pending\' WHERE user_id = $2 RETURNING *';
    } else {
      return res.status(400).json({ message: 'Ce rôle ne supporte pas le téléversement de document de vérification.' });
    }

    const result = await pool.query(updateQuery, [documentUrl, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Profil utilisateur non trouvé ou non autorisé.' });
    }

    const updatedProfile = result.rows[0];

    // Notify admins that a new document is pending verification
    try {
        const adminUsers = await pool.query("SELECT email FROM users WHERE role = 'admin'");
        if (adminUsers.rows.length > 0) {
            const professionalName = updatedProfile.nom_complet || updatedProfile.nom_entreprise || `Utilisateur ID: ${userId}`;
            const subject = `Nouveau document soumis pour vérification`;
            const html = `
                <p>Bonjour Administrateur,</p>
                <p>Un nouveau document a été soumis pour vérification par le professionnel : <strong>${professionalName}</strong>.</p>
                <p>Veuillez vous connecter au panel d'administration pour le traiter.</p>
                <p>Merci,</p>
                <p>Le système Proxi-Services</p>
            `;

            const adminEmails = adminUsers.rows.map(admin => admin.email);
            adminEmails.forEach(adminEmail => {
                sendNotificationEmail({
                    to: adminEmail,
                    subject: subject,
                    html: html,
                });
            });
        }
    } catch (emailError) {
        console.error('Failed to send KYC submission notification email:', emailError);
    }

    res.json({ message: 'Document téléversé avec succès !', profile: updatedProfile });

  } catch (error) {
    console.error('Error uploading verification document:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// Unused helper function
// const getNextId = (array) => {
//   return array.length > 0 ? Math.max(...array.map(item => item.id)) + 1 : 1;
// };

const serviceController = require('./controllers/serviceController');

// Service Management Endpoints
app.post('/api/artisans/:artisanId/services', authenticateToken, authorizeRole(['artisan']), serviceController.addService);
app.put('/api/artisans/:artisanId/services/:serviceId', authenticateToken, authorizeRole(['artisan']), serviceController.updateService);
app.delete('/api/artisans/:artisanId/services/:serviceId', authenticateToken, authorizeRole(['artisan']), serviceController.deleteService);

const portfolioController = require('./controllers/portfolioController');

// Portfolio Management Endpoints
app.post('/api/artisans/:artisanId/portfolio', authenticateToken, authorizeRole(['artisan']), upload.single('portfolioImage'), portfolioController.addPortfolioItem);
app.put('/api/artisans/:artisanId/portfolio/:portfolioId', authenticateToken, authorizeRole(['artisan']), upload.single('portfolioImage'), portfolioController.updatePortfolioItem);
app.delete('/api/artisans/:artisanId/portfolio/:portfolioId', authenticateToken, authorizeRole(['artisan']), portfolioController.deletePortfolioItem);

// --- Admin Verification Endpoints ---

// GET /api/admin/verifications - Get all pending verifications
app.get('/api/admin/verifications', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  try {
    const artisans = await pool.query(`
      SELECT u.id, ap.nom_complet as name, u.role, ap.document_verification_url, ap.verification_status
      FROM users u
      JOIN artisan_profiles ap ON u.id = ap.user_id
      WHERE ap.verification_status = 'pending'
    `);

    const commercants = await pool.query(`
      SELECT u.id, cp.nom_entreprise as name, u.role, cp.document_verification_url, cp.verification_status
      FROM users u
      JOIN commercant_profiles cp ON u.id = cp.user_id
      WHERE cp.verification_status = 'pending'
    `);

    res.json([...artisans.rows, ...commercants.rows]);

  } catch (error) {
    console.error('Error fetching pending verifications:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// PUT /api/admin/verifications/:userId - Update a user's verification status
app.put('/api/admin/verifications/:userId', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const { userId } = req.params;
  const { status } = req.body; // 'verified' or 'rejected'

  if (!['verified', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'Statut invalide.' });
  }

  try {
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Utilisateur non trouvé.' });
    }
    const { role } = userResult.rows[0];

    let updateQuery = '';
    if (role === 'artisan') {
      updateQuery = 'UPDATE artisan_profiles SET verification_status = $1 WHERE user_id = $2';
    } else if (role === 'commercant') {
      updateQuery = 'UPDATE commercant_profiles SET verification_status = $1 WHERE user_id = $2';
    } else {
      return res.status(400).json({ message: 'Le rôle de cet utilisateur ne supporte pas la vérification.' });
    }

    await pool.query(updateQuery, [status, userId]);

    // TODO: Send an email notification to the user

    res.status(200).json({ message: `Le statut de l\'utilisateur ${userId} a été mis à jour à "${status}".` });

  } catch (error) {
    console.error('Error updating verification status:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/admin/users - Get all users (for admin panel)
app.get('/api/admin/users', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const { page = 1, limit = 10, search = '' } = req.query;
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT
        u.id,
        u.email,
        u.role,
        u.last_seen,
        COALESCE(cp.nom_complet, ap.nom_complet, comp.nom_entreprise) AS name,
        COALESCE(cp.photo_url, ap.photo_url, comp.photo_url) AS photo_url,
        COALESCE(ap.verification_status, comp.verification_status) AS verification_status
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles comp ON u.id = comp.user_id
      WHERE
        LOWER(u.email) LIKE $3 OR
        LOWER(COALESCE(cp.nom_complet, ap.nom_complet, comp.nom_entreprise)) LIKE $3
      ORDER BY u.id
      LIMIT $1 OFFSET $2;
    `;

    const countQuery = `
      SELECT COUNT(u.id)
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN commercant_profiles comp ON u.id = comp.user_id
      WHERE
        LOWER(u.email) LIKE $1 OR
        LOWER(COALESCE(cp.nom_complet, ap.nom_complet, comp.nom_entreprise)) LIKE $1;
    `;

    const searchTerm = `%${search.toLowerCase()}%`;
    const usersResult = await pool.query(query, [limit, offset, searchTerm]);
    const countResult = await pool.query(countQuery, [searchTerm]);

    res.json({
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit),
      users: usersResult.rows,
    });

  } catch (error) {
    console.error('Error fetching users for admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /api/admin/users/:id - Get user details (for admin panel)
app.get('/api/admin/users/:id', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const userId = parseInt(req.params.id);

  try {
    const userResult = await pool.query('SELECT id, email, role, last_seen FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Utilisateur non trouvé.' });
    }
    const user = userResult.rows[0];

    let profile = null;
    if (user.role === 'client') {
      const profileResult = await pool.query('SELECT * FROM client_profiles WHERE user_id = $1', [userId]);
      profile = profileResult.rows[0];
    } else if (user.role === 'artisan') {
      const profileResult = await pool.query('SELECT * FROM artisan_profiles WHERE user_id = $1', [userId]);
      profile = profileResult.rows[0];
    } else if (user.role === 'commercant') {
      const profileResult = await pool.query('SELECT * FROM commercant_profiles WHERE user_id = $1', [userId]);
      profile = profileResult.rows[0];
    }

    res.json({ ...user, profile });

  } catch (error) {
    console.error('Error fetching user details for admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// PUT /api/admin/users/:id - Update user details (for admin panel)
app.put('/api/admin/users/:id', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const userId = parseInt(req.params.id);
  const { email, role } = req.body;

  try {
    // Basic validation
    if (email) {
      const emailCheck = await pool.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]);
      if (emailCheck.rows.length > 0) {
        return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
      }
    }

    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (email) { updates.push(`email = $${paramIndex++}`); values.push(email); }
    if (role) { updates.push(`role = $${paramIndex++}`); values.push(role); }

    if (updates.length === 0) {
      return res.status(400).json({ message: 'Aucun champ à mettre à jour.' });
    }

    values.push(userId);
    const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, email, role`;

    const result = await pool.query(query, values);

    res.json({ message: 'Utilisateur mis à jour avec succès.', user: result.rows[0] });

  } catch (error) {
    console.error('Error updating user from admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// DELETE /api/admin/users/:id - Delete a user (for admin panel)
app.delete('/api/admin/users/:id', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  const userId = parseInt(req.params.id);

  try {
    // Use a transaction to ensure all related data is deleted
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      // Delete from all related tables first
      await client.query('DELETE FROM favorites WHERE user_id = $1 OR favorite_artisan_id = $1', [userId]);
      await client.query('DELETE FROM reviews WHERE client_id = $1 OR artisan_id = $1', [userId]);
      await client.query('DELETE FROM demandes WHERE client_id = $1 OR artisan_id = $1', [userId]);
      await client.query('DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1', [userId]);
      await client.query('DELETE FROM portfolio_items WHERE artisan_id = $1', [userId]);
      await client.query('DELETE FROM services WHERE artisan_id = $1', [userId]);
      await client.query('DELETE FROM client_profiles WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM artisan_profiles WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM commercant_profiles WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM reports WHERE reporter_id = $1 OR reported_user_id = $1', [userId]);
      await client.query('DELETE FROM subscriptions WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM payments WHERE user_id = $1', [userId]);
      // Finally, delete from the users table
      const result = await client.query('DELETE FROM users WHERE id = $1 RETURNING id', [userId]);
      await client.query('COMMIT');

      if (result.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }

      res.status(200).json({ message: 'Utilisateur et toutes ses données associées ont été supprimés avec succès.' });

    } catch (transactionError) {
      await client.query('ROLLBACK');
      throw transactionError; // Rethrow to be caught by the outer catch block
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error deleting user from admin panel:', error);
    res.status(500).json({ message: 'Erreur interne du serveur lors de la suppression de l\'utilisateur.' });
  }
});



// Démarrage du serveur
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Le serveur est en écoute sur le port ${PORT}`);
});
