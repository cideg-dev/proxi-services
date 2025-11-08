// Routes pour la gestion des messages

const express = require('express');
const { check, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/authMiddleware');
const logger = require('../utils/logger');
const pool = require('../../db.config');

const router = express.Router();

// GET /:user1Id/:user2Id - Récupérer les messages historiques entre deux utilisateurs
router.get('/:user1Id/:user2Id', [
  check('user1Id', 'L\'ID utilisateur est requis et doit être un entier').isInt().toInt(),
  check('user2Id', 'L\'ID utilisateur est requis et doit être un entier').isInt().toInt(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { user1Id, user2Id } = req.params;
  const loggedInUserId = req.user.user.id.toString();

  // Autorisation: Vérifier que l'utilisateur connecté est l'un des participants
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
    logger.error('Erreur lors de la récupération des messages historiques :', { error: error.message });
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// GET /conversations - Récupérer toutes les conversations pour l'utilisateur connecté
router.get('/conversations', async (req, res) => {
  const loggedInUserId = req.user.user.id;

  try {
    const messagesResult = await pool.query(
      'SELECT id, sender_id, receiver_id, content, created_at AS timestamp FROM messages WHERE sender_id = $1 OR receiver_id = $1 ORDER BY created_at ASC',
      [loggedInUserId]
    );
    const messages = messagesResult.rows;

    // Récupération des profils et création d'une map
    const clientProfilesResult = await pool.query('SELECT user_id, nom_complet, photo_url FROM client_profiles');
    const artisanProfilesResult = await pool.query('SELECT user_id, nom_complet, photo_url FROM artisan_profiles');
    const commercantProfilesResult = await pool.query('SELECT user_id, nom_entreprise, photo_url FROM commercant_profiles');

    const profilesMap = new Map();
    clientProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_complet, imageUrl: p.photo_url }));
    artisanProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_complet, imageUrl: p.photo_url }));
    commercantProfilesResult.rows.forEach(p => profilesMap.set(p.user_id, { nom: p.nom_entreprise, imageUrl: p.photo_url }));

    // Récupération du statut last_seen pour tous les utilisateurs
    const usersResult = await pool.query('SELECT id, last_seen FROM users');
    const usersMap = new Map(usersResult.rows.map(user => [user.id, user]));

    // Récupération de la liste des utilisateurs connectés
    const io = req.app.get('io');
    const connectedUsers = req.app.get('connectedUsers') || new Map(); // Cette variable devrait être accessible globalement

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
      
      // Vérifier si l'utilisateur est en ligne
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
    logger.error('Erreur lors de la récupération des conversations :', { error: error.message });
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// DELETE /:user1Id/:user2Id - Supprimer tous les messages entre deux utilisateurs
router.delete('/:user1Id/:user2Id', [
  check('user1Id', 'L\'ID utilisateur est requis et doit être un entier').isInt().toInt(),
  check('user2Id', 'L\'ID utilisateur est requis et doit être un entier').isInt().toInt(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { user1Id, user2Id } = req.params;
  const loggedInUserId = req.user.user.id.toString();

  // Autorisation: Vérifier que l'utilisateur connecté est l'un des participants
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
    logger.error('Erreur lors de la suppression des messages :', { error: error.message });
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

// PUT /:messageId/read - Marquer un message comme lu
router.put('/:messageId/read', [
  check('messageId', 'L\'ID du message est requis et doit être un entier').isInt().toInt(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const messageId = parseInt(req.params.messageId);
  const userId = req.user.user.id; // L'utilisateur qui marque le message comme lu

  try {
    // Vérification de l'existence du message et que l'utilisateur est le destinataire
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

    // Mettre à jour seulement si le statut n'est pas déjà 'read'
    if (message.status !== 'read') {
      const result = await pool.query(
        'UPDATE messages SET status = $1 WHERE id = $2 RETURNING id, sender_id, receiver_id, content, status, created_at AS timestamp',
        ['read', messageId]
      );
      const updatedMessage = result.rows[0];

      // Émettre un événement Socket.IO au sender pour les informer que leur message a été lu
      const senderUserData = req.connectedUsers.get(updatedMessage.sender_id.toString());
      if (senderUserData) {
        req.io.to(senderUserData.socketId).emit('message-status-updated', updatedMessage);
      }
      
      return res.status(200).json({ message: 'Message marqué comme lu.', message: updatedMessage });
    }

    res.status(200).json({ message: 'Message déjà marqué comme lu.' });
  } catch (error) {
    logger.error('Erreur lors du marquage du message comme lu :', { error: error.message });
    res.status(500).json({ message: 'Erreur interne du serveur.' });
  }
});

module.exports = router;