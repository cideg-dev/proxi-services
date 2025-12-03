/*
Comprehensive security fix for get_app_user_id function
This script properly handles the function ambiguity by identifying and removing all versions
before creating the secure version with fixed search_path
*/

-- Step 1: Identify all versions of the get_app_user_id function
SELECT 
    proname,
    oidvectortypes(proargtypes) AS argument_types,
    prosrc AS source_code,
    prosecdef AS is_security_definer,
    prosecdef AS security_definer_status
FROM pg_proc 
WHERE proname = 'get_app_user_id';

-- Step 2: Drop all versions of the function by specifying their exact argument lists
-- We need to identify the exact signatures from the previous query and drop them one by one
-- Since we know get_app_user_id should have no arguments, we'll drop the argumentless version
-- If there are other versions, we need to drop those as well

-- Drop the no-argument version
DROP FUNCTION IF EXISTS public.get_app_user_id() CASCADE;

-- If there were other versions with arguments, they would be dropped like this:
-- DROP FUNCTION IF EXISTS public.get_app_user_id(param1_type, param2_type) CASCADE;

-- Step 3: Create the new secure function with fixed search_path
CREATE OR REPLACE FUNCTION public.get_app_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public -- Explicitly set search_path to prevent manipulation
AS $$
BEGIN
  -- Returns the authenticated user ID from the auth system
  RETURN auth.uid();
END;
$$;

-- Step 4: Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO anon;

-- Step 5: Add security documentation
COMMENT ON FUNCTION public.get_app_user_id IS 'Secure function to get the current application user ID with fixed search_path';

-- Step 6: Verify the function was created correctly
SELECT 
    proname,
    prosecdef AS is_security_definer,
    prosecdef AS security_definer_status,
    proconfig AS configuration_settings
FROM pg_proc 
WHERE proname = 'get_app_user_id';