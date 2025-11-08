// Migration pour remplacer la colonne refresh_token dans la table users par une table séparée

exports.up = (pgm) => {
  // Création de la table refresh_tokens
  pgm.createTable('refresh_tokens', {
    id: { type: ' SERIAL', primaryKey: true },
    user_id: { type: ' INTEGER', notNull: true, references: 'users(id)', onDelete: 'cascade' },
    token: { type: ' VARCHAR(128)', notNull: true, unique: true },
    expires_at: { type: ' TIMESTAMP', notNull: true, default: pgm.func('NOW() + INTERVAL \'7 days\'') },
    created_at: { type: ' TIMESTAMP', notNull: true, default: pgm.func('NOW()') }
  });

  // Création d'un index sur le token pour des recherches rapides
  pgm.createIndex('refresh_tokens', 'token');
  
  // Création d'un index sur expires_at pour le nettoyage efficace
  pgm.createIndex('refresh_tokens', 'expires_at');
  
  // Suppression de la colonne refresh_token de la table users
  pgm.dropColumn('users', 'refresh_token');
};

exports.down = (pgm) => {
  // Restauration de la colonne refresh_token dans la table users
  pgm.addColumn('users', {
    refresh_token: { type: 'text' }
  });
  
  // Suppression de la table refresh_tokens
  pgm.dropTable('refresh_tokens');
};