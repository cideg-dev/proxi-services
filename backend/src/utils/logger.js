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
    errorLog.request = {
      method: req.method,
      url: req.url,
      headers: req.headers,
      body: req.body,
      params: req.params,
      query: req.query,
      ip: req.ip || req.connection.remoteAddress
    };
  }
  
  logger.error('APPLICATION_ERROR', errorLog);
};

module.exports = {
  logger,
  logAuditAction,
  logError
};