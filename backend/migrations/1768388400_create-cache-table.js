// Migration pour créer une table de cache PostgreSQL qui remplace Redis
exports.shorthands = undefined;

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.up = (pgm) => {
  // Création de la table cache
  pgm.createTable('cache', {
    id: { type: 'SERIAL', primaryKey: true },
    key: { 
      type: 'VARCHAR(255)', 
      notNull: true, 
      unique: true 
    },
    value: { 
      type: 'TEXT', // Pour stocker des données JSON
      notNull: true 
    },
    expires_at: { 
      type: 'TIMESTAMP WITH TIME ZONE',
      notNull: true,
      default: pgm.func("NOW() + INTERVAL '1 hour'") // Durée d'expiration par défaut: 1 heure
    },
    created_at: { 
      type: 'TIMESTAMP WITH TIME ZONE', 
      notNull: true, 
      default: pgm.func('NOW()') 
    },
    updated_at: { 
      type: 'TIMESTAMP WITH TIME ZONE', 
      notNull: true, 
      default: pgm.func('NOW()') 
    },
  });

  // Création d'un index sur la clé pour des recherches rapides
  pgm.createIndex('cache', 'key');

  // Création d'un index sur expires_at pour le nettoyage automatique
  pgm.createIndex('cache', 'expires_at');
};

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.down = (pgm) => {
  // Suppression de la table cache
  pgm.dropTable('cache');
};