-- Script pour restaurer la structure complète de la base de données
-- Suppression de la table artisans incorrecte (si elle existe)
DROP TABLE IF EXISTS public.artisans CASCADE;

-- Restauration de la table users avec la structure d'origine
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

-- Recréation des tables liées dans le bon ordre (sans contraintes pour l'instant)
-- pour éviter les problèmes de dépendances circulaires

-- Tables qui dépendent directement de users
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
  CONSTRAINT artisan_profiles_pkey PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS public.client_profiles (
  user_id integer NOT NULL,
  nom_complet character varying,
  sexe character varying,
  location character varying,
  telephone character varying,
  photo_url character varying,
  adresse text,
  CONSTRAINT client_profiles_pkey PRIMARY KEY (user_id)
);

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
  CONSTRAINT commercant_profiles_pkey PRIMARY KEY (user_id)
);

-- Table qui référence users
CREATE SEQUENCE IF NOT EXISTS public.audit_logs_id_seq;

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id integer NOT NULL DEFAULT nextval('audit_logs_id_seq'::regclass),
  user_id integer,
  action_type character varying NOT NULL,
  entity_type character varying,
  entity_id integer,
  details jsonb,
  timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id)
);

-- Table pour les demandes
CREATE SEQUENCE IF NOT EXISTS public.demandes_id_seq;

CREATE TABLE IF NOT EXISTS public.demandes (
  id integer NOT NULL DEFAULT nextval('demandes_id_seq'::regclass),
  client_id integer NOT NULL,
  artisan_id integer NOT NULL,
  service_ids ARRAY,
  service_description text,
  status character varying NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone,
  CONSTRAINT demandes_pkey PRIMARY KEY (id)
);

-- Table pour les favoris
CREATE TABLE IF NOT EXISTS public.favorites (
  user_id integer NOT NULL,
  favorite_artisan_id integer NOT NULL,
  CONSTRAINT favorites_pkey PRIMARY KEY (user_id, favorite_artisan_id)
);

-- Table pour les messages
CREATE SEQUENCE IF NOT EXISTS public.messages_id_seq;

CREATE TABLE IF NOT EXISTS public.messages (
  id integer NOT NULL DEFAULT nextval('messages_id_seq'::regclass),
  sender_id integer NOT NULL,
  receiver_id integer NOT NULL,
  content text NOT NULL,
  status character varying DEFAULT 'sent'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT messages_pkey PRIMARY KEY (id)
);

-- Table pour les paiements
CREATE SEQUENCE IF NOT EXISTS public.payments_id_seq;

CREATE TABLE IF NOT EXISTS public.payments (
  id integer NOT NULL DEFAULT nextval('payments_id_seq'::regclass),
  user_id integer,
  amount numeric NOT NULL,
  currency character varying NOT NULL DEFAULT 'XOF'::character varying,
  reason character varying,
  kkiapay_transaction_id character varying UNIQUE,
  status character varying NOT NULL DEFAULT 'pending'::character varying,
  payment_method character varying,
  transaction_details jsonb,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT payments_pkey PRIMARY KEY (id)
);

-- Table pour les portfolios
CREATE SEQUENCE IF NOT EXISTS public.portfolio_items_id_seq;

CREATE TABLE IF NOT EXISTS public.portfolio_items (
  id integer NOT NULL DEFAULT nextval('portfolio_items_id_seq'::regclass),
  artisan_id integer NOT NULL,
  image_url character varying NOT NULL,
  caption character varying,
  CONSTRAINT portfolio_items_pkey PRIMARY KEY (id)
);

-- Table pour les rapports
CREATE SEQUENCE IF NOT EXISTS public.reports_id_seq;

CREATE TABLE IF NOT EXISTS public.reports (
  id integer NOT NULL DEFAULT nextval('reports_id_seq'::regclass),
  reporter_id integer NOT NULL,
  reported_user_id integer,
  reported_message_id integer,
  reported_review_id integer,
  reported_portfolio_item_id integer,
  report_type character varying NOT NULL,
  reason text NOT NULL,
  status character varying DEFAULT 'pending'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  resolved_at timestamp with time zone,
  resolved_by_admin_id integer,
  CONSTRAINT reports_pkey PRIMARY KEY (id)
);

-- Table pour les avis
CREATE SEQUENCE IF NOT EXISTS public.reviews_id_seq;

CREATE TABLE IF NOT EXISTS public.reviews (
  id integer NOT NULL DEFAULT nextval('reviews_id_seq'::regclass),
  artisan_id integer NOT NULL,
  client_id integer NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reviews_pkey PRIMARY KEY (id)
);

-- Table pour les services
CREATE SEQUENCE IF NOT EXISTS public.services_id_seq;

CREATE TABLE IF NOT EXISTS public.services (
  id integer NOT NULL DEFAULT nextval('services_id_seq'::regclass),
  artisan_id integer NOT NULL,
  name character varying NOT NULL,
  description text,
  price character varying,
  CONSTRAINT services_pkey PRIMARY KEY (id)
);

-- Table pour les abonnements
CREATE SEQUENCE IF NOT EXISTS public.subscriptions_id_seq;

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id integer NOT NULL DEFAULT nextval('subscriptions_id_seq'::regclass),
  user_id integer NOT NULL,
  subscription_type character varying NOT NULL,
  start_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  end_date timestamp with time zone,
  status character varying NOT NULL DEFAULT 'active'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT subscriptions_pkey PRIMARY KEY (id)
);

-- Maintenant que toutes les tables sont créées, on ajoute les contraintes de clé étrangère
ALTER TABLE public.artisan_profiles ADD CONSTRAINT artisan_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.client_profiles ADD CONSTRAINT client_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.commercant_profiles ADD CONSTRAINT commercant_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.demandes ADD CONSTRAINT demandes_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.demandes ADD CONSTRAINT demandes_artisan_id_fkey FOREIGN KEY (artisan_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.favorites ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.favorites ADD CONSTRAINT favorites_favorite_artisan_id_fkey FOREIGN KEY (favorite_artisan_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.messages ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.messages ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.payments ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.portfolio_items ADD CONSTRAINT portfolio_items_artisan_id_fkey FOREIGN KEY (artisan_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_reported_message_id_fkey FOREIGN KEY (reported_message_id) REFERENCES public.messages(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_reported_review_id_fkey FOREIGN KEY (reported_review_id) REFERENCES public.reviews(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_reported_portfolio_item_id_fkey FOREIGN KEY (reported_portfolio_item_id) REFERENCES public.portfolio_items(id) ON DELETE CASCADE;
ALTER TABLE public.reports ADD CONSTRAINT reports_resolved_by_admin_id_fkey FOREIGN KEY (resolved_by_admin_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.reviews ADD CONSTRAINT reviews_artisan_id_fkey FOREIGN KEY (artisan_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.reviews ADD CONSTRAINT reviews_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD CONSTRAINT services_artisan_id_fkey FOREIGN KEY (artisan_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;