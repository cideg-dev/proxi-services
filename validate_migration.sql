-- Script de validation de la migration
-- Ce script vérifie que la migration est prête à passer à l'étape finale

-- Vérification des colonnes UUID temporaires dans chaque table
DO $$
DECLARE
  missing_columns TEXT := '';
BEGIN
  -- Vérifier que la colonne user_id_uuid existe dans users
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'user_id_uuid') THEN
    missing_columns := missing_columns || 'users.user_id_uuid, ';
  END IF;
  
  -- Vérifier que la colonne user_id_uuid existe dans artisan_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'artisan_profiles' AND column_name = 'user_id_uuid') THEN
    missing_columns := missing_columns || 'artisan_profiles.user_id_uuid, ';
  END IF;
  
  -- Vérifier que la colonne user_id_uuid existe dans client_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_profiles' AND column_name = 'user_id_uuid') THEN
    missing_columns := missing_columns || 'client_profiles.user_id_uuid, ';
  END IF;
  
  -- Vérifier que la colonne user_id_uuid existe dans commercant_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'commercant_profiles' AND column_name = 'user_id_uuid') THEN
    missing_columns := missing_columns || 'commercant_profiles.user_id_uuid, ';
  END IF;
  
  -- Vérifier que les colonnes UUID existent dans reviews
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'client_id_uuid') THEN
    missing_columns := missing_columns || 'reviews.client_id_uuid, ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'artisan_id_uuid') THEN
    missing_columns := missing_columns || 'reviews.artisan_id_uuid, ';
  END IF;
  
  -- Vérifier que les colonnes UUID existent dans messages
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_id_uuid') THEN
    missing_columns := missing_columns || 'messages.sender_id_uuid, ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_id_uuid') THEN
    missing_columns := missing_columns || 'messages.receiver_id_uuid, ';
  END IF;
  
  -- Vérifier que les colonnes UUID existent dans demandes
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'demandes' AND column_name = 'client_id_uuid') THEN
    missing_columns := missing_columns || 'demandes.client_id_uuid, ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'demandes' AND column_name = 'artisan_id_uuid') THEN
    missing_columns := missing_columns || 'demandes.artisan_id_uuid, ';
  END IF;

  -- Si des colonnes sont manquantes, signaler l'erreur
  IF LENGTH(missing_columns) > 0 THEN
    RAISE EXCEPTION 'Colonnes manquantes dans la migration: %', LEFT(missing_columns, LENGTH(missing_columns)-2);
  ELSE
    RAISE NOTICE '✅ Toutes les colonnes UUID temporaires sont présentes';
    RAISE NOTICE 'La migration est prête à passer à l''étape finale';
  END IF;
END $$;