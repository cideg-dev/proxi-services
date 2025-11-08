// Utilitaire pour la journalisation des événements

const fs = require('fs');
const path = require('path');

const logStream = fs.createWriteStream(path.join(__dirname, '../../request_log.txt'), { flags: 'a' });

const logger = {
  info: (message) => {
    const log = `${new Date().toISOString()} - ${message}`;
    console.log(log);
    logStream.write(log + '\n');
  },
  error: (message) => {
    const log = `${new Date().toISOString()} - ERROR - ${message}`;
    console.error(log);
    logStream.write(log + '\n');
  },
  warn: (message) => {
    const log = `${new Date().toISOString()} - WARN - ${message}`;
    console.warn(log);
    logStream.write(log + '\n');
  }
};

module.exports = logger;