-- Script pour créer une vue artisans dans Supabase
-- Cette vue combine les données des tables users et artisan_profiles
-- pour fournir une interface semblable à une table artisans unique

-- Supprimer la vue si elle existe déjà
DROP VIEW IF EXISTS public.artisans_view;

-- Créer la vue artisans qui combine les données des artisans
CREATE VIEW public.artisans_view AS
SELECT 
    u.id,
    u.email,
    ap.nom_complet,
    ap.specialite,
    ap.description,
    ap.location,
    ap.telephone,
    ap.annees_experience,
    ap.siret,
    ap.site_web,
    ap.photo_url,
    ap.document_verification_url,
    ap.verification_status,
    ap.horaires_ouverture,
    ap.langues_parlees,
    ap.assurance_professionnelle
FROM 
    public.users u
JOIN 
    public.artisan_profiles ap ON u.id = ap.user_id
WHERE 
    u.role = 'artisan';

-- Activer Row Level Security (RLS) sur la vue si nécessaire
-- ALTER VIEW public.artisans_view ENABLE ROW LEVEL SECURITY;

-- Créer une politique RLS pour permettre aux utilisateurs de voir la vue
-- CREATE POLICY "Allow read access to artisans view" ON public.artisans_view
--   FOR SELECT TO authenticated, anon
--   USING (true);