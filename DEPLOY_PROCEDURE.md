# Procédure de déploiement - Proxi-Services

Ce document explique comment déployer les corrections apportées au système Proxi-Services.

## Aperçu des modifications

### 1. Corrections des fonctions Supabase
- Correction de la fonction `artisans` pour résoudre l'erreur 500
- Utilisation d'une approche plus robuste pour les jointures avec artisan_profiles
- Mise à jour de la fonction pour gérer correctement les erreurs

### 2. Corrections de la structure de base de données
- Ajout de la table `user_id_mapping` qui était manquante
- Mise à jour des contraintes et des politiques de sécurité

## Prérequis

Avant de déployer, assurez-vous d'avoir :

- Supabase CLI installé : `npm install -g @supabase/cli`
- Éditeur VS Code avec l'extension Supabase
- Accès à votre projet Supabase
- Accès à vos plateformes de déploiement (Render, GitHub Pages, etc.)

## Étapes de déploiement

### Étape 1 : Déploiement des fonctions Supabase

1. Assurez-vous d'être connecté à Supabase CLI :
   ```
   supabase login
   ```

2. Lier votre projet local à votre projet Supabase :
   ```
   supabase link --project-ref <project-ref>
   ```
   (Remplacez `<project-ref>` par l'ID de votre projet Supabase)

3. Déployer les fonctions :
   ```
   supabase functions deploy artisans
   supabase functions deploy professionals
   supabase functions deploy signup
   supabase functions deploy signin
   supabase functions deploy reviews
   ```

### Étape 2 : Déploiement des migrations de base de données

1. Exécuter les migrations :
   ```
   supabase db push
   ```

### Étape 3 : Déploiement du frontend (Flutter)

1. Depuis le répertoire `frontend/`, exécuter :
   ```
   flutter build web
   ```

2. Déployer le build sur votre plateforme :
   - Pour GitHub Pages : le déploiement est automatique via GitHub Actions
   - Pour Render : configurez le dépôt Git pour un déploiement automatique

## Script de déploiement automatisé

Un script `deploy_all.bat` est fourni pour automatiser le déploiement :
- Exécutez-le en tant qu'administrateur
- Il déploie les fonctions et les migrations
- Vous devrez déployer le frontend manuellement

## Résolution des problèmes

### Si vous avez des erreurs de déploiement :

1. Vérifiez que vous êtes bien connecté à Supabase CLI
2. Assurez-vous que votre projet local est lié au projet distant
3. Vérifiez que vous avez les droits nécessaires

### Si les erreurs persistent :

1. Vérifiez les logs dans le tableau de bord Supabase
2. Consultez les logs des fonctions
3. Vérifiez que la structure de la base de données est correcte

## Rollback

Si vous devez revenir à une version antérieure :
1. Sauvegardez la base de données actuelle
2. Utilisez les anciennes versions des fonctions
3. Exécutez `supabase db reset` si nécessaire