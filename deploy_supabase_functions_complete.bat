@echo off
cd /d E:\projet_services\supabase

echo Deploiement des fonctions Supabase...

echo Deploiement de la fonction signup...
supabase functions deploy signup --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction signin...
supabase functions deploy signin --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction logout...
supabase functions deploy logout --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction artisans...
supabase functions deploy artisans --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction professionals...
supabase functions deploy professionals --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction reviews...
supabase functions deploy reviews --project-ref ufeqnnbokyalwjfskhmw

echo Deploiement de la fonction migrate-users...
supabase functions deploy migrate-users --project-ref ufeqnnbokyalwjfskhmw

echo Verification du statut des fonctions...
supabase functions list --project-ref ufeqnnbokyalwjfskhmw

echo.
echo Deploiement termine! Veuillez verifier que toutes les fonctions sont bien deployees dans votre projet Supabase.
echo.
echo Pour des instructions completes sur la configuration, veuillez consulter : DEPLOY_SUPABASE_FUNCTIONS.md
pause