@echo off
setlocal enabledelayedexpansion

REM Sauvegarder le répertoire courant
cd /d E:\projet_services

echo Creation de la structure temporaire pour le depot...

REM Creer un repertoire temporaire pour le depot
if exist "temp_deploy" (
  rmdir /s /q temp_deploy
)
mkdir temp_deploy
cd temp_deploy

REM Initialiser le projet supabase
supabase init

REM Creer la structure des fonctions
mkdir supabase\functions\signup
mkdir supabase\functions\signin
mkdir supabase\functions\artisans
mkdir supabase\functions\reviews
mkdir supabase\functions\migrate-users

REM Copier les fichiers de fonction
copy "..\supabase\functions\signup\index.ts" "supabase\functions\signup\index.ts" >nul
copy "..\supabase\functions\signin\index.ts" "supabase\functions\signin\index.ts" >nul
copy "..\supabase\functions\artisans\index.ts" "supabase\functions\artisans\index.ts" >nul
copy "..\supabase\functions\reviews\index.ts" "supabase\functions\reviews\index.ts" >nul
copy "..\supabase\functions\migrate-users\index.ts" "supabase\functions\migrate-users\index.ts" >nul

REM Copier le fichier de configuration
copy "..\supabase\config.toml" "supabase\config.toml" >nul

echo Deploiement des fonctions Supabase depuis le repertoire temporaire...

echo Deploiement de la fonction signup...
supabase functions deploy signup --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction signin...
supabase functions deploy signin --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction artisans...
supabase functions deploy artisans --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction reviews...
supabase functions deploy reviews --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction migrate-users...
supabase functions deploy migrate-users --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement termine!

REM Retourner au repertoire initial et nettoyer
cd ..
rmdir /s /q temp_deploy

pause