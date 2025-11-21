-- Migration étape 1 : Vérification et création de la colonne user_id_uuid dans users si elle n'existe pas
DO $$
BEGIN
  -- Vérifier si la colonne user_id_uuid existe dans la table users
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'user_id_uuid') THEN
    -- Ajouter la colonne temporaire user_id_uuid
    ALTER TABLE users ADD COLUMN user_id_uuid UUID;
    
    -- Générer des UUID pour les utilisateurs existants (si la colonne id est de type integer)
    UPDATE users SET user_id_uuid = gen_random_uuid() WHERE user_id_uuid IS NULL;
    
    RAISE NOTICE 'Colonne user_id_uuid ajoutée à la table users';
  ELSE
    RAISE NOTICE 'Colonne user_id_uuid déjà existante dans la table users';
  END IF;
END $$;

-- Migration étape 2 : Mise à jour des tables de profils
DO $$
BEGIN
  -- artisan_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'artisan_profiles' AND column_name = 'user_id_uuid') THEN
    ALTER TABLE artisan_profiles ADD COLUMN user_id_uuid UUID;
    UPDATE artisan_profiles 
    SET user_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = artisan_profiles.user_id
    );
    RAISE NOTICE 'Colonne user_id_uuid ajoutée à artisan_profiles';
  ELSE
    RAISE NOTICE 'Colonne user_id_uuid déjà existante dans artisan_profiles';
  END IF;
  
  -- client_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_profiles' AND column_name = 'user_id_uuid') THEN
    ALTER TABLE client_profiles ADD COLUMN user_id_uuid UUID;
    UPDATE client_profiles 
    SET user_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = client_profiles.user_id
    );
    RAISE NOTICE 'Colonne user_id_uuid ajoutée à client_profiles';
  ELSE
    RAISE NOTICE 'Colonne user_id_uuid déjà existante dans client_profiles';
  END IF;
  
  -- commercant_profiles
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'commercant_profiles' AND column_name = 'user_id_uuid') THEN
    ALTER TABLE commercant_profiles ADD COLUMN user_id_uuid UUID;
    UPDATE commercant_profiles 
    SET user_id_uuid = (
      SELECT user_id_uuid 
      FROM users 
      WHERE users.id = commercant_profiles.user_id
    );
    RAISE NOTICE 'Colonne user_id_uuid ajoutée à commercant_profiles';
  ELSE
    RAISE NOTICE 'Colonne user_id_uuid déjà existante dans commercant_profiles';
  END IF;
END $$;