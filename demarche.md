# Feuille de Route : Système d'Affiliation "Démacheur"

Ce document détaille les étapes nécessaires à la mise en place du système de parrainage et de commission pour les "démacheurs".

---

### Phase 1 : Socle du Parrainage (La Base)

*Objectif : Permettre de savoir qui a parrainé qui lors de l'inscription.*

- [x] **Backend :** Ajouter une colonne `referral_code` à la table `users` pour stocker le code de l'utilisateur qui a parrainé.
- [x] **Backend :** Modifier la route d'inscription (`/api/auth/register`) pour qu'elle accepte un `referralCode` optionnel et l'enregistre.
- [x] **Frontend :** Ajouter un champ "Code de parrainage (optionnel)" sur l'écran d'inscription (`register_screen.dart`).

---

### Phase 2 : Abonnement "Démacheur"

*Objectif : Permettre à un utilisateur de devenir un "démacheur" via un abonnement.*

- [x] **Backend :** Créer une table `demacheur_subscriptions` (user_id, expires_at, status) pour gérer les abonnements des démacheurs.
- [x] **Backend :** Créer une route d'API pour s'abonner (ex: `/api/demacheur/subscribe`) qui intègre le système de paiement.
- [x] **Backend :** Créer une route d'API pour vérifier le statut de l'abonnement d'un utilisateur.
- [x] **Frontend :** Créer un nouvel écran "Devenir Démacheur" accessible depuis les paramètres.
- [x] **Frontend :** Sur cet écran, afficher le statut de l'abonnement et un bouton "S'abonner" / "Gérer l'abonnement".
- [ ] **Frontend :** Intégrer le tunnel de paiement pour cet abonnement.

---

### Phase 3 : Gestion des Commissions

*Objectif : Calculer et attribuer automatiquement les commissions.*

- [ ] **Backend :** Créer une table `earnings` (demacheur_id, referred_user_id, amount, status) pour tracer les gains.
- [ ] **Backend :** Mettre en place la logique métier : quand un utilisateur parrainé paie son abonnement de 5000f, insérer une nouvelle ligne de 1000f dans la table `earnings` pour son parrain.
- [ ] **Frontend :** Dans l'écran "Démacheur", créer un tableau de bord affichant l'historique des parrainages et le total des gains.

---

### Phase 4 : Paiement des Démacheurs (Le plus complexe)

*Objectif : Permettre aux démacheurs de récupérer leurs gains.*

- [ ] **Analyse & Conception :** Définir le processus de paiement (manuel depuis un panel admin, semi-automatique, etc.).
- [ ] **Backend :** Créer une route d'API pour qu'un démacheur puisse demander un paiement.
- [ ] **Backend (Admin) :** Créer une interface dans le panel admin pour voir et approuver les demandes de paiement.
- [ ] **Frontend :** Ajouter un bouton "Demander un paiement" dans le tableau de bord du démacheur.
