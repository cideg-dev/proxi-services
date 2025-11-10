// Service pour la gestion de la confidentialité et des données personnelles

const path = require('path');
const dbConfigPath = path.join(__dirname, '..', 'db.config');
const pool = require(dbConfigPath);
const logger = require('../utils/logger');

/**
 * Anonymiser un utilisateur et ses données associées
 * @param {number} userId - ID de l'utilisateur à anonymiser
 */
const anonymizeUser = async (userId) => {
  try {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // 1. Anonymiser le profil client s'il existe
      await client.query(
        'UPDATE client_profiles SET nom_complet = $1, sexe = NULL, telephone = NULL, adresse = NULL WHERE user_id = $2',
        [`Utilisateur_${userId}`, userId]
      );
      
      // 2. Anonymiser le profil artisan s'il existe
      await client.query(
        'UPDATE artisan_profiles SET nom_complet = $1, sexe = NULL, telephone = NULL WHERE user_id = $2',
        [`Artisan_${userId}`, userId]
      );
      
      // 3. Anonymiser le profil commerçant s'il existe
      await client.query(
        'UPDATE commercant_profiles SET nom_entreprise = $1, sexe_contact = NULL, telephone = NULL WHERE user_id = $2',
        [`Commerçant_${userId}`, userId]
      );
      
      // 4. Remplacer l'email par un email anonyme unique
      const anonymousEmail = `user_${userId}_${Date.now()}@anonymous.proxi-services`;
      await client.query(
        'UPDATE users SET email = $1 WHERE id = $2',
        [anonymousEmail, userId]
      );
      
      // 5. Mettre à jour les messages de l'utilisateur pour masquer son identité
      await client.query(
        'UPDATE messages SET content = $1 WHERE sender_id = $2',
        ['[Contenu du message supprimé lors de l\'anonymisation]', userId]
      );
      
      // 6. Mettre à jour les notes/avis de l'utilisateur
      await client.query(
        'UPDATE reviews SET comment = $1 WHERE client_id = $2',
        ['[Commentaire supprimé lors de l\'anonymisation]', userId]
      );
      
      // 7. Désactiver le compte utilisateur
      await client.query(
        'UPDATE users SET is_blocked = true WHERE id = $2',
        [userId]
      );
      
      await client.query('COMMIT');
      logger.info(`Utilisateur ${userId} anonymisé avec succès`);
      
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Erreur lors de l\'anonymisation de l\'utilisateur:', error.message);
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Erreur de connexion à la base lors de l\'anonymisation:', error.message);
    throw error;
  }
};

/**
 * Supprimer complètement un utilisateur et toutes ses données (selon les réglementations applicables)
 * @param {number} userId - ID de l'utilisateur à supprimer
 */
const deleteUser = async (userId) => {
  try {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Supprimer les données liées à l'utilisateur dans un ordre spécifique pour respecter les contraintes de clé étrangère
      await client.query('DELETE FROM refresh_tokens WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1', [userId, userId]);
      await client.query('DELETE FROM reviews WHERE client_id = $1 OR artisan_id = $1', [userId, userId]);
      await client.query('DELETE FROM favorites WHERE user_id = $1 OR favorite_artisan_id = $1', [userId, userId]);
      await client.query('DELETE FROM demandes WHERE client_id = $1 OR artisan_id = $1', [userId, userId]);
      await client.query('DELETE FROM services WHERE artisan_id = $1', [userId]);
      await client.query('DELETE FROM portfolio_items WHERE artisan_id = $1', [userId]);
      await client.query('DELETE FROM payments WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM subscriptions WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM reports WHERE reporter_id = $1 OR reported_user_id = $1', [userId, userId]);
      
      // Supprimer les profils
      await client.query('DELETE FROM client_profiles WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM artisan_profiles WHERE user_id = $1', [userId]);
      await client.query('DELETE FROM commercant_profiles WHERE user_id = $1', [userId]);
      
      // Supprimer l'utilisateur
      await client.query('DELETE FROM users WHERE id = $1', [userId]);
      
      await client.query('COMMIT');
      logger.info(`Utilisateur ${userId} supprimé avec succès`);
      
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Erreur lors de la suppression de l\'utilisateur:', error.message);
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('Erreur de connexion à la base lors de la suppression:', error.message);
    throw error;
  }
};

/**
 * Obtenir un export des données personnelles d'un utilisateur
 * @param {number} userId - ID de l'utilisateur
 */
const exportUserData = async (userId) => {
  try {
    const userData = {};
    
    // Récupérer les informations de base de l'utilisateur
    const userResult = await pool.query('SELECT id, email, role, created_at FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length > 0) {
      userData.user = userResult.rows[0];
    }
    
    // Récupérer les données de profil
    const clientProfileResult = await pool.query('SELECT * FROM client_profiles WHERE user_id = $1', [userId]);
    if (clientProfileResult.rows.length > 0) {
      userData.clientProfile = clientProfileResult.rows[0];
    }
    
    const artisanProfileResult = await pool.query('SELECT * FROM artisan_profiles WHERE user_id = $1', [userId]);
    if (artisanProfileResult.rows.length > 0) {
      userData.artisanProfile = artisanProfileResult.rows[0];
    }
    
    const commercantProfileResult = await pool.query('SELECT * FROM commercant_profiles WHERE user_id = $1', [userId]);
    if (commercantProfileResult.rows.length > 0) {
      userData.commercantProfile = commercantProfileResult.rows[0];
    }
    
    // Récupérer les messages récents
    const messagesResult = await pool.query(
      'SELECT * FROM messages WHERE sender_id = $1 OR receiver_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );
    userData.messages = messagesResult.rows;
    
    // Récupérer les avis
    const reviewsResult = await pool.query(
      'SELECT * FROM reviews WHERE client_id = $1 OR artisan_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );
    userData.reviews = reviewsResult.rows;
    
    return userData;
  } catch (error) {
    logger.error('Erreur lors de l\'export des données utilisateur:', error.message);
    throw error;
  }
};

module.exports = {
  anonymizeUser,
  deleteUser,
  exportUserData
};