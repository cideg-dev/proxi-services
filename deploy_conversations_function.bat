@echo off
echo Deploying conversations function to Supabase...

REM Change to the project directory
cd /d "E:\projet_services"

REM Deploy the conversations function
supabase functions deploy conversations

echo Deployment completed.
pause