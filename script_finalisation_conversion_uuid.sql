-- script_finalisation_conversion_uuid.sql
-- Script pour finaliser la conversion vers les UUID

-- 7. Supprimer les contraintes de clé étrangère existantes
ALTER TABLE artisan_profiles DROP CONSTRAINT IF EXISTS artisan_profiles_user_id_fkey;
ALTER TABLE client_profiles DROP CONSTRAINT IF EXISTS client_profiles_user_id_fkey;
ALTER TABLE commercant_profiles DROP CONSTRAINT IF EXISTS commercant_profiles_user_id_fkey;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_client_id_fkey;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_artisan_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey;
ALTER TABLE demandes DROP CONSTRAINT IF EXISTS demandes_client_id_fkey;
ALTER TABLE demandes DROP CONSTRAINT IF EXISTS demandes_artisan_id_fkey;
ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_user_id_fkey;
ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_favorite_artisan_id_fkey;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_reported_user_id_fkey;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_user_id_fkey;
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_user_id_fkey;
ALTER TABLE portfolio_items DROP CONSTRAINT IF EXISTS portfolio_items_artisan_id_fkey;
ALTER TABLE services DROP CONSTRAINT IF EXISTS services_artisan_id_fkey;

-- 8. Supprimer les anciennes colonnes INTEGER
-- Table users
ALTER TABLE users DROP COLUMN id CASCADE;
ALTER TABLE users RENAME COLUMN user_id_uuid TO id;
ALTER TABLE users ADD PRIMARY KEY (id);

-- Table artisan_profiles
ALTER TABLE artisan_profiles DROP COLUMN user_id;
ALTER TABLE artisan_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE artisan_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Table client_profiles
ALTER TABLE client_profiles DROP COLUMN user_id;
ALTER TABLE client_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE client_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Table commercant_profiles
ALTER TABLE commercant_profiles DROP COLUMN user_id;
ALTER TABLE commercant_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE commercant_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Table reviews
ALTER TABLE reviews DROP COLUMN client_id, DROP COLUMN artisan_id;
ALTER TABLE reviews RENAME COLUMN client_id_uuid TO client_id;
ALTER TABLE reviews RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE reviews ADD FOREIGN KEY (client_id) REFERENCES users(id);
ALTER TABLE reviews ADD FOREIGN KEY (artisan_id) REFERENCES users(id);

-- Table messages
ALTER TABLE messages DROP COLUMN sender_id, DROP COLUMN receiver_id;
ALTER TABLE messages RENAME COLUMN sender_id_uuid TO sender_id;
ALTER TABLE messages RENAME COLUMN receiver_id_uuid TO receiver_id;
ALTER TABLE messages ADD FOREIGN KEY (sender_id) REFERENCES users(id);
ALTER TABLE messages ADD FOREIGN KEY (receiver_id) REFERENCES users(id);

-- Table demandes
ALTER TABLE demandes DROP COLUMN client_id, DROP COLUMN artisan_id;
ALTER TABLE demandes RENAME COLUMN client_id_uuid TO client_id;
ALTER TABLE demandes RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE demandes ADD FOREIGN KEY (client_id) REFERENCES users(id);
ALTER TABLE demandes ADD FOREIGN KEY (artisan_id) REFERENCES users(id);

-- Table favorites
ALTER TABLE favorites DROP COLUMN user_id, DROP COLUMN favorite_artisan_id;
ALTER TABLE favorites RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE favorites RENAME COLUMN favorite_artisan_id_uuid TO favorite_artisan_id;
ALTER TABLE favorites ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE favorites ADD FOREIGN KEY (favorite_artisan_id) REFERENCES users(id);

-- Table reports
ALTER TABLE reports DROP COLUMN reporter_id, DROP COLUMN reported_user_id;
ALTER TABLE reports RENAME COLUMN reporter_id_uuid TO reporter_id;
ALTER TABLE reports RENAME COLUMN reported_user_id_uuid TO reported_user_id;
ALTER TABLE reports ADD FOREIGN KEY (reporter_id) REFERENCES users(id);
ALTER TABLE reports ADD FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Table audit_logs
ALTER TABLE audit_logs DROP COLUMN user_id;
ALTER TABLE audit_logs RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE audit_logs ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Table payments
ALTER TABLE payments DROP COLUMN user_id;
ALTER TABLE payments RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE payments ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Table subscriptions
ALTER TABLE subscriptions DROP COLUMN user_id;
ALTER TABLE subscriptions RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE subscriptions ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Table portfolio_items
ALTER TABLE portfolio_items DROP COLUMN artisan_id;
ALTER TABLE portfolio_items RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE portfolio_items ADD FOREIGN KEY (artisan_id) REFERENCES users(id) ON DELETE CASCADE;

-- Table services
ALTER TABLE services DROP COLUMN artisan_id;
ALTER TABLE services RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE services ADD FOREIGN KEY (artisan_id) REFERENCES users(id) ON DELETE CASCADE;

-- 9. Mettre à jour la table users pour que id soit de type UUID avec une valeur par défaut
-- Si ce n'est pas déjà le cas
ALTER TABLE users ALTER COLUMN id SET DEFAULT uuid_generate_v4();