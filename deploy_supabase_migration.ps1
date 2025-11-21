# Script de déploiement de la migration Supabase - Version mise à jour
# Exécutez ce script après avoir installé l'interface de ligne de commande Supabase

Write-Host "=== Déploiement de la migration vers Supabase ===" -ForegroundColor Green

# Vérifier si supabase CLI est installé
try {
    $supabaseVersion = & supabase --version
    Write-Host "✅ Supabase CLI trouvé : $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI non trouvé. Veuillez l'installer avec:" -ForegroundColor Red
    Write-Host "npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Demander les informations de projet
$projectRef = Read-Host "Entrez votre Project Ref Supabase (trouvable dans Settings > Project Settings)"
$confirm = Read-Host "Confirmez-vous le déploiement pour le projet $projectRef ? (o/n)"

if ($confirm -ne 'o' -and $confirm -ne 'O') {
    Write-Host "❌ Déploiement annulé" -ForegroundColor Red
    exit 0
}

# Se déplacer dans le répertoire supabase
Set-Location supabase

Write-Host "`n1. Déploiement des fonctions Edge..." -ForegroundColor Yellow
try {
    & supabase functions deploy --project-ref $projectRef
    Write-Host "✅ Fonctions Edge déployées avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du déploiement des fonctions Edge" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Instructions pour la conversion du schéma et les politiques RLS :" -ForegroundColor Yellow
Write-Host "
AVERTISSEMENT : Votre base de données utilise actuellement des INTEGER pour les IDs,
alors que l'authentification Supabase utilise des UUID. Pour une compatibilité complète :

OPTION 1 (Recommandée) - Conversion vers UUID :
1. Sauvegardez votre base de données actuelle
2. Exécutez les scripts dans cet ordre :
   - E:\projet_services\script_conversion_uuid.sql
   - E:\projet_services\script_finalisation_conversion_uuid.sql
3. Ensuite, exécutez le contenu de ce fichier dans votre tableau de bord Supabase

OPTION 2 (Solution temporaire) - Adaptation pour INTEGER :
- Si vous choisissez de conserver votre schéma actuel, vous devrez adapter
  les politiques RLS pour gérer la conversion UUID vers INTEGER.

Pour exécuter les politiques RLS, allez dans votre tableau de bord Supabase :
1. Allez dans l'onglet 'SQL'
2. Copiez-collez le contenu du fichier 'rls_policies.sql'
3. Cliquez sur 'Run'
" -ForegroundColor White

Write-Host "`n3. Mise à jour du frontend Flutter :" -ForegroundColor Yellow
Write-Host "
Dans votre projet Flutter :
1. Exécutez 'flutter pub get' pour installer les nouvelles dépendances
2. Testez l'application pour vérifier que tout fonctionne correctement
" -ForegroundColor White

Write-Host "`n=== Migration presque terminée ===" -ForegroundColor Green
Write-Host "
La migration est presque terminée ! Vous devez maintenant :

1. Suivre les instructions ci-dessus pour la conversion du schéma (recommandée)
2. Exécuter les politiques RLS dans votre tableau de bord Supabase
3. Mettre à jour votre frontend Flutter pour utiliser le service Supabase
4. Tester votre application

Consultez le fichier MIGRATION_SUPABASE.md pour des instructions détaillées.
" -ForegroundColor Cyan