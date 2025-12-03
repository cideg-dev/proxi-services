-- Script corrigé pour supprimer un utilisateur spécifique et ses données associées
-- Prend en compte la correspondance entre UUID Supabase et ID applicatif

-- Supprimer les enregistrements liés à l'utilisateur problématique dans user_id_mapping
-- et récupérer le supabase_user_id pour la suppression dans l'auth
WITH user_to_delete AS (
  SELECT u.id as app_user_id, uim.supabase_user_id
  FROM public.users u
  JOIN public.user_id_mapping uim ON u.id = uim.app_user_id
  WHERE u.email = 'cideg.p.line@gmail.com'
)

-- Supprimer de toutes les tables liées à l'utilisateur
DELETE FROM public.artisan_profiles WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.client_profiles WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.commercant_profiles WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.audit_logs WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.demandes WHERE client_id IN (SELECT app_user_id FROM user_to_delete) 
  OR artisan_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.favorites WHERE user_id IN (SELECT app_user_id FROM user_to_delete) 
  OR favorite_artisan_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.messages WHERE sender_id IN (SELECT app_user_id FROM user_to_delete) 
  OR receiver_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.payments WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.portfolio_items WHERE artisan_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.reports WHERE 
  reporter_id IN (SELECT app_user_id FROM user_to_delete)
  OR reported_user_id IN (SELECT app_user_id FROM user_to_delete)
  OR resolved_by_admin_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.reviews WHERE 
  artisan_id IN (SELECT app_user_id FROM user_to_delete)
  OR client_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.services WHERE artisan_id IN (SELECT app_user_id FROM user_to_delete);

DELETE FROM public.subscriptions WHERE user_id IN (SELECT app_user_id FROM user_to_delete);

-- Supprimer de user_id_mapping
DELETE FROM public.user_id_mapping WHERE app_user_id IN (SELECT app_user_id FROM user_to_delete);

-- Supprimer de la table users
DELETE FROM public.users WHERE id IN (SELECT app_user_id FROM user_to_delete);