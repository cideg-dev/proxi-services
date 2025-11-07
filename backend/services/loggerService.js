const fs = require('fs');
const path = require('path');

// Journaliser les événements dans un fichier séparé
const logFilePath = path.join(__dirname, '../logs/app.log');

// Assurer que le répertoire de logs existe
const logsDir = path.dirname(logFilePath);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const logLevels = {
  ERROR: 'ERROR',
  WARN: 'WARN',
  INFO: 'INFO',
  DEBUG: 'DEBUG'
};

const log = (level, message, meta = {}) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    meta
  };

  // Écriture dans le fichier de log
  fs.appendFileSync(logFilePath, JSON.stringify(logEntry) + '\n', 'utf8');
  
  // En mode développement, afficher aussi dans la console
  if (process.env.NODE_ENV === 'development') {
    console.log(`${timestamp} [${level}] ${message}`, meta);
  }
};

const logger = {
  error: (message, meta = {}) => log(logLevels.ERROR, message, meta),
  warn: (message, meta = {}) => log(logLevels.WARN, message, meta),
  info: (message, meta = {}) => log(logLevels.INFO, message, meta),
  debug: (message, meta = {}) => log(logLevels.DEBUG, message, meta)
};

module.exports = logger;