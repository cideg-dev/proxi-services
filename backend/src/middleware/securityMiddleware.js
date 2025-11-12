const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const validator = require('validator');
const hpp = require('hpp');
const cors = require('cors');
const SecurityMonitoringService = require('../services/securityMonitoringService');

// Configuration avancée du rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 500, // Limite chaque IP à 100 reqs (500 en dev)
  standardHeaders: true, // Retourne les infos de rate limit dans les headers
  legacyHeaders: false, // Désactive les headers 'X-RateLimit-*'
  message: {
    error: 'Trop de demandes depuis cette adresse IP, veuillez réessayer plus tard.',
    code: 429
  },
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
      scriptSrc: ["'self'", "'strict-dynamic'", "'unsafe-inline'"], // Utiliser 'strict-dynamic' pour une sécurité renforcée
      scriptSrcAttr: ["'none'"], // Empêche les attributs de script en ligne
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://*.kkiapay.net", "wss:", "https://api.example.com"], // Ajouter d'autres domaines si nécessaire
      frameSrc: ["https://www.kkiapay.tg"],
      objectSrc: ["'none'"],
      baseUri: ["'none'"], // Empêche l'utilisation de balises <base>
      formAction: ["'self'"], // Restreint les actions de formulaire
      frameAncestors: ["'none'"], // Empêche l'incorporation dans des iframes (anti-clickjacking)
    },
  },
  hsts: {
    maxAge: 31536000, // 1 an
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'DENY' // Empêche le rendu dans des iframes (anti-clickjacking)
  },
  referrerPolicy: {
    policy: 'strict-origin-when-cross-origin' // Réduit les fuites de referrer
  },
  dnsPrefetchControl: {
    allow: false // Désactive le prefetch DNS
  },
  noSniff: true, // Empêche le MIME type sniffing
  ieNoOpen: true, // Empêche IE de s'exécuter en mode "Open"
  xssFilter: true, // Active le filtre XSS d'IE/Chrome
  hidePoweredBy: true, // Cache le header X-Powered-By
});

// Sanitisation des données (contre injection NoSQL)
const sanitize = mongoSanitize({
  allowDots: false, // Désactive l'accès aux propriétés imbriquées avec des points
  replaceWith: '_', // Remplace les caractères problématiques par _
});

// Protection contre XSS avec middleware personnalisé (amélioré)
const xssProtection = (req, res, next) => {
  // Détecter les requêtes potentiellement suspectes
  if (SecurityMonitoringService.detectSuspiciousRequest(req)) {
    return res.status(413).json({ 
      success: false, 
      message: 'Requête trop volumineuse ou suspecte' 
    });
  }

  // Nettoyer les propriétés du body
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObjectXSS(req.body);
  }

  // Nettoyer les query params
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObjectXSS(req.query);
  }

  // Nettoyer les params
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeObjectXSS(req.params);
  }

  next();
};

// Fonction récursive pour nettoyer les objets contre XSS
function sanitizeObjectXSS(obj) {
  if (typeof obj !== 'object' || obj === null) {
    if (typeof obj === 'string') {
      // Utiliser validator.escape avec validation supplémentaire
      return validator.escape(obj).substring(0, 5000); // Limiter la longueur pour éviter les attaques par déni de service
    }
    return obj;
  }

  const sanitizedObj = Array.isArray(obj) ? [] : {};
  
  Object.keys(obj).forEach(key => {
    // Nettoyer la clé pour éviter les injections dans les noms de propriétés
    const sanitizedKey = validator.escape(String(key));
    
    if (typeof obj[key] === 'string') {
      // Limiter la longueur des chaînes pour éviter les attaques par déni de service
      sanitizedObj[sanitizedKey] = validator.escape(obj[key]).substring(0, 5000);
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      // Récursion pour les objets imbriqués
      sanitizedObj[sanitizedKey] = sanitizeObjectXSS(obj[key]);
    } else {
      // Conserver les valeurs non string telles quelles
      sanitizedObj[sanitizedKey] = obj[key];
    }
  });

  return sanitizedObj;
}

// Protection contre la pollution du prototype (HPP)
const hppProtection = hpp({
  whitelist: [], // Tableau vide signifie que tous les champs sont autorisés à moins qu'ils soient dans la liste noire
  blacklist: ['constructor', 'prototype', '__proto__'] // Champs bloqués
});

// Configuration CORS sécurisée
const corsOptions = {
  origin: function (origin, callback) {
    // En production, restreindre strictement les origines
    if (process.env.NODE_ENV === 'production') {
      const allowedOrigins = [
        process.env.FRONTEND_URL || 'https://proxi-services.com',
        'https://cideg-dev.github.io',
      ];

      // Autoriser les requêtes sans origine (ex: mobile apps ou requêtes curl)
      if (!origin) return callback(null, true);

      // Vérifier si l'origine est dans la liste blanche
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        const msg = 'La politique CORS de ce site n\'autorise pas l\'accès depuis l\'origine spécifiée';
        callback(new Error(msg), false);
      }
    } else {
      // En développement, permettre les origines localhost
      const allowedOrigins = [
        process.env.FRONTEND_URL || 'http://localhost:5173',
        'https://cideg-dev.github.io',
        'http://localhost:3000'
      ];

      // Autoriser les requêtes sans origine (ex: mobile apps ou requêtes curl)
      if (!origin) return callback(null, true);

      // Vérifier si l'origine est dans la liste blanche
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        // En développement, autoriser les origines localhost
        if (origin && origin.startsWith('http://localhost:')) {
          return callback(null, true);
        }
        const msg = 'La politique CORS de ce site n\'autorise pas l\'accès depuis l\'origine spécifiée';
        callback(new Error(msg), false);
      }
    }
  },
  credentials: true, // Autoriser les cookies et autres credentials
  optionsSuccessStatus: 200, // Répondre avec 200 pour les requêtes OPTIONS
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], // Méthodes HTTP autorisées
  allowedHeaders: [
    'Origin', 'X-Requested-With', 'Content-Type', 'Accept', 
    'Authorization', 'X-HTTP-Method-Override'
  ], // En-têtes autorisés
  maxAge: 86400 // Délai de mise en cache des résultats CORS (24h)
};

module.exports = {
  limiter,
  helmetConfig,
  sanitize,
  xssProtection,
  hppProtection,
  cors: cors(corsOptions)
};