const { redisClient } = require('./cacheService');
const { logger } = require('../utils/logger');

/**
 * Service de gestion de la liste noire des tokens JWT
 * Permet de révoquer des tokens avant leur expiration
 */
class TokenBlacklistService {
  /**
   * Ajoute un token à la liste noire
   * @param {string} token - Le token à révoquer
   * @param {number} expiration - Durée d'expiration en secondes (généralement la durée restante du token)
   * @returns {Promise<boolean>} - Succès ou échec de l'opération
   */
  static async addToBlacklist(token, expiration) {
    try {
      // Récupérer le payload du token pour obtenir l'ID utilisateur
      const tokenParts = token.split('.');
      if (tokenParts.length !== 3) {
        throw new Error('Format de token invalide');
      }

      // Décoder l'en-tête et le payload (sans vérifier la signature)
      const payload = JSON.parse(atob(tokenParts[1]));
      const userId = payload.id;
      
      // Générer une clé unique pour ce token
      const tokenKey = `blacklisted_token:${token}`;
      const userTokensKey = `user_tokens:${userId}`;
      
      // Ajouter le token à la liste noire avec son expiration
      await redisClient.setEx(tokenKey, expiration, '1');
      
      // Ajouter le token à la liste des tokens de l'utilisateur
      await redisClient.sAdd(userTokensKey, token);
      
      // Donner un TTL de 30 jours à la liste des tokens de l'utilisateur
      await redisClient.expire(userTokensKey, 30 * 24 * 60 * 60);
      
      logger.info(`Token ajouté à la liste noire pour l'utilisateur ${userId}`, {
        userId,
        timestamp: new Date().toISOString()
      });
      
      return true;
    } catch (error) {
      logger.error('Erreur lors de l\'ajout du token à la liste noire', {
        error: error.message,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
  
  /**
   * Vérifie si un token est dans la liste noire
   * @param {string} token - Le token à vérifier
   * @returns {Promise<boolean>} - true si le token est révoqué, false sinon
   */
  static async isBlacklisted(token) {
    try {
      const tokenKey = `blacklisted_token:${token}`;
      const result = await redisClient.get(tokenKey);
      return result !== null;
    } catch (error) {
      logger.error('Erreur lors de la vérification de la liste noire', {
        error: error.message,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
  
  /**
   * Révoque tous les tokens d'un utilisateur
   * @param {number} userId - L'ID de l'utilisateur
   * @returns {Promise<boolean>} - Succès ou échec de l'opération
   */
  static async revokeAllTokens(userId) {
    try {
      const userTokensKey = `user_tokens:${userId}`;
      
      // Récupérer tous les tokens de l'utilisateur
      const tokens = await redisClient.sMembers(userTokensKey);
      
      if (tokens && tokens.length > 0) {
        // Calculer le temps écoulé depuis la première connexion pour déterminer l'expiration
        // (utilisation d'une valeur par défaut de 7 jours pour la révocation de tous les tokens)
        const expiration = 7 * 24 * 60 * 60; // 7 jours
        
        // Révoquer chaque token
        for (const token of tokens) {
          await redisClient.setEx(`blacklisted_token:${token}`, expiration, '1');
        }
        
        // Supprimer la liste des tokens de l'utilisateur
        await redisClient.del(userTokensKey);
      }
      
      logger.info(`Tous les tokens révoqués pour l'utilisateur ${userId}`, {
        userId,
        timestamp: new Date().toISOString()
      });
      
      return true;
    } catch (error) {
      logger.error('Erreur lors de la révocation de tous les tokens', {
        error: error.message,
        userId,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
  
  /**
   * Révoque les tokens d'un utilisateur sauf un token spécifique (pour la déconnexion d'autres sessions)
   * @param {number} userId - L'ID de l'utilisateur
   * @param {string} keepToken - Le token à conserver (optionnel)
   * @returns {Promise<boolean>} - Succès ou échec de l'opération
   */
  static async revokeOtherTokens(userId, keepToken = null) {
    try {
      const userTokensKey = `user_tokens:${userId}`;
      
      // Récupérer tous les tokens de l'utilisateur
      const tokens = await redisClient.sMembers(userTokensKey);
      
      if (tokens && tokens.length > 0) {
        const tokensToRevoke = keepToken ? tokens.filter(token => token !== keepToken) : tokens;
        
        // Calculer le temps d'expiration (7 jours pour la révocation)
        const expiration = 7 * 24 * 60 * 60; // 7 jours
        
        // Révoquer les tokens spécifiés
        for (const token of tokensToRevoke) {
          await redisClient.setEx(`blacklisted_token:${token}`, expiration, '1');
        }
        
        // Si un token doit être conservé, mettre à jour la liste
        if (keepToken) {
          await redisClient.del(userTokensKey);
          await redisClient.sAdd(userTokensKey, keepToken);
          
          // Donner un TTL de 30 jours à la liste des tokens de l'utilisateur
          await redisClient.expire(userTokensKey, 30 * 24 * 60 * 60);
        }
        
        logger.info(`Autres tokens révoqués pour l'utilisateur ${userId}`, {
          userId,
          keepToken: keepToken ? true : false,
          revokedCount: tokensToRevoke.length,
          timestamp: new Date().toISOString()
        });
      }
      
      return true;
    } catch (error) {
      logger.error('Erreur lors de la révocation des autres tokens', {
        error: error.message,
        userId,
        timestamp: new Date().toISOString()
      });
      return false;
    }
  }
}

module.exports = TokenBlacklistService;