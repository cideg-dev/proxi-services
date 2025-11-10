// Service pour la gestion granulaire des rôles et permissions

// Définition des permissions par ressource et action
const permissions = {
  user: {
    read: ['self', 'admin'],
    update: ['self', 'admin'],
    delete: ['self', 'admin'],
    block: ['admin']
  },
  profile: {
    read: ['self', 'authenticated'], // Tous les utilisateurs authentifiés peuvent lire
    update: ['self', 'admin'],
    delete: ['self', 'admin']
  },
  message: {
    read: ['sender', 'receiver', 'admin'],
    create: ['authenticated'],
    update: ['sender', 'admin'],
    delete: ['sender', 'admin']
  },
  review: {
    read: ['authenticated'],
    create: ['authenticated'],
    update: ['sender', 'admin'],
    delete: ['sender', 'admin']
  },
  admin: {
    dashboard: ['admin'],
    manage_users: ['admin'],
    manage_content: ['admin'],
    view_reports: ['admin']
  }
};

/**
 * Vérifier si un utilisateur a la permission d'effectuer une action
 * @param {string} resource - Ressource concernée (user, profile, message, etc.)
 * @param {string} action - Action à effectuer (read, create, update, delete)
 * @param {object} user - Objet utilisateur avec rôle et éventuellement ID
 * @param {object} resourceOwner - Propriétaire de la ressource (si applicable)
 * @returns {boolean} - Si l'utilisateur a la permission
 */
const checkPermission = (resource, action, user, resourceOwner = null) => {
  if (!permissions[resource] || !permissions[resource][action]) {
    return false;
  }

  const allowedRoles = permissions[resource][action];
  
  // Vérifier les permissions spécifiques au propriétaire
  if (resourceOwner) {
    if (allowedRoles.includes('self') && user.id === resourceOwner.id) {
      return true;
    }
    if (allowedRoles.includes('sender') && user.id === resourceOwner.senderId) {
      return true;
    }
    if (allowedRoles.includes('receiver') && user.id === resourceOwner.receiverId) {
      return true;
    }
  }
  
  // Vérifier les permissions basées sur le rôle
  return allowedRoles.includes(user.role) || allowedRoles.includes('authenticated');
};

/**
 * Middleware pour vérifier les permissions
 * @param {string} resource - Ressource concernée
 * @param {string} action - Action à effectuer
 */
const requirePermission = (resource, action) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentification requise' });
    }

    // Récupérer l'utilisateur propriétaire de la ressource si nécessaire
    let resourceOwner = null;
    
    // Dépend du contexte - cette logique devra être adaptée selon la route
    if (req.params.userId) {
      resourceOwner = { id: parseInt(req.params.userId) };
    } else if (req.params.id) {
      // On peut avoir besoin d'aller chercher des informations dans la base
      // selon le type de ressource
    }

    if (!checkPermission(resource, action, req.user.user, resourceOwner)) {
      return res.status(403).json({ message: 'Accès refusé : permission insuffisante' });
    }

    next();
  };
};

module.exports = {
  checkPermission,
  requirePermission
};