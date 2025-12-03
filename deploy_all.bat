@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo     Script de déploiement complet - Proxi-Services
echo =====================================================
echo.

REM Vérifier si le répertoire courant est le bon
if not exist "frontend" (
    echo ERREUR: Ce script doit être exécuté depuis le répertoire racine du projet
    pause
    exit /b 1
)

echo Etape 1: Déploiement des fonctions Supabase...
call deploy_functions.bat
if errorlevel 1 (
    echo ERREUR lors du déploiement des fonctions Supabase
    pause
    exit /b 1
)

echo.
echo Etape 2: Déploiement des migrations de base de données...
REM Vérifier si supabase CLI est installé
supabase --version >nul 2>&1
if errorlevel 1 (
    echo ATTENTION: Supabase CLI n'est pas installé ou n'est pas dans le PATH
    echo Installez-le avec: npm install -g @supabase/cli
    echo Puis exécutez manuellement: supabase db push
    pause
) else (
    echo Exécution de: supabase db push
    supabase db push
    if errorlevel 1 (
        echo ERREUR lors du déploiement des migrations
        pause
        exit /b 1
    )
    echo Migrations déployées avec succès!
)

echo.
echo Etape 3: Le frontend Flutter devra être rebuild et redéployé manuellement
echo Si vous utilisez GitHub Pages, exécutez: flutter build web
echo Si vous utilisez Render ou une autre plateforme, le déploiement se fait via les repo Git

echo.
echo =====================================================
echo     Déploiement terminé avec succès!
echo     Vérifiez les tableaux de bord pour confirmer
echo =====================================================

pause