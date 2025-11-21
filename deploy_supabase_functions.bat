@echo off
cd /d E:\projet_services\supabase

echo Deploiement des fonctions Supabase...

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
pause