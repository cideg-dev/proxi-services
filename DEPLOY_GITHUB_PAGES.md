# Guide de déploiement : Frontend Flutter Web → GitHub Pages

Ce document explique comment builder et déployer le frontend Flutter sur GitHub Pages, et quelles configurations appliquer au backend pour que l'application fonctionne (Socket.IO, CORS, JWT, DB). Il propose aussi des mesures pour réduire l'exposition du code source côté web.

## Résumé
- Le frontend produit des fichiers statiques dans `frontend/build/web`.
- GitHub Pages peut servir ces fichiers depuis la branche `gh-pages` (ou `docs/` sur `main`).
- Le backend (Node/Express) doit être déployé ailleurs (Render, Railway, Heroku, VPS) ou exposé via un tunnel public pour que Socket.IO et l'API fonctionnent.

## Prérequis
- Avoir accès au dépôt GitHub et pouvoir pousser sur `main`.
- Avoir une cible pour le backend (ou ngrok pour tests).
- Secrets/variables nécessaires côté backend :
  - `JWT_SECRET` (obligatoire)
  - `DB_USER, DB_HOST, DB_DATABASE, DB_PASSWORD, DB_PORT` (Postgres)
  - `SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS` (si you use email)
  - `FRONTEND_URL` (à définir après déploiement Pages)

## Étapes locales (PowerShell)
1) Préparer le backend local (exemple minimal) :

```powershell
cd backend
$env:DB_USER='postgres'
$env:DB_HOST='localhost'
$env:DB_DATABASE='proxi'
$env:DB_PASSWORD='secret'
$env:DB_PORT='5432'
$env:JWT_SECRET='une_phrase_secrete'
$env:FRONTEND_URL='http://localhost:5173'
npm install
npm start
```

2) Builder le frontend localement (tester) :

```powershell
cd frontend
flutter pub get
flutter analyze
flutter build web --release --base-href "/<repo>/"
# Remplacez <repo> par le nom du repo (ou '/' pour username.github.io)
```

3) Vérifier manuellement le build : ouvrir `build/web/index.html` via un petit serveur local (par ex. `python -m http.server` ou `serve`) pour tester que l'UI s'affiche.

## Déploiement automatique via GitHub Actions (déjà ajouté)
- Fichier : `.github/workflows/deploy_flutter_web.yml` (présent dans le repo).
- Ce workflow :
  1. checkout
  2. setup Flutter
  3. flutter pub get
  4. flutter analyze
  5. flutter build web --release --base-href "/<repo>/"
  6. suppression des fichiers source-map (*.map)
  7. publish `build/web` sur `gh-pages`

Pour déclencher : push sur `main` ou `workflow_dispatch` manuel.

## Configurer le backend pour GitHub Pages
1) Déployer votre backend sur un service public (ex: Render, Railway, Heroku) et obtenir l'URL publique (ex: `https://api.example.com`).
2) Dans l'environnement du backend, définir la variable d'origine du frontend :

```
FRONTEND_URL=https://<user>.github.io/<repo>/
```

3) Redémarrer le backend pour prendre la variable en compte (Socket.IO/Express adaptent CORS selon `process.env.FRONTEND_URL`).

Remarque : `server.js` vérifie `JWT_SECRET` à l'initialisation et sort si absent — assurez-vous qu'il est défini.

## Réduire l'exposition du code source côté web (limites)
- Le build release minifie `main.dart.js` — c'est la première protection.
- Suppression des `.map` dans le workflow (déjà ajoutée) réduit la facilité de restauration du code original.
- Malgré cela, un utilisateur peut toujours télécharger `main.dart.js`. Pour réduire la surface d'attaque :
  - Ne pas placer de secrets côté client.
  - Déplacer toute logique sensible côté serveur (vérifications, calculs, clés API).
  - Si vous devez protéger davantage, envisagez de fournir une API côté serveur (no logic in client) et limiter les données renvoyées.

## Vérifications post-déploiement
1) Ouvrir `https://<user>.github.io/<repo>/` et vérifier l'UI.
2) Ouvrir la console devtools : vérifier absence d'erreurs CORS et que Socket.IO se connecte.
3) Tester quelques flows métiers : login, fetch artisans, chat (si backend accessible), upload images.
4) Vérifier logs backend pour erreurs (DB, JWT, Socket.IO).

## Troubleshooting commun
- Erreur CORS / Socket.IO : vérifier `FRONTEND_URL` côté backend; regarder origin configurée dans `server.js`.
- Backend ne démarre pas : vérifier `JWT_SECRET` et variables DB.
- Erreurs Flutter build : exécuter `flutter analyze` localement et corriger les erreurs signalées.

## Sécurité & secrets
- Ne jamais committer les secrets dans le repo.
- Utilisez GitHub Secrets pour workflows qui déploient le backend (si vous automatisez aussi le backend).

## Next steps que je peux faire pour vous
- A) Lancer une passe automatique pour corriger d'autres lints/erreurs simples dans `frontend/lib` (typage JSON, imports inutilisés, unused_element). Je peux corriger 3–6 fichiers par batch.
- B) Lancer un `flutter analyze` complet en local/CI et vous fournir le rapport complet (ou l'afficher ici si vous collez la sortie).
- C) Préparer un script PowerShell pour automatiser la préparation locale (set env + start backend + build frontend).

Si vous voulez que je continue (corriger automatiquement les erreurs restantes ou ajouter un README plus complet), dites-moi A, B ou C.

Fin du guide
