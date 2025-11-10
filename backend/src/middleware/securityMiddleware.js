const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const validator = require('validator');
const hpp = require('hpp');
const cors = require('cors');

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limite chaque IP à 100 requêtes par windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Trop de demandes depuis cette adresse IP, veuillez réessayer plus tard.',
  skip: (req, res) => {
    // Vous pouvez ajouter des exceptions ici
    return req.path === '/health';
  }
});

// Configuration avancée de Helmet pour plus de sécurité
const helmetConfig = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:", "data:"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://*.kkiapay.net", "wss:", "https://api.example.com"], // Ajouter d'autres domaines si nécessaire
      frameSrc: ["https://www.kkiapay.tg"],
      objectSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000, // 1 an
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'DENY'
  },
  referrerPolicy: {
    policy: 'same-origin'
  },
  dnsPrefetchControl: {
    allow: false
  },
  noSniff: true,
  ieNoOpen: true,
});

// Sanitisation des données (contre injection NoSQL)
const sanitize = mongoSanitize();

// Protection contre XSS avec middleware personnalisé
const xssProtection = (req, res, next) => {
  // Nettoyer les propriétés du body
  if (req.body) {
    req.body = sanitizeObjectXSS(req.body);
  }
  
  // Nettoyer les query params
  if (req.query) {
    req.query = sanitizeObjectXSS(req.query);
  }
  
  // Nettoyer les params
  if (req.params) {
    req.params = sanitizeObjectXSS(req.params);
  }
  
  next();
};

// Fonction récursive pour nettoyer les objets contre XSS
function sanitizeObjectXSS(obj) {
  if (typeof obj !== 'object' || obj === null) {
    if (typeof obj === 'string') {
      return validator.escape(obj);
    }
    return obj;
  }
  
  Object.keys(obj).forEach(key => {
    if (typeof obj[key] === 'string') {
      obj[key] = validator.escape(obj[key]);
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      obj[key] = sanitizeObjectXSS(obj[key]);
    }
  });
  
  return obj;
}

// Protection contre la pollution du prototype (HPP)
const hppProtection = hpp();

// Configuration CORS sécurisée
const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      process.env.FRONTEND_URL || 'http://localhost:5173',
      'https://cideg-dev.github.io',
      'http://localhost:3000'  // Si vous avez un serveur de développement backend
    ];

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
  credentials: true,
  optionsSuccessStatus: 200
};

module.exports = {
  limiter,
  helmetConfig,
  sanitize,
  xssProtection,
  hppProtection,
  cors: cors(corsOptions)
};