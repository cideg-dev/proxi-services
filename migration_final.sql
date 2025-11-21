-- Migration étape finale (complètement corrigée) : Conversion complète vers UUID

-- Désactiver temporairement les politiques RLS pendant la migration
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Artisans can manage own profile" ON artisan_profiles;
DROP POLICY IF EXISTS "Clients can manage own profile" ON client_profiles;
DROP POLICY IF EXISTS "Commercants can manage own profile" ON commercant_profiles;
DROP POLICY IF EXISTS "Everyone can read reviews" ON reviews;
DROP POLICY IF EXISTS "Clients can create own reviews" ON reviews;
DROP POLICY IF EXISTS "Clients can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can read own messages" ON messages;
DROP POLICY IF EXISTS "Users can send own messages" ON messages;
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
DROP POLICY IF EXISTS "Users can manage own demands" ON demandes;
DROP POLICY IF EXISTS "Users can read all portfolios" ON portfolio_items;
DROP POLICY IF EXISTS "Artisans can manage own portfolio" ON portfolio_items;
DROP POLICY IF EXISTS "Users can read all services" ON services;
DROP POLICY IF EXISTS "Artisans can manage own services" ON services;

-- Supprimer TOUTES les clés étrangères qui pointent vers la table users
ALTER TABLE artisan_profiles DROP CONSTRAINT IF EXISTS artisan_profiles_user_id_fkey CASCADE;
ALTER TABLE client_profiles DROP CONSTRAINT IF EXISTS client_profiles_user_id_fkey CASCADE;
ALTER TABLE commercant_profiles DROP CONSTRAINT IF EXISTS commercant_profiles_user_id_fkey CASCADE;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_client_id_fkey CASCADE;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_artisan_id_fkey CASCADE;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey CASCADE;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey CASCADE;
ALTER TABLE demandes DROP CONSTRAINT IF EXISTS demandes_client_id_fkey CASCADE;
ALTER TABLE demandes DROP CONSTRAINT IF EXISTS demandes_artisan_id_fkey CASCADE;
ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_user_id_fkey CASCADE;
ALTER TABLE favorites DROP CONSTRAINT IF EXISTS favorites_favorite_artisan_id_fkey CASCADE;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey CASCADE;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_reported_user_id_fkey CASCADE;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_resolved_by_admin_id_fkey CASCADE;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey CASCADE;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_user_id_fkey CASCADE;
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_user_id_fkey CASCADE;
ALTER TABLE portfolio_items DROP CONSTRAINT IF EXISTS portfolio_items_artisan_id_fkey CASCADE;
ALTER TABLE services DROP CONSTRAINT IF EXISTS services_artisan_id_fkey CASCADE;

-- Supprimer la clé primaire de la table users
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey CASCADE;

-- Supprimer les colonnes existantes dans les tables qui doivent être converties
-- En utilisant CASCADE pour supprimer également les dépendances
ALTER TABLE users DROP COLUMN IF EXISTS id CASCADE;
ALTER TABLE artisan_profiles DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE client_profiles DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE commercant_profiles DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE reviews DROP COLUMN IF EXISTS client_id, DROP COLUMN IF EXISTS artisan_id CASCADE;
ALTER TABLE messages DROP COLUMN IF EXISTS sender_id, DROP COLUMN IF EXISTS receiver_id CASCADE;
ALTER TABLE demandes DROP COLUMN IF EXISTS client_id, DROP COLUMN IF EXISTS artisan_id CASCADE;
ALTER TABLE favorites DROP COLUMN IF EXISTS user_id, DROP COLUMN IF EXISTS favorite_artisan_id CASCADE;
ALTER TABLE reports DROP COLUMN IF EXISTS reporter_id, DROP COLUMN IF EXISTS reported_user_id, DROP COLUMN IF EXISTS resolved_by_admin_id CASCADE;
ALTER TABLE audit_logs DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE payments DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE subscriptions DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE portfolio_items DROP COLUMN IF EXISTS artisan_id CASCADE;
ALTER TABLE services DROP COLUMN IF EXISTS artisan_id CASCADE;

