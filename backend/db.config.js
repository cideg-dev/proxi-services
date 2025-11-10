const { Pool } = require('pg');
require('dotenv').config();

// Validation des variables d'environnement critiques
const requiredEnvVars = ['DATABASE_URL', 'DB_USER', 'DB_HOST', 'DB_NAME', 'DB_PASSWORD', 'DB_PORT'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.error(`Variables d'environnement manquantes: ${missingEnvVars.join(', ')}`);
  process.exit(1);
}

let config;

// Render and other platforms use a single DATABASE_URL.
// This is the preferred way for production.
if (process.env.DATABASE_URL) {
  config = {
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false, // Required for Render connections
      // Désactiver SSL en développement si nécessaire
      ...(process.env.NODE_ENV === 'production' && { 
        require: true,
        rejectUnauthorized: false
      })
    },
    // Configuration de sécurité supplémentaire
    max: 20, // nombre maximum de clients dans le pool
    min: 5,  // nombre minimum de clients dans le pool
    idleTimeoutMillis: 30000, // fermer les clients inactifs après 30 secondes
    connectionTimeoutMillis: 2000, // timeout après 2 secondes
  };
} else {
  // Fallback for local development using separate variables
  config = {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: parseInt(process.env.DB_PORT) || 5432,
    // Configuration de sécurité supplémentaire
    max: 20, // nombre maximum de clients dans le pool
    min: 5,  // nombre minimum de clients dans le pool
    idleTimeoutMillis: 30000, // fermer les clients inactifs après 30 secondes
    connectionTimeoutMillis: 2000, // timeout après 2 secondes
    ssl: process.env.NODE_ENV === 'production' ? {
      require: true,
      rejectUnauthorized: false
    } : false
  };
}

// Créer le pool de connexions
const pool = new Pool(config);

// Gestion des erreurs de connexion
pool.on('error', (err) => {
  console.error('Erreur inattendue du pool PostgreSQL :', err);
  // Redémarrer le pool en cas d'erreur critique
  process.exit(-1);
});

module.exports = pool;