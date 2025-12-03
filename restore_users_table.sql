-- Script pour restaurer la structure correcte de la base de données
-- Suppression de la table artisans incorrecte (si elle existe)
DROP TABLE IF EXISTS public.artisans;

-- Restauration de la table users avec la structure d'origine
CREATE TABLE IF NOT EXISTS public.users (
  id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  email character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  role character varying NOT NULL,
  is_blocked boolean DEFAULT false,
  mfa_enabled boolean DEFAULT false,
  mfa_secret character varying,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Si la table artisan_profiles n'existe plus, la recréer aussi
CREATE TABLE IF NOT EXISTS public.artisan_profiles (
  user_id integer NOT NULL,
  nom_complet character varying,
  sexe character varying,
  specialite character varying,
  description text,
  location character varying,
  telephone character varying,
  annees_experience integer,
  siret character varying,
  site_web character varying,
  photo_url character varying,
  document_verification_url character varying,
  verification_status character varying DEFAULT 'not_verified'::character varying,
  horaires_ouverture text,
  langues_parlees ARRAY,
  assurance_professionnelle boolean DEFAULT false,
  CONSTRAINT artisan_profiles_pkey PRIMARY KEY (user_id),
  CONSTRAINT artisan_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Activer RLS sur les tables si nécessaire
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artisan_profiles ENABLE ROW LEVEL SECURITY;

-- Créer des politiques RLS de base si nécessaire
CREATE POLICY "Allow registration" ON public.users
  FOR INSERT TO anon
  WITH CHECK (true);

CREATE POLICY "Allow read access to own user data" ON public.users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Allow update access to own user data" ON public.users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow artisans to manage own profile" ON public.artisan_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);