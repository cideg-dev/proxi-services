// Script de test pour vérifier la connexion à la base de données Supabase
require('dotenv').config();
const { testConnection } = require('./db.config');

async function runTest() {
  console.log('Tentative de connexion à la base de données Supabase...');
  
  try {
    const isConnected = await testConnection();
    if (isConnected) {
      console.log('✅ Connexion à Supabase réussie !');
    } else {
      console.log('❌ Échec de la connexion à Supabase');
    }
  } catch (error) {
    console.error('❌ Erreur lors de la connexion à Supabase:', error.message);
  }
}

runTest();