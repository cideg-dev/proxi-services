## Contexte rapide

Application « Proxi-Services » mono-repo : backend Node/Express (dossier `backend/`) exposant REST + Socket.IO et frontend Flutter (dossier `frontend/`) ciblant mobile et web.

Principaux composants à connaître :
- backend: `server.js` (Socket.IO, routes, uploads), `db.config.js` (pg Pool), `middleware/authMiddleware.js` (JWT + autorisations), `controllers/*` (logique métier).
- frontend: Flutter app (web build -> static files sous `build/web`), utilise `socket_io_client`, `flutter_dotenv` et `assets/app.env`.

Points critiques (concret)
- DB: PostgreSQL configuré via `DB_USER, DB_HOST, DB_DATABASE, DB_PASSWORD, DB_PORT` (voir `backend/db.config.js`).
- JWT: `JWT_SECRET` est requis (vérifié dans `server.js` — le process s'arrête si absent).
- Uploads: fichiers servis depuis `/uploads`, images traitées avec `sharp` et `multer.memoryStorage()` (voir `server.js` et `controllers/portfolioController.js`).
- Socket.IO: événements clés dans `server.js`: `user connected`, `chat message`, `update online users`, `user-disconnected`. Le serveur maintient une Map `connectedUsers`.

Conventions de code importantes
- Trois rôles: `client`, `artisan`, `commercant`. Les profils sont dans des tables séparées (`client_profiles`, `artisan_profiles`, `commercant_profiles`) — ne changez pas la structure sans vérifier `schema.sql`.
- Validation: `express-validator` est employé dans les routes.
- Ne pas renommer de colonnes DB ni changer le format du JWT (routes/authRoutes.js signent et attendent ce format).

Déploiement Flutter Web / GitHub Pages — notes spécifiques
- Le frontend Flutter produit un site statique (dossier `build/web`). GitHub Pages peut servir ces fichiers (branch `gh-pages` ou dossier `docs/`).
- `frontend/web/index.html` contient une variable de base href (`$FLUTTER_BASE_HREF`) — pour GitHub Pages builder, utilisez :

  flutter build web --release --base-href "/REPO_NAME/"

  Remplacez `/REPO_NAME/` par le chemin GitHub Pages (ou `/` si vous publiez en `username.github.io`).
- CAVEATS Socket.IO & API: GitHub Pages est statique — le backend doit être public (https) et CORS autoriser l'origine GitHub Pages. `server.js` utilise `process.env.FRONTEND_URL` (par défaut `http://localhost:5173`) comme origine Socket.IO; si vous déployez sur Pages, mettez `FRONTEND_URL=https://<user>.github.io/<repo>/` dans le backend pour autoriser la connexion.
- Pour tests locaux où le backend reste en local, utilisez un tunnel public (ngrok, localtunnel) ou déployez temporairement le backend (Railway/Render/Heroku) pour que la version Pages puisse communiquer avec Socket.IO et l'API.

Actions typiques pour tester un déploiement GitHub Pages
1) Builder le web: `flutter build web --release --base-href "/<repo>/"` (Windows PowerShell/CLI).
2) Copier le contenu de `build/web` dans la branche `gh-pages` ou dans le dossier `docs/` de `main` et pousser.
3) Mettre `FRONTEND_URL` dans le backend sur l'URL Pages et redémarrer le serveur backend pour autoriser CORS/Socket.IO.

Exemples concrets dans le repo
- Gestion des logs requêtes: `backend/request_log.txt` et middleware de logging dans `server.js`.
- Calcul de complétude de profil: fonction `calculateProfileCompleteness` définie dans `server.js` (à réutiliser si besoin).
- Uploads/images: conversion en `.webp`, tailles cibles (profil: 200x200, documents: max width 800) — conserver.

Points de friction connus
- Backend exige `JWT_SECRET` (sinon exit), et PostgreSQL opérationnel — on ne peut pas déployer l'API sur Pages (Pages = frontend statique uniquement).
- Si le frontend utilise `flutter_secure_storage` ou autres plugins natifs, les fonctionnalités native-only ne fonctionneront pas sur web.

Où lire pour démarrer
- `backend/server.js`, `backend/db.config.js`, `schema.sql`, `backend/middleware/authMiddleware.js`, `frontend/pubspec.yaml`, `frontend/web/index.html`.

Si une section est incomplète ou si vous voulez un exemple de workflow GitHub Actions pour builder et déployer `build/web` sur `gh-pages`, dites-le et je fournirai un fichier `/.github/workflows/deploy_flutter_web.yml` prêt à l'emploi.
## Contexte rapide

