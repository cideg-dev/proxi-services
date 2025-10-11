@echo off
setlocal

:: =================================================================
:: Script semi-automatisé pour réinitialiser le mot de passe PostgreSQL
:: À EXÉCUTER EN TANT QU'ADMINISTRATEUR
:: =================================================================

echo.
echo Ce script vous guidera pour reinitialiser votre mot de passe PostgreSQL.
echo Il doit etre execute en tant qu'administrateur.
echo.
pause
cls

:: --- Etape 1: Demander les informations nécessaires ---
echo Etape 1: Informations sur votre installation PostgreSQL
echo ----------------------------------------------------
echo.
set /p "PG_VERSION=Entrez votre version majeure de PostgreSQL (ex: 14, 15, 16): "
set /p "PG_USER=Entrez le nom d'utilisateur a reinitialiser (generalement 'postgres'): "
echo.

set "PG_SERVICE_NAME=postgresql-x64-%PG_VERSION%"
set "PG_DATA_PATH=C:\Program Files\PostgreSQL\%PG_VERSION%\data"
set "PG_HBA_PATH=%PG_DATA_PATH%\pg_hba.conf"

echo Le script va utiliser les chemins et noms suivants:
echo   - Nom du service: %PG_SERVICE_NAME%
echo   - Chemin du fichier de conf: %PG_HBA_PATH%
echo.
echo Si ces informations sont incorrectes, fermez ce script et modifiez-les manuellement.
echo.
pause
cls

:: --- Etape 2: Arrêter le service ---
echo Etape 2: Arret du service PostgreSQL
echo ------------------------------------
echo.
net stop %PG_SERVICE_NAME%
if %errorlevel% neq 0 (
    echo.
    echo /!\ ERREUR: Le service '%PG_SERVICE_NAME%' n'a pas pu etre arrete.
    echo Verifiez le nom du service dans la console 'services.msc'.
    pause
    exit /b
)
echo Le service a ete arrete avec succes.
echo.
pause
cls

:: --- Etape 3: Modification manuelle du fichier de configuration ---
echo Etape 3: Modification de pg_hba.conf
echo ---------------------------------------
echo.
echo Le fichier de configuration va s'ouvrir dans le Bloc-notes.
echo.
echo IMPORTANT:
echo 1. Trouvez les lignes commencant par 'host' pour l'adresse 127.0.0.1 et ::1.
echo 2. Remplacez la methode a la fin de ces lignes (ex: 'scram-sha-256' ou 'md5') par 'trust'.
echo 3. Enregistrez le fichier (Ctrl+S) et fermez le Bloc-notes.
echo.

notepad "%PG_HBA_PATH%"

echo.
echo Appuyez sur une touche lorsque vous avez termine de modifier et d'enregistrer le fichier.
pause
cls

:: --- Etape 4: Redémarrer le service ---
echo Etape 4: Redemarrage du service PostgreSQL
echo -----------------------------------------
echo.
net start %PG_SERVICE_NAME%
if %errorlevel% neq 0 (
    echo.
    echo /!\ ERREUR: Le service '%PG_SERVICE_NAME%' n'a pas pu etre redemarre.
    echo Verifiez les logs de PostgreSQL pour trouver l'erreur.
    pause
    exit /b
)
echo Le service a ete redemarre avec succes.
echo.
pause
cls

:: --- Etape 5: Changer le mot de passe ---
echo Etape 5: Changement du mot de passe
echo -----------------------------------
echo.
echo Entrez le nouveau mot de passe pour l'utilisateur '%PG_USER%'.
set /p "NEW_PASSWORD=Nouveau mot de passe: "
echo.

echo Connexion a psql pour changer le mot de passe...
"C:\Program Files\PostgreSQL\%PG_VERSION%\bin\psql.exe" -U %PG_USER% -c "ALTER USER %PG_USER% WITH PASSWORD '%NEW_PASSWORD%';"

if %errorlevel% neq 0 (
    echo.
    echo /!\ ERREUR: La commande de changement de mot de passe a echoue.
    pause
) else (
    echo.
    echo --- MOT DE PASSE CHANGE AVEC SUCCES ---
    echo.
)
pause
cls

:: --- Etape 6: Restauration de la sécurité ---
echo Etape 6: Restauration de la securite (TRES IMPORTANT)
echo ----------------------------------------------------
echo.
echo Le service va etre arrete a nouveau.
net stop %PG_SERVICE_NAME%
echo.
echo Le fichier de configuration va se rouvrir.
echo.
echo IMPORTANT:
echo 1. Annulez les modifications precedentes. Remettez la methode 'scram-sha-256' (ou 'md5').
echo 2. Enregistrez et fermez le fichier.
echo.

notepad "%PG_HBA_PATH%"

echo.
echo Appuyez sur une touche pour finaliser et redemarrer le service.
pause

net start %PG_SERVICE_NAME%
echo.
echo Le service a ete redemarre. La procedure est terminee.
echo N'oubliez pas de mettre a jour votre nouveau mot de passe dans le fichier .env !
echo.
pause
endlocal