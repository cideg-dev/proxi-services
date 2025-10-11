@ECHO OFF
:: =================================================================================
:: Script pour réinitialiser complètement la base de données PostgreSQL.
:: DOIT ÊTRE EXÉCUTÉ EN TANT QU'ADMINISTRATEUR.
::
:: Ce script va :
:: 1. Arrêter le service PostgreSQL.
:: 2. Sauvegarder l'ancien dossier de données.
:: 3. Créer un nouveau cluster de base de données avec le mot de passe 'Martial2017'.
:: 4. Démarrer le service.
:: 5. Créer la base de données 'proxiservices' et y appliquer le schéma.
:: =================================================================================

:: Vérification des droits d'administrateur
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo Erreur: Veuillez executer ce script en tant qu'administrateur.
    echo.
    pause
    exit /b
)

:: --- Configuration ---
SET PG_VERSION=17
SET PG_BIN_PATH="C:\Program Files\PostgreSQL\%PG_VERSION%\bin"
SET PG_DATA_PATH="C:\Program Files\PostgreSQL\%PG_VERSION%\data"
SET NEW_PG_PASSWORD=Martial2017
SET DB_NAME=proxiservices
SET DB_USER=postgres

:: --- Début du processus ---
ECHO.
ECHO Ce script va effacer et recréer la base de données PostgreSQL.
ECHO Le dossier %PG_DATA_PATH% sera renommé en %PG_DATA_PATH%_old.
PAUSE

ECHO.
ECHO Etape 1: Arrêt du service PostgreSQL...
net stop postgresql-x64-%PG_VERSION%
if %errorlevel% neq 0 (
    echo "Le service n'a pas pu être arrêté. Est-il déjà stoppé ?"
)

ECHO.
ECHO Etape 2: Sauvegarde de l'ancien dossier de données...
if exist %PG_DATA_PATH% (
    ren %PG_DATA_PATH% "data_old_%random%"
)

ECHO.
ECHO Etape 3: Création du nouveau cluster de base de données...
mkdir %PG_DATA_PATH%
echo %NEW_PG_PASSWORD% > "%TEMP%\pgpass.txt"
%PG_BIN_PATH%\initdb.exe -D %PG_DATA_PATH% -U %DB_USER% --pwfile="%TEMP%\pgpass.txt"
del "%TEMP%\pgpass.txt"

ECHO.
ECHO Etape 4: Démarrage du service PostgreSQL...
net start postgresql-x64-%PG_VERSION%
if %errorlevel% neq 0 (
    echo "ERREUR: Le service PostgreSQL n'a pas pu démarrer. Vérifiez les logs."
    pause
    exit /b
)
ECHO Le service a démarré. Attente de 5 secondes pour l'initialisation...
timeout /t 5

ECHO.
ECHO Etape 5: Création de la base de données '%DB_NAME%' et application du schéma...
set PGPASSWORD=%NEW_PG_PASSWORD%
%PG_BIN_PATH%\psql.exe -U %DB_USER% -c "CREATE DATABASE %DB_NAME%;"
%PG_BIN_PATH%\psql.exe -U %DB_USER% -d %DB_NAME% -f schema.sql

ECHO.
ECHO =================================================================
ECHO SUCCES: La base de données a été complètement réinitialisée.
ECHO Le mot de passe pour l'utilisateur '%DB_USER%' est '%NEW_PG_PASSWORD%'.
ECHO =================================================================
ECHO.
pause
