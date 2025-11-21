-- supabase/rls_policies.sql
-- Activer RLS sur toutes les tables - Version corrigée pour UUID

-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE artisan_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE demandes ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Politiques d'accès pour la table users
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated
  USING (id = auth.uid());

-- Politiques pour artisan_profiles
CREATE POLICY "Artisans can manage own profile" ON artisan_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Politiques pour client_profiles
CREATE POLICY "Clients can manage own profile" ON client_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Politiques pour commercant_profiles
CREATE POLICY "Commercants can manage own profile" ON commercant_profiles
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Politiques pour reviews
CREATE POLICY "Everyone can read reviews" ON reviews
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Clients can create own reviews" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients can update own reviews" ON reviews
  FOR UPDATE TO authenticated
  USING (client_id = auth.uid());

-- Politiques pour messages
CREATE POLICY "Users can read own messages" ON messages
  FOR SELECT TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Users can send own messages" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update own messages" ON messages
  FOR UPDATE TO authenticated
  USING (sender_id = auth.uid());

-- Politiques pour demandes
CREATE POLICY "Users can manage own demands" ON demandes
  FOR ALL TO authenticated
  USING (client_id = auth.uid() OR artisan_id = auth.uid());

-- Politiques pour portfolios
CREATE POLICY "Users can read all portfolios" ON portfolio_items
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own portfolio" ON portfolio_items
  FOR ALL TO authenticated
  USING (artisan_id = auth.uid());

-- Politiques pour services
CREATE POLICY "Users can read all services" ON services
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own services" ON services
  FOR ALL TO authenticated
  USING (artisan_id = auth.uid());