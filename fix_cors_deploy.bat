@echo off
cd /d E:\projet_services\supabase

echo Verification de la fonction signin...
type functions\signin\index.ts | findstr "OPTIONS\|Access-Control-Allow-Origin"

echo.
echo Redeploiement de la fonction signin avec gestion CORS amelioree...
supabase functions deploy signin --project-ref ufeqnnbokyalwjfskhmw

echo Verification du statut de la fonction...
supabase functions list --project-ref ufeqnnbokyalwjfskhmw | findstr signin

echo.
echo Pour verifier que la fonction fonctionne correctement:
echo 1. Allez dans votre dashboard: https://supabase.com/dashboard/project/ufeqnnbokyalwjfskhmw/functions
echo 2. Cliquez sur la fonction "signin"
echo 3. Consultez les logs pour verifier qu'il n'y a pas d'erreurs
echo.
echo Si le probleme persiste, consultez le fichier CORS_FIX.md pour des solutions additionnelles.
pause