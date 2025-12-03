@echo off
echo Deploying all Supabase functions...

REM Change to the project directory
cd /d "E:\projet_services"

REM Deploy each function
supabase functions deploy signup
supabase functions deploy signin
supabase functions deploy profile
supabase functions deploy artisans
supabase functions deploy professionals
supabase functions deploy reviews
supabase functions deploy migrate-users
supabase functions deploy logout
supabase functions deploy conversations

echo All functions deployed successfully.
pause