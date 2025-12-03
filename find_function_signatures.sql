-- Script pour identifier les signatures exactes de la fonction get_app_user_id

-- Cette requête vous donnera les signatures exactes des fonctions ambigues
SELECT 
    proname,
    oidvectortypes(proargtypes) AS argument_types,
    proargnames AS argument_names,
    probin AS source_binary,
    prosecdef AS is_security_definer,
    prokind AS function_type
FROM pg_proc 
JOIN pg_namespace n ON pg_proc.pronamespace = n.oid
WHERE proname = 'get_app_user_id' AND n.nspname = 'public';

-- Une fois que vous avez les signatures exactes, vous pouvez supprimer chaque version spécifique
-- Exemple de suppression (remplacez les XXX par les types réels trouvés dans la requête ci-dessus):
-- DROP FUNCTION IF EXISTS public.get_app_user_id(X_TYPE, Y_TYPE);
-- Répétez pour chaque signature trouvée

-- Puis créer la nouvelle version sécurisée
/*
CREATE OR REPLACE FUNCTION public.get_app_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN auth.uid();
END;
$$;
*/

-- Instructions :
-- 1. Exécutez d'abord la requête SELECT ci-dessus
-- 2. Regardez les types d'arguments retournés
-- 3. Remplacez les types dans la commande DROP FUNCTION
-- 4. Répétez pour chaque signature
-- 5. Ensuite, créez la nouvelle fonction sécurisée