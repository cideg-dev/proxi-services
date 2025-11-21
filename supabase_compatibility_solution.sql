-- Solution de contournement : Table de correspondance UUID-INTEGER pour Supabase
-- Cette approche conserve votre schéma actuel tout en permettant l'intégration Supabase

-- 1. Créer une table de correspondance entre UUID Supabase et IDs INTEGER
CREATE TABLE IF NOT EXISTS user_id_mapping (
  supabase_user_id UUID PRIMARY KEY,
  app_user_id INTEGER UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Créer un index pour de meilleures performances
CREATE INDEX IF NOT EXISTS idx_user_id_mapping_app_user_id ON user_id_mapping(app_user_id);

-- 3. Créer une fonction pour obtenir l'ID de l'application à partir de l'UUID Supabase
CREATE OR REPLACE FUNCTION get_app_user_id(supabase_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  app_id INTEGER;
BEGIN
  SELECT app_user_id INTO app_id
  FROM user_id_mapping
  WHERE supabase_user_id = supabase_uuid;
  
  RETURN app_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Créer une fonction pour obtenir l'UUID Supabase à partir de l'ID de l'application
CREATE OR REPLACE FUNCTION get_supabase_user_id(app_id INTEGER)
RETURNS UUID AS $$
DECLARE
  supabase_uuid UUID;
BEGIN
  SELECT supabase_user_id INTO supabase_uuid
  FROM user_id_mapping
  WHERE app_user_id = app_id;
  
  RETURN supabase_uuid;
END;
$$ LANGUAGE plpgsql;

-- 5. Mettre à jour les politiques RLS pour utiliser la table de correspondance
-- Politiques d'accès pour la table users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (id = get_app_user_id(auth.uid()));

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated
  USING (id = get_app_user_id(auth.uid()));

-- Politiques pour artisan_profiles
DROP POLICY IF EXISTS "Artisans can manage own profile" ON artisan_profiles;
CREATE POLICY "Artisans can manage own profile" ON artisan_profiles
  FOR ALL TO authenticated
  USING (user_id = get_app_user_id(auth.uid()))
  WITH CHECK (user_id = get_app_user_id(auth.uid()));

-- Politiques pour client_profiles
DROP POLICY IF EXISTS "Clients can manage own profile" ON client_profiles;
CREATE POLICY "Clients can manage own profile" ON client_profiles
  FOR ALL TO authenticated
  USING (user_id = get_app_user_id(auth.uid()))
  WITH CHECK (user_id = get_app_user_id(auth.uid()));

-- Politiques pour commercant_profiles
DROP POLICY IF EXISTS "Commercants can manage own profile" ON commercant_profiles;
CREATE POLICY "Commercants can manage own profile" ON commercant_profiles
  FOR ALL TO authenticated
  USING (user_id = get_app_user_id(auth.uid()))
  WITH CHECK (user_id = get_app_user_id(auth.uid()));

-- Politiques pour reviews
DROP POLICY IF EXISTS "Everyone can read reviews" ON reviews;
CREATE POLICY "Everyone can read reviews" ON reviews
  FOR SELECT TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Clients can create own reviews" ON reviews;
CREATE POLICY "Clients can create own reviews" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (client_id = get_app_user_id(auth.uid()));

DROP POLICY IF EXISTS "Clients can update own reviews" ON reviews;
CREATE POLICY "Clients can update own reviews" ON reviews
  FOR UPDATE TO authenticated
  USING (client_id = get_app_user_id(auth.uid()));

-- Politiques pour messages
DROP POLICY IF EXISTS "Users can read own messages" ON messages;
CREATE POLICY "Users can read own messages" ON messages
  FOR SELECT TO authenticated
  USING (sender_id = get_app_user_id(auth.uid()) OR receiver_id = get_app_user_id(auth.uid()));

DROP POLICY IF EXISTS "Users can send own messages" ON messages;
CREATE POLICY "Users can send own messages" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (sender_id = get_app_user_id(auth.uid()));

DROP POLICY IF EXISTS "Users can update own messages" ON messages;
CREATE POLICY "Users can update own messages" ON messages
  FOR UPDATE TO authenticated
  USING (sender_id = get_app_user_id(auth.uid()));

-- Politiques pour demandes
DROP POLICY IF EXISTS "Users can manage own demands" ON demandes;
CREATE POLICY "Users can manage own demands" ON demandes
  FOR ALL TO authenticated
  USING (client_id = get_app_user_id(auth.uid()) OR artisan_id = get_app_user_id(auth.uid()));

-- Politiques pour portfolios
DROP POLICY IF EXISTS "Users can read all portfolios" ON portfolio_items;
CREATE POLICY "Users can read all portfolios" ON portfolio_items
  FOR SELECT TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Artisans can manage own portfolio" ON portfolio_items;
CREATE POLICY "Artisans can manage own portfolio" ON portfolio_items
  FOR ALL TO authenticated
  USING (artisan_id = get_app_user_id(auth.uid()));

-- Politiques pour services
DROP POLICY IF EXISTS "Users can read all services" ON services;
CREATE POLICY "Users can read all services" ON services
  FOR SELECT TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS "Artisans can manage own services" ON services;
CREATE POLICY "Artisans can manage own services" ON services
  FOR ALL TO authenticated
  USING (artisan_id = get_app_user_id(auth.uid()));

-- Maintenant, vous devez peupler la table de correspondance avec vos utilisateurs existants
-- Cela devrait être fait en tant qu'étape d'initialisation une fois que vous aurez migré vos utilisateurs vers l'auth Supabase