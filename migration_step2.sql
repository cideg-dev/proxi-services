-- Migration étape 2 : Mise à jour des autres tables avec colonnes UUID temporaires
DO $$
BEGIN
  -- reviews
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'client_id_uuid') THEN
    ALTER TABLE reviews ADD COLUMN client_id_uuid UUID;
    UPDATE reviews 
    SET client_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = reviews.client_id
    );
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'artisan_id_uuid') THEN
    ALTER TABLE reviews ADD COLUMN artisan_id_uuid UUID;
    UPDATE reviews 
    SET artisan_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = reviews.artisan_id
    );
  END IF;
  
  RAISE NOTICE 'Colonnes UUID ajoutées à la table reviews';
  
  -- messages
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_id_uuid') THEN
    ALTER TABLE messages ADD COLUMN sender_id_uuid UUID;
    UPDATE messages 
    SET sender_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = messages.sender_id
    );
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_id_uuid') THEN
    ALTER TABLE messages ADD COLUMN receiver_id_uuid UUID;
    UPDATE messages 
    SET receiver_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = messages.receiver_id
    );
  END IF;
  
  RAISE NOTICE 'Colonnes UUID ajoutées à la table messages';
  
  -- demandes
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'demandes' AND column_name = 'client_id_uuid') THEN
    ALTER TABLE demandes ADD COLUMN client_id_uuid UUID;
    UPDATE demandes 
    SET client_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = demandes.client_id
    );
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'demandes' AND column_name = 'artisan_id_uuid') THEN
    ALTER TABLE demandes ADD COLUMN artisan_id_uuid UUID;
    UPDATE demandes 
    SET artisan_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = demandes.artisan_id
    );
  END IF;
  
  RAISE NOTICE 'Colonnes UUID ajoutées à la table demandes';
  
  -- Ajouter d'autres tables selon le même modèle...
END $$;