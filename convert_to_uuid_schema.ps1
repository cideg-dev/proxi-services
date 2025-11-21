# Script de conversion du schéma vers UUID
# ATTENTION : Sauvegardez votre base de données avant d'exécuter ce script !

Write-Host "=== Conversion du schéma de INTEGER vers UUID ===" -ForegroundColor Red
Write-Host "
AVERTISSEMENT CRITIQUE : 
Ce script va modifier la structure de votre base de données.
Il est IMPÉRATIF de sauvegarder votre base de données avant de continuer.
" -ForegroundColor Red

$confirm1 = Read-Host "Avez-vous sauvegardé votre base de données ? (o/n)"
if ($confirm1 -ne 'o' -and $confirm1 -ne 'O') {
    Write-Host "❌ Conversion annulée - Veuillez sauvegarder votre base de données avant de continuer" -ForegroundColor Red
    exit 0
}

$confirm2 = Read-Host "Confirmez-vous la conversion du schéma vers UUID ? (o/n)"
if ($confirm2 -ne 'o' -and $confirm2 -ne 'O') {
    Write-Host "❌ Conversion annulée" -ForegroundColor Red
    exit 0
}

Write-Host "`n1. Connexion à Supabase..." -ForegroundColor Yellow

# Vous devrez fournir les détails de connexion à votre base de données
$projectUrl = Read-Host "Entrez l'URL de votre projet Supabase (https://xxxx.supabase.co)"
$databaseUrl = Read-Host "Entrez l'URL directe de votre base de données (DATABASE_URL de votre projet Supabase)"

Write-Host "`n2. Exécution du script de conversion de base de données..." -ForegroundColor Yellow
Write-Host "
Le script SQL de conversion est disponible dans :
E:\projet_services\script_conversion_uuid.sql

Exécutez ce script dans votre éditeur SQL de tableau de bord Supabase ou via psql.
" -ForegroundColor White

Write-Host "`n3. Exécution du script de finalisation..." -ForegroundColor Yellow
Write-Host "
Après avoir exécuté le script de conversion, exécutez :
E:\projet_services\script_finalisation_conversion_uuid.sql

ATTENTION : Soyez prudent avec la commande DROP COLUMN et assurez-vous
que toutes les données ont été correctement migrées avant de supprimer
les anciennes colonnes INTEGER.
" -ForegroundColor White

Write-Host "`n4. Mise à jour des politiques RLS..." -ForegroundColor Yellow
Write-Host "
Une fois la conversion terminée, exécutez le fichier mis à jour des politiques :
E:\projet_services\supabase\rls_policies.sql

Ce fichier est maintenant correctement configuré pour fonctionner avec les UUID.
" -ForegroundColor White

Write-Host "`n=== Conversion prête à être exécutée ===" -ForegroundColor Green
Write-Host "
Étapes à suivre :

1. Exécutez le script E:\projet_services\script_conversion_uuid.sql
2. Exécutez le script E:\projet_services\script_finalisation_conversion_uuid.sql
3. Exécutez le script E:\projet_services\supabase\rls_policies.sql

Puis mettez à jour votre application Flutter pour utiliser le service Supabase.
" -ForegroundColor Cyan