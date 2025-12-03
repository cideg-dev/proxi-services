-- Script pour supprimer un utilisateur spécifique et ses données associées
-- Remplacez 'cideg.p.line@gmail.com' par l'email de l'utilisateur à supprimer

-- Supprimer les enregistrements liés à l'utilisateur problématique
DELETE FROM public.user_id_mapping WHERE app_user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.artisan_profiles WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.client_profiles WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.commercant_profiles WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.audit_logs WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.demandes WHERE client_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
) OR artisan_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.favorites WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
) OR favorite_artisan_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.messages WHERE sender_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
) OR receiver_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.payments WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.portfolio_items WHERE artisan_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.reports WHERE 
  reporter_id IN (SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com')
  OR reported_user_id IN (SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com')
  OR resolved_by_admin_id IN (SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com');

DELETE FROM public.reviews WHERE 
  artisan_id IN (SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com')
  OR client_id IN (SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com');

DELETE FROM public.services WHERE artisan_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

DELETE FROM public.subscriptions WHERE user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

-- Supprimer l'utilisateur de la table users
DELETE FROM public.users WHERE email = 'cideg.p.line@gmail.com';