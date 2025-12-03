-- Script pour créer une table artisans dans Supabase
-- Cette table pourrait être utilisée pour stocker les informations spécifiques aux artisans
-- en plus de la structure existante utilisant users et artisan_profiles

CREATE TABLE IF NOT EXISTS public.artisans (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  nom_complet VARCHAR,
  specialite VARCHAR,
  description TEXT,
  location VARCHAR,
  telephone VARCHAR,
  annees_experience INTEGER,
  siret VARCHAR,
  site_web VARCHAR,
  photo_url VARCHAR,
  document_verification_url VARCHAR,
  verification_status VARCHAR DEFAULT 'not_verified',
  horaires_ouverture TEXT,
  langues_parlees TEXT[],
  assurance_professionnelle BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT artisans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Créer un index sur user_id pour de meilleures performances
CREATE INDEX IF NOT EXISTS idx_artisans_user_id ON public.artisans(user_id);

-- Activer Row Level Security (RLS) si nécessaire
ALTER TABLE public.artisans ENABLE ROW LEVEL SECURITY;

-- Créer une politique RLS pour permettre aux utilisateurs de voir les artisans
CREATE POLICY "Allow read access to artisans" ON public.artisans
  FOR SELECT TO authenticated, anon
  USING (true);

-- Créer une politique RLS pour permettre aux propriétaires de modifier leurs données
CREATE POLICY "Allow individual artisans to update their own profile" ON public.artisans
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);