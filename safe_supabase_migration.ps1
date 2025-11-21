# Script de migration sécurisée vers Supabase avec solution de contournement

Write-Host "=== Migration sécurisée vers Supabase - Solution de contournement ===" -ForegroundColor Green
Write-Host "
Cette approche conserve votre schéma actuel avec des INTEGER tout en permettant
l'intégration avec l'authentification native de Supabase via une table de correspondance.
" -ForegroundColor Cyan

Write-Host "`n1. Exécution de la solution de compatibilité..." -ForegroundColor Yellow
Write-Host "
Copiez-collez le contenu du fichier suivant dans l'éditeur SQL de votre tableau de bord Supabase :
E:\projet_services\supabase_compatibility_solution.sql

Cela crée la table de correspondance et met à jour les politiques RLS.
" -ForegroundColor White

Read-Host "Appuyez sur Entrée quand la solution de compatibilité est déployée..."

Write-Host "`n2. Déploiement de la fonction de migration des utilisateurs..." -ForegroundColor Yellow
Write-Host "
Déployez la fonction de migration des utilisateurs :
1. Allez dans votre tableau de bord Supabase
2. Allez dans 'Functions'
3. Créez une nouvelle fonction appelée 'migrate-users'
4. Collez le contenu du fichier E:\projet_services\migrate_users_to_supabase_auth.ts
" -ForegroundColor White

Read-Host "Appuyez sur Entrée quand la fonction de migration est déployée..."

Write-Host "`n3. Mise à jour des fonctions Edge existantes..." -ForegroundColor Yellow
Write-Host "
Mettons à jour les fonctions Edge pour utiliser la nouvelle table de correspondance.

La fonction signup.ts doit maintenant :
1. Créer l'utilisateur dans Supabase Auth
2. Créer l'utilisateur dans la table users avec un ID généré
3. Insérer l'entrée dans la table de correspondance user_id_mapping
" -ForegroundColor White

Write-Host "`n4. Exécution de la migration des utilisateurs..." -ForegroundColor Yellow
Write-Host "
Une fois que tout est en place, vous pouvez exécuter la fonction de migration :
1. Dans votre tableau de bord Supabase
2. Allez dans 'Functions' 
3. Exécutez la fonction 'migrate-users' avec une requête POST

ATTENTION : Assurez-vous que vos données sont sauvegardées avant d'exécuter cette fonction.
" -ForegroundColor Red

Read-Host "Appuyez sur Entrée quand vous êtes prêt à exécuter la migration des utilisateurs..."

Write-Host "`n5. Mise à jour du frontend Flutter..." -ForegroundColor Yellow
Write-Host "
Dans votre projet Flutter :
1. Exécutez 'flutter pub get' dans le dossier frontend/
2. Utilisez le service Supabase disponible dans frontend/lib/services/supabase_service.dart
3. Remplacez vos anciens appels API par les méthodes SupabaseService
" -ForegroundColor White

Write-Host "`n=== Migration sécurisée terminée ===" -ForegroundColor Green
Write-Host "
Votre backend est maintenant compatible avec Supabase tout en conservant votre schéma existant.
- Table de correspondance UUID-INTEGER créée
- Politiques RLS mises à jour pour utiliser la correspondance
- Fonction de migration des utilisateurs déployée
- Frontend prêt pour l'intégration Supabase
" -ForegroundColor Cyan