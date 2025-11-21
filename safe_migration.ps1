# Script de migration sécurisée vers UUID - Version finale

Write-Host "=== Migration sécurisée du schéma vers UUID ===" -ForegroundColor Green
Write-Host "
CETTE MIGRATION EST SENSIBLE. S'IL VOUS PLAÎT :
1. Sauvegardez votre base de données avant de continuer
2. Exécutez cette migration dans un environnement de test d'abord
3. Soyez prêt à restaurer à partir de votre sauvegarde en cas de problème
" -ForegroundColor Red

$confirm = Read-Host "Avez-vous sauvegardé votre base de données ? (o/n)"
if ($confirm -ne 'o' -and $confirm -ne 'O') {
    Write-Host "❌ Migration annulée - Sauvegardez d'abord votre base de données" -ForegroundColor Red
    exit 1
}

Write-Host "`n1. Exécution de la migration étape 1..." -ForegroundColor Yellow
Write-Host "
Copiez-collez le contenu du fichier suivant dans l'éditeur SQL de votre tableau de bord Supabase :
E:\projet_services\migration_step1.sql
" -ForegroundColor White

Read-Host "Appuyez sur Entrée quand la migration étape 1 est terminée avec succès..."

Write-Host "`n2. Exécution de la migration étape 2..." -ForegroundColor Yellow
Write-Host "
Copiez-collez le contenu du fichier suivant dans l'éditeur SQL de votre tableau de bord Supabase :
E:\projet_services\migration_step2.sql
" -ForegroundColor White

Read-Host "Appuyez sur Entrée quand la migration étape 2 est terminée avec succès..."

Write-Host "`n3. Validation de la migration..." -ForegroundColor Yellow
Write-Host "
Copiez-collez le contenu du fichier suivant pour valider la migration :
E:\projet_services\validate_migration.sql
" -ForegroundColor White

Read-Host "Appuyez sur Entrée quand la validation est terminée et que tous les tests passent..."

Write-Host "`n4. Migration finale (cette étape est critique)..." -ForegroundColor Red
Write-Host "
Dernière chance : Assurez-vous que votre base de données est sauvegardée.

Copiez-collez le contenu du fichier suivant dans l'éditeur SQL de votre tableau de bord Supabase :
E:\projet_services\migration_final.sql

CETTE ÉTAPE EST DÉFICILE - SOYEZ CERTAIN DE VOTRE SAUVEGARDE
" -ForegroundColor Red

Read-Host "Appuyez sur Entrée quand vous êtes prêt pour la migration finale..."

Write-Host "`n5. Migration terminée" -ForegroundColor Green
Write-Host "
La conversion de votre schéma vers UUID est maintenant terminée.
Votre base de données est prête à fonctionner avec l'authentification native de Supabase.
" -ForegroundColor Cyan