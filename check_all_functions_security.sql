-- Check all functions for potential security issues including mutable search_path
-- This script will help ensure all functions have properly configured search_path

-- Query to identify functions that don't have an explicit search_path set
SELECT
    p.proname AS function_name,
    p.prosrc AS function_source,
    n.nspname AS schema_name,
    CASE
        WHEN p.proconfig IS NOT NULL AND p.proconfig::text LIKE '%search_path%' THEN 'SECURE'
        ELSE 'VULNERABLE - Missing explicit search_path'
    END AS security_status
FROM
    pg_proc p
JOIN
    pg_namespace n ON p.pronamespace = n.oid
WHERE
    n.nspname = 'public'
    AND p.prokind = 'f'  -- Only functions, not procedures
ORDER BY
    security_status, function_name;

-- Example of how to fix the get_app_user_id function with proper security
-- (This is a template - adjust according to your specific function)

/*
-- Template for securing a function:
CREATE OR REPLACE FUNCTION public.your_function_name()
RETURNS your_return_type
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public -- Fixed search_path for security
AS $$
BEGIN
    -- Your function logic here
    -- Make sure to validate all inputs and use proper access controls
    RETURN your_result;
END;
$$;

-- Grant only necessary permissions
GRANT EXECUTE ON FUNCTION public.your_function_name TO authenticated;
*/

-- Specific fix for get_app_user_id function
CREATE OR REPLACE FUNCTION public.get_app_user_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public -- Explicitly set search_path for security
AS $$
BEGIN
  RETURN auth.uid();
END;
$$;

-- Ensure proper permissions are set
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_app_user_id TO anon;