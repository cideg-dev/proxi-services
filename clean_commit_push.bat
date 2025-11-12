@echo off
echo Nettoyage des fichiers temporaires...
del /q /f *.tmp 2>nul
del /q /f *~ 2>nul
for /d %%x in (.git\rebase-apply .git\rebase-merge) do (rmdir /s /q "%%x" 2>nul)

echo Verification de l'etat du depot...
git status

echo Ajout des fichiers modifies au commit...
git add -A

echo Creation du commit...
git commit -m "Corrections de securite et ameliorations des services backend"

echo Verification avant envoi vers GitHub...
git status

echo Envoi vers le depot distant GitHub...
git push origin master

echo Operation terminee.
pause