-- Script simplifié pour supprimer les données d'un utilisateur spécifique
-- Remplacez 'cideg.p.line@gmail.com' par l'email de l'utilisateur à supprimer

-- Supprimer d'abord de la table de correspondance
DELETE FROM public.user_id_mapping WHERE app_user_id IN (
  SELECT id FROM public.users WHERE email = 'cideg.p.line@gmail.com'
);

-- Supprimer l'utilisateur de la table users (cela supprimera automatiquement les données liées grâce aux contraintes de clé étrangère)
DELETE FROM public.users WHERE email = 'cideg.p.line@gmail.com';