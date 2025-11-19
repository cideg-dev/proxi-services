#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Exécuter les migrations PostgreSQL si la base de données est accessible
console.log('Vérification de la disponibilité de la base de données...');

// Lancer le script de migration conditionnelle
const migrateIfDbAvailable = spawn('node', ['../migrate-if-db-available.js'], {
  stdio: 'inherit',
  cwd: __dirname
});

migrateIfDbAvailable.on('close', (code) => {
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

migrateIfDbAvailable.on('error', (err) => {
  console.error('Erreur lors de l\'exécution des migrations:', err.message);
  process.exit(1);
});