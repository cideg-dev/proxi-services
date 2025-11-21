-- script_conversion_uuid.sql
-- Script pour convertir les colonnes ID en UUID pour correspondre à l'authentification Supabase

-- 1. Ajouter une extension UUID si ce n'est pas déjà fait
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Ajouter une colonne temporaire user_id_uuid dans la table users
ALTER TABLE users ADD COLUMN user_id_uuid UUID;

-- 3. Générer des UUID pour les utilisateurs existants
UPDATE users SET user_id_uuid = uuid_generate_v4();

-- 4. Mettre à jour les tables de profils pour utiliser les nouveaux UUID
-- Sauvegarder les associations existantes
-- artisan_profiles
ALTER TABLE artisan_profiles ADD COLUMN user_id_uuid UUID;
UPDATE artisan_profiles 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = artisan_profiles.user_id
);

-- client_profiles
ALTER TABLE client_profiles ADD COLUMN user_id_uuid UUID;
UPDATE client_profiles 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = client_profiles.user_id
);

-- commercant_profiles
ALTER TABLE commercant_profiles ADD COLUMN user_id_uuid UUID;
UPDATE commercant_profiles 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = commercant_profiles.user_id
);

-- 5. Mettre à jour les autres tables qui référencent les utilisateurs
-- reviews
ALTER TABLE reviews ADD COLUMN client_id_uuid UUID, ADD COLUMN artisan_id_uuid UUID;
UPDATE reviews 
SET client_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = reviews.client_id
);
UPDATE reviews 
SET artisan_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = reviews.artisan_id
);

-- messages
ALTER TABLE messages ADD COLUMN sender_id_uuid UUID, ADD COLUMN receiver_id_uuid UUID;
UPDATE messages 
SET sender_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = messages.sender_id
);
UPDATE messages 
SET receiver_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = messages.receiver_id
);

-- demandes
ALTER TABLE demandes ADD COLUMN client_id_uuid UUID, ADD COLUMN artisan_id_uuid UUID;
UPDATE demandes 
SET client_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = demandes.client_id
);
UPDATE demandes 
SET artisan_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = demandes.artisan_id
);

-- favorites
ALTER TABLE favorites ADD COLUMN user_id_uuid UUID, ADD COLUMN favorite_artisan_id_uuid UUID;
UPDATE favorites 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = favorites.user_id
);
UPDATE favorites 
SET favorite_artisan_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = favorites.favorite_artisan_id
);

-- reports
ALTER TABLE reports ADD COLUMN reporter_id_uuid UUID, ADD COLUMN reported_user_id_uuid UUID;
UPDATE reports 
SET reporter_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = reports.reporter_id
);
UPDATE reports 
SET reported_user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = reports.reported_user_id
);

-- 6. Mettre à jour les autres tables si nécessaire
-- audit_logs
ALTER TABLE audit_logs ADD COLUMN user_id_uuid UUID;
UPDATE audit_logs 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = audit_logs.user_id
);

-- payments
ALTER TABLE payments ADD COLUMN user_id_uuid UUID;
UPDATE payments 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = payments.user_id
);

-- subscriptions
ALTER TABLE subscriptions ADD COLUMN user_id_uuid UUID;
UPDATE subscriptions 
SET user_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = subscriptions.user_id
);

-- portfolio_items
ALTER TABLE portfolio_items ADD COLUMN artisan_id_uuid UUID;
UPDATE portfolio_items 
SET artisan_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = portfolio_items.artisan_id
);

-- services
ALTER TABLE services ADD COLUMN artisan_id_uuid UUID;
UPDATE services 
SET artisan_id_uuid = (
    SELECT user_id_uuid 
    FROM users 
    WHERE users.id = services.artisan_id
);