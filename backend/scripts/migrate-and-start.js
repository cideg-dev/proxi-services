#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Exécuter les migrations PostgreSQL avant de démarrer le serveur
console.log('Exécution des migrations PostgreSQL...');

// Chemin vers node-pg-migrate
const migratePath = path.join(__dirname, '../node_modules/.bin/node-pg-migrate');

// Déterminer le script correct selon le système d'exploitation
const isWindows = process.platform === 'win32';
const migrateCommand = isWindows ? `${migratePath}.cmd` : migratePath;

const migrate = spawn(migrateCommand, ['up'], {
  stdio: 'inherit',
  shell: isWindows, // Utiliser le shell sur Windows pour exécuter les fichiers .cmd
  env: { ...process.env }
});

migrate.on('close', (code) => {
  if (code === 0) {
    console.log('Migrations terminées avec succès. Démarrage du serveur...');
    
    // Démarrer le serveur après les migrations
    const server = spawn('node', ['server.js'], {
      stdio: 'inherit',
      cwd: path.join(__dirname, '..')
    });

    server.on('close', (code) => {
      console.log(`Le serveur s'est arrêté avec le code: ${code}`);
      process.exit(code);
    });

    // Gérer le cas où le processus est interrompu
    process.on('SIGINT', () => {
      server.kill('SIGINT');
      process.exit();
    });

    process.on('SIGTERM', () => {
      server.kill('SIGTERM');
      process.exit();
    });
  } else {
    console.error(`Les migrations ont échoué avec le code: ${code}`);
    process.exit(code);
  }
});

migrate.on('error', (err) => {
  console.error('Erreur lors de l\'exécution des migrations:', err.message);
  process.exit(1);
});