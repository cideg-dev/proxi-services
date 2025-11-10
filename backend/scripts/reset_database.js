const { Pool } = require('pg');
require('dotenv').config();

// Configuration du pool de connexions
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`,
});

async function resetDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('Démarrage de la réinitialisation de la base de données...');
    
    // Désactiver les contrôles de clé étrangère temporairement
    await client.query('SET session_replication_role = replica;');
    
    // Supprimer toutes les données des tables dans l'ordre approprié pour respecter les relations
    const tables = [
      'reports',
      'reviews',
      'portfolio_items',
      'services',
      'favorites',
      'demandes',
      'messages',
      'subscriptions',
      'payments',
      'audit_logs',
      'commercant_profiles',
      'artisan_profiles',
      'client_profiles',
      'users'
    ];
    
    for (const table of tables) {
      await client.query(`DELETE FROM ${table};`);
      console.log(`Données supprimées de la table: ${table}`);
    }
    
    // Réinitialiser les séquences d'ID
    await client.query(`
      DO $$ 
      DECLARE
        r RECORD;
      BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
        LOOP
          EXECUTE 'SELECT setval(pg_get_serial_sequence('''||r.tablename||''', ''id''), 1, false)';
        END LOOP;
      END
      $$;
    `);
    
    // Réactiver les contrôles de clé étrangère
    await client.query('SET session_replication_role = DEFAULT;');
    
    console.log('Toutes les tables ont été vidées avec succès. Les séquences ID ont été réinitialisées.');
  } catch (error) {
    console.error('Erreur lors de la réinitialisation de la base de données:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Exécuter la réinitialisation de la base de données
resetDatabase()
  .then(() => {
    console.log('La réinitialisation de la base de données est terminée.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Erreur lors de l\'exécution du script:', error);
    process.exit(1);
  });