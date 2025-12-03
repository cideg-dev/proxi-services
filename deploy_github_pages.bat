@echo off
setlocal

echo ================================================
echo Deploiement de l'application Proxi-Services sur GitHub Pages
echo ================================================

REM Chemin vers les fichiers construits
set BUILD_PATH=E:\projet_services\frontend\build\web
set DEPLOY_PATH=E:\projet_services\github_pages_deploy

REM Vérifier si les fichiers sont prêts
if not exist "%DEPLOY_PATH%\index.html" (
    echo Erreur : Les fichiers de build n'existent pas dans %DEPLOY_PATH%
    echo Lancez flutter build web avant d'executer ce script
    exit /b 1
)

echo Fichiers de build trouves dans %DEPLOY_PATH%

REM Si vous avez un repo GitHub local, vous pouvez copier les fichiers directement
REM dans le bon repertoire et faire un commit/push

echo.
echo Instructions pour le depot GitHub :
echo 1. Allez dans votre depot GitHub local (ex: E:\mon_depot_github)
echo 2. Copiez le contenu de %DEPLOY_PATH% dans le repertoire racine ou dans le dossier docs/
echo 3. Faites un commit et un push :
echo    git add .
echo    git commit -m "Deploy de l'application Proxi-Services"
echo    git push origin main

echo.
echo Si vous utilisez une action GitHub, vous pouvez directement utiliser le repertoire %DEPLOY_PATH% comme source

echo.
echo Le depot est pret dans : %DEPLOY_PATH%
echo Vous pouvez maintenant :
echo - Copier ces fichiers vers votre depot GitHub
echo - Utiliser une action GitHub pour deployer automatiquement
echo - Deployer manuellement sur GitHub Pages

pause