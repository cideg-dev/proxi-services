-- Script pour restaurer la structure correcte de la base de données Proxi-Services
-- Suppression des tables qui ne font pas partie du schéma original

-- Supprimer les tables qui ne sont pas dans le schéma original
-- (en supposant que vous avez créé des tables incorrectes)
-- DROP TABLE IF EXISTS public.artisans CASCADE; -- à décommenter si cette table existe et est incorrecte

-- Vérifier si la table users est correcte
-- Si elle est incomplète ou incorrecte, la supprimer et la recréer
-- DROP TABLE IF EXISTS public.users CASCADE; -- à décommenter si nécessaire

-- Recréer la table users avec la structure complète
CREATE TABLE IF NOT EXISTS public.users (
  id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  email character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  role character varying NOT NULL,
  is_blocked boolean DEFAULT false,
  mfa_enabled boolean DEFAULT false,
  mfa_secret character varying,
  last_seen timestamp without time zone,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Recréer la table artisan_profiles
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
  CONSTRAINT artisan_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Recréer la table client_profiles
CREATE TABLE IF NOT EXISTS public.client_profiles (
  user_id integer NOT NULL,
  nom_complet character varying,
  sexe character varying,
  location character varying,
  telephone character varying,
  photo_url character varying,
  adresse text,
  CONSTRAINT client_profiles_pkey PRIMARY KEY (user_id),
  CONSTRAINT client_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Recréer la table commercant_profiles
CREATE TABLE IF NOT EXISTS public.commercant_profiles (
  user_id integer NOT NULL,
  nom_entreprise character varying,
  sexe_contact character varying,
  type_commerce character varying,
  description text,
  adresse character varying,
  location character varying,
  telephone character varying,
  siret character varying,
  site_web character varying,
  horaires_ouverture character varying,
  photo_url character varying,
  document_verification_url character varying,
  verification_status character varying DEFAULT 'not_verified'::character varying,
  langues_parlees ARRAY,
  assurance_professionnelle boolean DEFAULT false,
  CONSTRAINT commercant_profiles_pkey PRIMARY KEY (user_id),
  CONSTRAINT commercant_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Activer Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artisan_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commercant_profiles ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS de base
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