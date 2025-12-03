-- Migration: Ajouter la table user_id_mapping et corriger les problèmes de schéma
-- Fichier: supabase/migrations/20251121100000_add_user_mapping_table.sql

-- Créer la table de correspondance des IDs si elle n'existe pas
CREATE TABLE IF NOT EXISTS user_id_mapping (
  supabase_user_id UUID NOT NULL,
  app_user_id INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_id_mapping_pkey PRIMARY KEY (supabase_user_id),
  CONSTRAINT user_id_mapping_app_user_id_fkey FOREIGN KEY (app_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Activer Row Level Security sur la table de correspondance
ALTER TABLE user_id_mapping ENABLE ROW LEVEL SECURITY;

-- Créer une politique RLS de base pour la table de correspondance
CREATE POLICY "Allow authenticated users to access user mapping" ON user_id_mapping
  FOR ALL TO authenticated
  USING (auth.uid() = supabase_user_id);