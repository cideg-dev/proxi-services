-- Fix for search_path vulnerability in get_app_user_id function
-- This ensures that the function always uses a secure, fixed search_path

-- First, let's check if the function exists and what its current definition is
SELECT proname, probin, prokind, provolatile, prosecdef, proargtypes
FROM pg_proc
WHERE proname = 'get_app_user_id';

-- Then, we'll recreate the function with a secure search_path
-- Replace the function definition with one that explicitly sets the search_path
-- First drop the function if it exists (this will handle the ambiguity)
DROP FUNCTION IF EXISTS public.get_app_user_id();

CREATE OR REPLACE FUNCTION public.get_app_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Required to access auth table
SET search_path = public -- Explicitly set search_path to public only
AS $$
BEGIN
  -- Ensure we're only looking in the public schema
  -- This prevents potential attacks through search_path manipulation
  RETURN auth.uid();
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO anon;

-- Add comment to document the security measure
COMMENT ON FUNCTION public.get_app_user_id IS 'Secure function to get the current application user ID with fixed search_path';