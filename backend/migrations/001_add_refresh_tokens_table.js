// Migration pour ajouter la table des refresh tokens

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
};

exports.down = (pgm) => {
  pgm.dropTable('refresh_tokens');
};