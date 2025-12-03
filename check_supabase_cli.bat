@echo off
echo Checking Supabase CLI installation...

REM Check if Supabase CLI is installed
supabase --version
if %errorlevel% neq 0 (
    echo Supabase CLI is not installed. Installing...
    winget install --id Supabase.SupabaseCLI
    if %errorlevel% neq 0 (
        echo Please install Supabase CLI manually from https://github.com/supabase/cli/releases
        pause
        exit /b
    )
)

echo Supabase CLI is installed.
echo.

REM Check if logged in to Supabase
supabase status
if %errorlevel% neq 0 (
    echo Please log in to Supabase:
    supabase login
)

echo Supabase CLI is ready.
pause