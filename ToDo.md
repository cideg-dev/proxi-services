# ToDo - Projet Proxi-Services

Ce fichier suit les tâches de développement basées sur le cahier des charges. Les tâches cochées sont considérées comme terminées.

---

## Tâches Déjà Réalisées ✅

- [x] **Configuration & Démarrage :**
    - [x] Frontend : Rendre le chargement des variables d'environnement (`dotenv`) plus robuste.
    - [x] Frontend : Centraliser l'URL de l'API (`API_URL`) dans `ApiConstants`.
    - [x] Frontend : Remplacer les URLs codées en dur (ancien port 5000).
    - [x] Backend : Configurer le serveur pour qu'il serve l'application frontend compilée.
    - [x] Backend : Mettre en place un fichier `.env.example` pour la configuration.
- [x] **Affichage des Professionnels :**
    - [x] Backend : Modifier l'API pour que la liste des professionnels inclue les artisans ET les commerçants.
    - [x] Frontend : Mettre à jour l'écran d'accueil pour afficher la liste mixte des professionnels.
    - [x] Backend : Modifier l'API pour que l'écran de détail puisse charger les informations d'un artisan OU d'un commerçant.
    - [x] Frontend : Adapter l'écran de détail pour qu'il affiche les informations spécifiques à chaque rôle (artisan/commerçant).

---

## Phase 0 (Critique)

### ✅ Finaliser la configuration et le démarrage
- [x] Ajouter des scripts d'initialisation (PowerShell / npm) pour faciliter le lancement de l'environnement de développement local.
- [x] **Critère d'acceptation :** Un nouveau développeur peut cloner le projet et le lancer avec une seule commande.

### ✅ Améliorer l'expérience utilisateur (UX) pour l'inscription et la connexion
- [x] Afficher les erreurs serveur (400/500) de manière claire et conviviale pour l'utilisateur.
- [x] Ajouter une validation côté client avant l'envoi du formulaire (format de l'email, longueur du mot de passe).
- [x] Mettre en place un mécanisme de "retry" (nouvel essai) en cas d'échec de connexion réseau.
- [x] **Tests à faire :** Scénario normal, mauvais mot de passe, email déjà utilisé.

### ☐ Gérer les URLs d'images et le téléchargement
- [x] Côté serveur, générer des miniatures (thumbnails) avec `sharp` pour optimiser le chargement.
- [x] Ajouter un en-tête `Cache-Control` pour que le navigateur mette en cache les images.
- [x] **Critère d'acceptation :** Les images sont converties en `.webp`, accessibles via une URL complète, et s'affichent sans erreur 404.

### ✅ Protéger les routes et gérer les autorisations
- [x] S'assurer que TOUTES les routes sensibles utilisent `authenticateToken` et `authorizeRole`.
- [x] Ajouter des tests pour les autorisations (ex: un client ne peut pas modifier le profil d'un artisan).

---

## Phase 1 (Haute Priorité)

### ✅ Workflow complet des "demandes" de service
- [x] Ajouter la possibilité pour un client d'annuler une demande (`DELETE /api/demandes/:id`). (Backend terminé)
- [x] Créer une route pour voir les détails d'une seule demande (`GET /api/demandes/:id`).
- [x] **Frontend :** Créer les écrans pour l'historique client et l'inbox artisan, permettant la gestion des demandes (annulation, acceptation, refus).
- [x] **Frontend :** Afficher des notifications (toast) quand le statut d'une demande change.
- [x] **Critère d'acceptation :** Un client peut créer une demande, l'artisan la reçoit, l'accepte, et le client voit la mise à jour en temps réel.

### ✅ Vérification des documents (KYC) pour les professionnels
- [x] Ajouter une notification par email quand un document est téléversé.
- [x] **Backend :** Créer les routes pour l'administrateur (`GET /api/admin/verifications`, `PUT /api/admin/verifications/:id`).
- [x] **Base de données :** Ajouter une colonne `verification_status` aux profils.
- [x] **Frontend :** Créer un panel administrateur pour lister les vérifications, voir les documents, et les accepter/rejeter.
- [x] **Critère d'acceptation :** Le statut d'un professionnel passe à "en attente" après l'upload, et un admin peut le marquer comme "vérifié".

---

## Phase 2 (Moyenne Priorité)

### ✅ Améliorer la gestion des favoris
- [x] Permettre de trier ou filtrer les favoris (par distance, par exemple).
- [x] **Frontend :** Ajouter un bouton "favori" sur les listes et l'écran de détail.

### ✅ Améliorer la messagerie
- [x] Ajouter un accusé de réception pour les messages (envoyé / lu).
- [x] **Base de données :** Ajouter un statut "delivered/read" à la table des messages.
- [x] Paginer le chargement de l'historique des messages pour ne pas tout charger d'un coup.
- [x] **Frontend :** Afficher les statuts "envoyé/lu" (par exemple, avec des coches ✓✓).

### ✅ Créer un tableau de bord administrateur
- [x] Gestion des utilisateurs, des vérifications, des signalements.
- [x] Mettre en place un système de logs d'audit.

---

## Phase 3 (Optionnel)

### ✅ Mettre en place les paiements / abonnements
- [x] Intégrer un service de paiement comme kkiapay.
- [x] Créer les écrans pour s'abonner, se désabonner, et voir les factures.

---

## Tâches Techniques

### ☐ Mettre en place des tests et une intégration continue (CI)
- [ ] **Backend :** Écrire des tests unitaires pour les `controllers` et `services`.
- [ ] **Frontend :** Écrire des tests de widgets.
- [ ] **CI (GitHub Actions) :** Créer un workflow qui installe les dépendances, lance les linters et les tests automatiquement.

---

## Nouvelles Fonctionnalités Suggérées

### Axe 1 : Confiance et Sécurité (Impact Élevé)
- [ ] **Vérification d'Identité des Artisans :** Intégrer un service de vérification de documents d'identité pour afficher un badge "Identité Vérifiée" sur les profils.
- [ ] **Paiement Sécurisé / Escrow :** Mettre en place un système où le paiement du client est conservé par la plateforme et n'est versé à l'artisan qu'après confirmation de la fin de la prestation.

### Axe 2 : Recherche et Découverte (Impact Élevé)
- [ ] **Filtres de Recherche Avancés :** Ajouter des filtres par disponibilité, tarif, distance, et note moyenne.
- [ ] **Demande de Devis Multiple :** Permettre à un client de poster une demande de service et de recevoir des devis de plusieurs artisans.

### Axe 3 : Outils pour les Artisans (Impact Moyen)
- [ ] **Gestion de Calendrier et Prise de Rendez-vous :** Intégrer un calendrier de disponibilité pour les artisans avec possibilité de réservation directe par les clients.
- [ ] **Tableau de Bord de Statistiques :** Créer un dashboard pour les artisans avec des métriques (vues du profil, contacts, revenus, etc.).