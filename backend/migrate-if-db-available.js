const { spawn } = require('child_process');
const { Client } = require('pg');
require('dotenv').config();

// Fonction pour tester si la base de données est accessible
async function isDatabaseAccessible() {
  if (!process.env.DATABASE_URL) {
    console.log('DATABASE_URL non définie, migration ignorée');
    return false;
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL
  });

  try {
    await client.connect();
    await client.end();
    console.log('Base de données accessible, migration autorisée');
    return true;
  } catch (err) {
    console.log(`Base de données inaccessible: ${err.message}`);
    console.log('IGNORE_MIGRATIONS est défini, migration ignorée');
    return false;
  }
}

// Fonction pour exécuter la migration
function runMigration() {
  return new Promise((resolve, reject) => {
    console.log('Lancement de la migration...');
    
    const migrateProcess = spawn('npx', ['node-pg-migrate', 'up'], {
      stdio: 'inherit',
      cwd: __dirname
    });

    migrateProcess.on('close', (code) => {
      if (code === 0) {
        console.log('Migration terminée avec succès');
        resolve();
      } else {
        console.log(`Migration échouée avec le code ${code}`);
        reject(new Error(`Migration failed with code ${code}`));
      }
    });

    migrateProcess.on('error', (err) => {
      console.log(`Erreur lors de la migration: ${err.message}`);
      reject(err);
    });
  });
}

// Exécution principale
async function main() {
  // Vérifier si la variable d'environnement IGNORE_MIGRATIONS est définie
  if (process.env.IGNORE_MIGRATIONS) {
    console.log('IGNORE_MIGRATIONS est défini, migration ignorée');
    process.exit(0);
  }

  // Sinon, vérifier si la base de données est accessible
  if (await isDatabaseAccessible()) {
    try {
      await runMigration();
      process.exit(0);
    } catch (error) {
      console.log(`Échec de la migration: ${error.message}`);
      process.exit(1);
    }
  } else {
    // Si la base de données n'est pas accessible, ignorer la migration
    console.log('Migration ignorée car la base de données n\'est pas accessible');
    process.exit(0);
  }
}

main();