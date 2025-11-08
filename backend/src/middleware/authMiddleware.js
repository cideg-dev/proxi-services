const jwt = require('jsonwebtoken');
const pool = require('../../db.config');
const logger = require('../utils/logger');

// Middleware d'authentification
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ message: 'Accès refusé. Aucun token fourni.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await pool.query('SELECT id, email, role FROM users WHERE id = $1', [decoded.user.id]);

    if (user.rows.length === 0) {
      return res.status(401).json({ message: 'Token invalide. Utilisateur non trouvé.' });
    }

    req.user = { user: user.rows[0] };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(403).json({ message: 'Le token a expiré.' });
    }
    logger.error('Erreur d\'authentification:', { error: error.message });
    return res.status(403).json({ message: 'Token invalide.' });
  }
};

// Middleware d'autorisation basé sur le rôle
const authorizeRole = (roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.user.role)) {
      return res.status(403).json({ message: `Accès refusé. Rôle ${req.user?.user?.role || 'non spécifié'} non autorisé.` });
    }
    next();
  };
};

module.exports = {
  authenticateToken,
  authorizeRole
};