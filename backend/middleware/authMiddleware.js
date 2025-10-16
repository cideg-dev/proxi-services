const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      console.error('JWT Verification Error:', err.message); // Log the specific error
      return res.sendStatus(403);
    }
    req.user = user;
    next();
  });
};

const authorizeRole = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.user.role)) {
      return res.status(403).json({ message: 'Action non autorisée pour votre rôle.' });
    }
    next();
  };
};

module.exports = { authenticateToken, authorizeRole };