-- Renommer les colonnes temporaires pour qu'elles deviennent les nouvelles colonnes
ALTER TABLE users RENAME COLUMN user_id_uuid TO id;
ALTER TABLE artisan_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE client_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE commercant_profiles RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE reviews RENAME COLUMN client_id_uuid TO client_id;
ALTER TABLE reviews RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE messages RENAME COLUMN sender_id_uuid TO sender_id;
ALTER TABLE messages RENAME COLUMN receiver_id_uuid TO receiver_id;
ALTER TABLE demandes RENAME COLUMN client_id_uuid TO client_id;
ALTER TABLE demandes RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE favorites RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE favorites RENAME COLUMN favorite_artisan_id_uuid TO favorite_artisan_id;
ALTER TABLE reports RENAME COLUMN reporter_id_uuid TO reporter_id;
ALTER TABLE reports RENAME COLUMN reported_user_id_uuid TO reported_user_id;
ALTER TABLE reports RENAME COLUMN resolved_by_admin_id_uuid TO resolved_by_admin_id;
ALTER TABLE audit_logs RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE payments RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE subscriptions RENAME COLUMN user_id_uuid TO user_id;
ALTER TABLE portfolio_items RENAME COLUMN artisan_id_uuid TO artisan_id;
ALTER TABLE services RENAME COLUMN artisan_id_uuid TO artisan_id;

-- Définir la nouvelle colonne comme clé primaire
ALTER TABLE users ADD PRIMARY KEY (id);

-- Réactiver les contraintes de clé étrangère
-- artisan_profiles
ALTER TABLE artisan_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- client_profiles
ALTER TABLE client_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- commercant_profiles
ALTER TABLE commercant_profiles ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- reviews
ALTER TABLE reviews ADD FOREIGN KEY (client_id) REFERENCES users(id);
ALTER TABLE reviews ADD FOREIGN KEY (artisan_id) REFERENCES users(id);

-- messages
ALTER TABLE messages ADD FOREIGN KEY (sender_id) REFERENCES users(id);
ALTER TABLE messages ADD FOREIGN KEY (receiver_id) REFERENCES users(id);

-- demandes
ALTER TABLE demandes ADD FOREIGN KEY (client_id) REFERENCES users(id);
ALTER TABLE demandes ADD FOREIGN KEY (artisan_id) REFERENCES users(id);

-- favorites
ALTER TABLE favorites ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE favorites ADD FOREIGN KEY (favorite_artisan_id) REFERENCES users(id);

-- reports
ALTER TABLE reports ADD FOREIGN KEY (reporter_id) REFERENCES users(id);
ALTER TABLE reports ADD FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE reports ADD FOREIGN KEY (resolved_by_admin_id) REFERENCES users(id) ON DELETE SET NULL;

-- audit_logs
ALTER TABLE audit_logs ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- payments
ALTER TABLE payments ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- subscriptions
ALTER TABLE subscriptions ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- portfolio_items
ALTER TABLE portfolio_items ADD FOREIGN KEY (artisan_id) REFERENCES users(id) ON DELETE CASCADE;

-- services
ALTER TABLE services ADD FOREIGN KEY (artisan_id) REFERENCES users(id) ON DELETE CASCADE;

-- Réactiver les politiques RLS avec la nouvelle structure
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Artisans can manage own profile" ON artisan_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Clients can manage own profile" ON client_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Commercants can manage own profile" ON commercant_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Everyone can read reviews" ON reviews
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Clients can create own reviews" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients can update own reviews" ON reviews
  FOR UPDATE TO authenticated
  USING (client_id = auth.uid());

CREATE POLICY "Users can read own messages" ON messages
  FOR SELECT TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Users can send own messages" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update own messages" ON messages
  FOR UPDATE TO authenticated
  USING (sender_id = auth.uid());

CREATE POLICY "Users can manage own demands" ON demandes
  FOR ALL TO authenticated
  USING (client_id = auth.uid() OR artisan_id = auth.uid());

CREATE POLICY "Users can read all portfolios" ON portfolio_items
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own portfolio" ON portfolio_items
  FOR ALL TO authenticated
  USING (artisan_id = auth.uid());

CREATE POLICY "Users can read all services" ON services
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own services" ON services
  FOR ALL TO authenticated
  USING (artisan_id = auth.uid());