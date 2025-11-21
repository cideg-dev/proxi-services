# Script de migration complet vers Supabase
# Ce script guide à travers toutes les étapes de la migration

# Fonction pour vérifier si supabase CLI est installé
function Check-SupabaseCLI {
    try {
        $version = & supabase --version
        Write-Host "✅ Supabase CLI trouvé : $version" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Supabase CLI non trouvé." -ForegroundColor Red
        return $false
    }
}

# Fonction pour attendre l'utilisateur
function WaitForUser {
    param($message)
    Write-Host $message -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour continuer"
}

Write-Host "=== Migration complète vers Supabase ===" -ForegroundColor Green

# Vérification de Supabase CLI
if (-not (Check-SupabaseCLI)) {
    Write-Host "Veuillez installer Supabase CLI avec : npm install -g supabase" -ForegroundColor Red
    exit 1
}

# Étape 1 : Informations de projet
Write-Host "`n1. Informations de projet Supabase" -ForegroundColor Cyan
$projectRef = Read-Host "Entrez votre Project Ref Supabase (trouvable dans Settings > Project Settings)"
$projectUrl = Read-Host "Entrez l'URL de votre projet Supabase (https://xxxx.supabase.co)"
$anonKey = Read-Host "Entrez votre clé anon (dans Settings > Project Settings > API)"

# Confirmation
Write-Host "`nConfirmation des informations :" -ForegroundColor Yellow
Write-Host "Project Ref : $projectRef" -ForegroundColor White
Write-Host "Project URL : $projectUrl" -ForegroundColor White
$confirm = Read-Host "Confirmez-vous ces informations ? (o/n)"

if ($confirm -ne 'o' -and $confirm -ne 'O') {
    Write-Host "❌ Migration annulée" -ForegroundColor Red
    exit 0
}

# Étape 2 : Déploiement des fonctions Edge
Write-Host "`n2. Déploiement des fonctions Edge..." -ForegroundColor Cyan
Set-Location supabase
try {
    & supabase functions deploy --project-ref $projectRef
    Write-Host "✅ Fonctions Edge déployées avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du déploiement des fonctions Edge" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

WaitForUser "`nAppuyez sur Entrée pour continuer avec la conversion du schéma..."

# Étape 3 : Conversion du schéma
Write-Host "`n3. Conversion du schéma vers UUID" -ForegroundColor Cyan
Write-Host "
AVERTISSEMENT : Votre base de données utilise actuellement des INTEGER pour les IDs,
alors que l'authentification Supabase utilise des UUID.

Pour continuer, vous devez convertir votre schéma :
1. Exécutez E:\projet_services\script_conversion_uuid.sql
2. Exécutez E:\projet_services\script_finalisation_conversion_uuid.sql
" -ForegroundColor Yellow

$choice = Read-Host "Avez-vous sauvegardé votre base de données et prêt à convertir vers UUID ? (o/n)"
if ($choice -eq 'o' -or $choice -eq 'O') {
    Write-Host "
    La conversion doit être faite manuellement car elle affecte directement vos données.
    Les scripts sont disponibles dans E:\projet_services\ :
    1. script_conversion_uuid.sql
    2. script_finalisation_conversion_uuid.sql
    " -ForegroundColor White
} else {
    Write-Host "Veuillez sauvegarder votre base de données avant de continuer." -ForegroundColor Red
    exit 0
}

WaitForUser "`nAprès avoir exécuté les scripts de conversion, appuyez sur Entrée pour continuer..."

# Étape 4 : Mise en place des politiques RLS
Write-Host "`n4. Mise en place des politiques RLS..." -ForegroundColor Cyan
Write-Host "
Exécutez maintenant le fichier de politiques RLS dans votre tableau de bord Supabase :
1. Allez dans votre tableau de bord Supabase
2. Allez dans l'onglet SQL
3. Copiez-collez le contenu de E:\projet_services\supabase\rls_policies.sql
4. Cliquez sur 'Run'
" -ForegroundColor White

WaitForUser "`nAprès avoir exécuté les politiques RLS, appuyez sur Entrée pour continuer..."

# Étape 5 : Mise à jour du frontend
Write-Host "`n5. Mise à jour du frontend Flutter..." -ForegroundColor Cyan
Write-Host "
Dans votre projet Flutter :
1. Exécutez 'flutter pub get' dans le dossier frontend/
2. Le service Supabase est disponible dans frontend/lib/services/supabase_service.dart
3. Remplacez vos anciens appels API par les méthodes SupabaseService
" -ForegroundColor White

Write-Host "`n=== Migration terminée ===" -ForegroundColor Green
Write-Host "
Toutes les étapes de la migration ont été configurées.
Votre backend est maintenant basé sur Supabase avec :

✅ Fonctions Edge déployées
✅ Schéma converti pour gérer les UUID
✅ Politiques RLS mises en place
✅ Frontend prêt pour l'intégration Supabase

Votre application n'a plus besoin d'une plateforme backend tierce comme Render.
Les données sont gérées directement par Supabase avec des politiques de sécurité.
" -ForegroundColor Cyan