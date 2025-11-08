// Migration pour ajouter des index pour améliorer la performance

exports.up = (pgm) => {
  // Index sur la table users pour les recherches par email (utilisé fréquemment pour l'authentification)
  pgm.createIndex('users', 'email');
  
  // Index sur les tables de profils pour les recherches par user_id
  pgm.createIndex('client_profiles', 'user_id');
  pgm.createIndex('artisan_profiles', 'user_id');
  pgm.createIndex('commercant_profiles', 'user_id');
  
  // Index sur la table des messages pour les recherches par sender_id et receiver_id
  pgm.createIndex('messages', ['sender_id', 'receiver_id']);
  pgm.createIndex('messages', 'created_at'); // Pour le tri par date
  
  // Index sur la table des demandes pour les recherches par client_id et artisan_id
  pgm.createIndex('demandes', ['client_id', 'artisan_id']);
  pgm.createIndex('demandes', 'created_at');
  
  // Index sur la table des avis pour les recherches par artisan_id
  pgm.createIndex('avis', 'artisan_id');
  pgm.createIndex('avis', 'created_at');
  
  // Index sur la table des services pour les recherches par artisan_id
  pgm.createIndex('services', 'artisan_id');
};

exports.down = (pgm) => {
  // Suppression des index
  pgm.dropIndex('users', 'email');
  pgm.dropIndex('client_profiles', 'user_id');
  pgm.dropIndex('artisan_profiles', 'user_id');
  pgm.dropIndex('commercant_profiles', 'user_id');
  pgm.dropIndex('messages', ['sender_id', 'receiver_id']);
  pgm.dropIndex('messages', 'created_at');
  pgm.dropIndex('demandes', ['client_id', 'artisan_id']);
  pgm.dropIndex('demandes', 'created_at');
  pgm.dropIndex('avis', 'artisan_id');
  pgm.dropIndex('avis', 'created_at');
  pgm.dropIndex('services', 'artisan_id');
};