Repository d'une application « Proxi-Services » composée d'un backend Node/Express (dossier `backend/`) et d'un frontend Flutter (dossier `frontend/`). Le backend expose REST + Socket.IO et utilise PostgreSQL via `pg`. Les profils utilisateurs sont répartis en tables distinctes par rôle : `client_profiles`, `artisan_profiles`, `commercant_profiles`.

## Objectif d'un agent

Rendre des modifications sûres et ciblées : ajouter/corriger des endpoints, réparer des régressions, améliorer validation et manipulation d'images, ou corriger des intégrations DB/SMTP. Préserver la logique métier (rôles/autorisation, calcul de complétude de profil, événements Socket.IO).

## Règles importantes pour les modifications

- Ne pas changer la structure des tables sans vérifier `schema.sql` et `backend/db.config.js`.
- Respecter l'autorisation par rôle : `authenticateToken` et `authorizeRole` (voir `backend/middleware/authMiddleware.js`). Les routes utilisent `req.user.id` et `req.user.role` provenant du JWT.
- Les URLs d'uploads (photos/documents) sont servies depuis `/uploads` et les images sont traitées avec `sharp` (conversion en .webp). Préserver cette logique si vous modifiez le téléversement (voir `server.js`, `portfolioController.js`).

## Points d'intégration critiques

- Base de données PostgreSQL : configuration via variables d'environnement (voir `backend/db.config.js`). Variables attendues : DB_USER, DB_HOST, DB_DATABASE, DB_PASSWORD, DB_PORT.
- JWT secret obligatoire : `JWT_SECRET` (server refuse de démarrer si absent).
- SMTP pour réinitialisation de mot de passe : `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` (voir `backend/services/emailService.js` et `service_email_password_reset.js`).
- Frontend attendu sur `process.env.FRONTEND_URL` (par défaut http://localhost:5173) pour CORS/Socket.IO.

## Commandes dev & scripts

- Backend : lancer en développement

  - Depuis `backend/` : `npm install` puis `npm start` (script `start` lance `node server.js`).
  - Lint : `npm run lint` (Windows: `ESLINT_USE_FLAT_CONFIG` est désactivé dans le script). 

- DB : un fichier `schema.sql` et `database.sqlite` existent ; cependant le backend s'attend à PostgreSQL. Avant d'ajouter des migrations, vérifier les scripts `init_db.bat` et `reset_database.bat` à la racine `backend/`.

## Patterns et conventions du code

- Rôles & profils : trois rôles principaux `client`, `artisan`, `commercant`. Les routes et controllers séparent nettement la logique par rôle (ex : `POST /api/profile` crée la ligne dans la table correspondante). Exemple : `artisanController.getArtisan`, `portfolioController.addPortfolioItem`.
- Socket.IO : géré dans `server.js`. Les événements importants : `user connected`, `chat message`, `demand-status-updated`, `update online users`. Le backend stocke une map `connectedUsers` pour mapper userId -> socketId.
- Validation : `express-validator` est utilisé systématiquement dans routes pour valider paramètres et corps.
- Téléversements : `multer.memoryStorage()` + `sharp` pour traitement en mémoire puis écriture vers `uploads/` (converti en `.webp`).

## Exemples concrets à réutiliser

- Vérifier rôle avant modifications :

  if (req.user.id !== parseInt(req.params.artisanId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

- Traitement d'image (`server.js` upload/photo) : conserver la conversion en `.webp` et la taille cible (profil: 200x200, documents: max width 800).

## Ce qu'il est déconseillé de faire

- Ne pas modifier le format JWT ou l'expiration sans mettre à jour tous les endroits qui signent/attendent le token (`routes/authRoutes.js`).
- Ne pas renommer les colonnes de la DB dans le code sans mettre à jour `schema.sql` et les requêtes SQL.

## Emplacements clés à lire avant de modifier

- backend/server.js (point d'entrée, Socket.IO, routes principales)
- backend/db.config.js (connexion DB)
- backend/routes/authRoutes.js (authentification + génération JWT)
- backend/middleware/authMiddleware.js (auth/autorisation)
- backend/services/emailService.js (SMTP / reset password)
- backend/controllers/* (services, portfolio, artisan)
- schema.sql (structure DB)

## Si tu as besoin d'exécuter des tests ou debug

- Le repo ne contient pas de suite de tests automatisés. Pour vérifier localement :
  - configurer les variables d'environnement dans un `.env` (DB, JWT_SECRET, SMTP_*)
  - démarrer PostgreSQL et exécuter `schema.sql` pour créer les tables
  - depuis `backend/` : `npm install` puis `npm start` et utiliser Postman ou curl pour tester les endpoints

## Demande de retour

Si une section est ambiguë ou manque d'exemples (ex : structure exacte des tables dans `schema.sql` ou commandes d'initialisation DB Windows), dis-moi quelles parties tu veux que je détaille et j'ajouterai un court extrait ou commande.
