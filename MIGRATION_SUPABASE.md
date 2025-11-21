# Migration vers une architecture pure Supabase

Ce projet contient tous les fichiers nécessaires pour migrer votre backend Node.js vers une architecture pure Supabase, éliminant la dépendance à Render (ou toute autre plateforme de backend).

## Fichiers créés

### Fonctions Edge Supabase (`supabase/functions/`)
- `signup.ts` - Gestion de l'inscription des utilisateurs
- `signin.ts` - Gestion de la connexion des utilisateurs  
- `artisans.ts` - Récupération des artisans
- `reviews.ts` - Gestion des avis (ajout et lecture)

### Politiques de sécurité (`supabase/`)
- `rls_policies.sql` - Politiques Row Level Security pour sécuriser l'accès aux données

### Fichiers Flutter (`frontend/lib/services/`)
- `supabase_service.dart` - Service pour interagir avec Supabase
- `api_constants.dart` - Constantes de connexion à Supabase (mis à jour)

## Étapes de déploiement

### 1. Préparation de l'environnement
```bash
npm install -g supabase
```

### 2. Connexion à votre projet Supabase
```bash
supabase login
supabase link --project-ref [VOTRE_PROJECT_REF]
```

Le Project Ref se trouve dans votre tableau de bord Supabase, dans Settings > Project Settings.

### 3. Déploiement des fonctions Edge
```bash
cd supabase
supabase functions deploy
```

### 4. Mise en place des politiques RLS
1. Allez dans votre tableau de bord Supabase
2. Allez dans l'onglet SQL
3. Copiez-collez le contenu du fichier `rls_policies.sql`
4. Exécutez la requête

### 5. Mise à jour du frontend Flutter
1. Dans votre projet Flutter, exécutez :
```bash
flutter pub get
```

2. Remplacez l'utilisation de `ApiService` par `SupabaseService` dans vos widgets et contrôleurs

## Adaptation du code Flutter

Voici un exemple de migration d'un service existant vers le nouveau service Supabase :

### Avant (avec ApiService) :
```dart
final artisans = await artisanService.getArtisans();
```

### Après (avec SupabaseService) :
```dart
final supabaseService = SupabaseService();
final artisans = await supabaseService.getArtisans();
```

## Points importants

1. L'authentification passe maintenant par Supabase Auth (email/password)
2. Les permissions sont gérées par les politiques RLS
3. Les appels API sont maintenant directs vers les fonctions Edge Supabase
4. Toutes vos données existent déjà dans Supabase

## Migration des données existantes

Si vous avez des données dans votre backend Render expiré, elles sont probablement déjà dans votre base Supabase. Vérifiez dans l'onglet Database de votre tableau de bord Supabase.

## Support des fonctionnalités

Les fonctions Edge créées supportent :
- ✅ Inscription et connexion des utilisateurs
- ✅ Récupération des artisans
- ✅ Gestion des avis (ajout et lecture)
- ✅ Sécurité via RLS

Pour ajouter d'autres fonctionnalités, créez de nouvelles fonctions Edge similaires dans le répertoire `supabase/functions/`.

## Tests

Après déploiement, testez toutes les fonctionnalités critiques de votre application pour vous assurer que tout fonctionne correctement avec la nouvelle architecture.

## Avantages de cette migration

- ✅ Plus de dépendance à une plateforme backend tierce
- ✅ Solution gratuite à long terme (dans les limites de Supabase)
- ✅ Accès continu à vos données
- ✅ Meilleure intégration avec la base de données
- ✅ Moins de complexité d'infrastructure