@echo off
echo Deploying Supabase functions with corrected config...

REM Change to the project directory
cd /d "E:\projet_services"

REM Deploy each function
echo Deploying signup function...
supabase functions deploy signup

echo Deploying signin function...
supabase functions deploy signin

echo Deploying profile function...
supabase functions deploy profile

echo Deploying artisans function...
supabase functions deploy artisans

echo Deploying professionals function...
supabase functions deploy professionals

echo Deploying reviews function...
supabase functions deploy reviews

echo Deploying migrate-users function...
supabase functions deploy migrate-users

echo Deploying logout function...
supabase functions deploy logout

echo Deploying conversations function...
supabase functions deploy conversations

echo All functions deployed successfully!
echo.
echo NOTE: For CORS configuration, please update it in your Supabase Dashboard:
echo 1. Go to https://app.supabase.com/project/YOUR_PROJECT_ID/settings/api
echo 2. Add "https://cideg-dev.github.io" to the "Additional URLs" section under "API Settings"
echo 3. Save the changes
pause