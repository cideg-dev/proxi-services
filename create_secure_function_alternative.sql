-- Création d'une nouvelle fonction sécurisée avec un nom différent
-- pour éviter tout risque de suppression de fonction essentielle

-- Créer une nouvelle fonction sécurisée avec nom modifié
CREATE OR REPLACE FUNCTION public.secure_get_app_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public -- Fixed search_path for security
AS $$
BEGIN
  -- Returns the authenticated user ID from the auth system
  -- This is the same logic as the original function but with secure configuration
  RETURN auth.uid();
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.secure_get_app_user_id TO authenticated;
GRANT EXECUTE ON FUNCTION public.secure_get_app_user_id TO anon;

-- Add security documentation
COMMENT ON FUNCTION public.secure_get_app_user_id IS 'Secure function to get the current application user ID with fixed search_path';

-- Verification: Check that the new function was created
SELECT 
    proname,
    prosecdef AS is_security_definer,
    proconfig AS configuration_settings
FROM pg_proc 
WHERE proname = 'secure_get_app_user_id';

-- NOTE: Cette fonction peut être utilisée comme remplacement sécurisé
-- pour toute logique qui utilisait précédemment get_app_user_id()
-- Elle a le même comportement mais avec la sécurité renforcée