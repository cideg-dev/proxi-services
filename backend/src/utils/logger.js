const winston = require('winston');
require('winston-daily-rotate-file');
require('dotenv').config();

// Création d'un transport pour les fichiers de log quotidiens
const dailyRotateFileTransport = new winston.transports.DailyRotateFile({
  filename: 'logs/application-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  zippedArchive: true,
  maxSize: '20m',
  maxFiles: '14d',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  )
});

// Création d'un logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'proxi-services-api' },
  transports: [
    dailyRotateFileTransport,
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Fonction pour logger des événements d'audit
const logAuditAction = (userId, action, resource, details = {}) => {
  logger.info('AUDIT_EVENT', {
    userId,
    action,
    resource,
    details,
    timestamp: new Date().toISOString()
  });
};

// Fonction pour logger les erreurs de manière structurée
const logError = (error, req = null, context = {}) => {
  const errorLog = {
    message: error.message,
    stack: error.stack,
    context,
    timestamp: new Date().toISOString()
  };

  if (req) {
    // Créer un objet de requête sans les données sensibles
    const safeRequest = {
      method: req.method,
      url: req.url,
      headers: req.headers,
      params: req.params,
      query: req.query,
      ip: req.ip || req.connection.remoteAddress
    };
    
    // N'ajouter le body que s'il ne contient pas de données sensibles
    if (req.body) {
      const safeBody = {};
      for (const [key, value] of Object.entries(req.body)) {
        // Ne pas inclure les champs sensibles dans les logs
        if (!['password', 'currentPassword', 'newPassword', 'token', 'refreshToken', 'authorization'].includes(key.toLowerCase())) {
          safeBody[key] = value;
        } else {
          safeBody[key] = '[REDACTED]';
        }
      }
      safeRequest.body = safeBody;
    }
    
    errorLog.request = safeRequest;
  }

  logger.error('APPLICATION_ERROR', errorLog);
};

module.exports = {
  logger,
  logAuditAction,
  logError
};