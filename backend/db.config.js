const { Pool } = require('pg');
require('dotenv').config();

let config;

// Render and other platforms use a single DATABASE_URL.
// This is the preferred way for production.
if (process.env.DATABASE_URL) {
  config = {
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false // Required for Render connections
    }
  };
} else {
  // Fallback for local development using separate variables
  config = {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  };
}

const pool = new Pool(config);

module.exports = pool;