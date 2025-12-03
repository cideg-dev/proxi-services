@echo off
echo Starting complete solution deployment...

echo.
echo Step 1: Checking Supabase CLI...
call "E:\projet_services\check_supabase_cli.bat"

echo.
echo Step 2: Deploying Supabase functions...
call "E:\projet_services\deploy_all_functions.bat"

echo.
echo Step 3: Building Flutter Web application...
call "E:\projet_services\build_flutter_web.bat"

echo.
echo Step 4: Updating GitHub Pages deployment...
call "E:\projet_services\deploy_github_pages.bat"

echo.
echo All steps completed successfully!
echo The application should now be working without the CORS and API errors.
pause