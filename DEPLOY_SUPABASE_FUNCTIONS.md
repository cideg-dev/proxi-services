# Déploiement des fonctions Supabase

## Problème identifié

Votre application rencontre une erreur CORS et une erreur de délai lors de la tentative de connexion à Supabase. Cela indique que les fonctions Edge Supabase n'ont pas été déployées dans votre projet.

## Étapes de déploiement

### 1. Installation de l'interface de ligne de commande Supabase

```bash
npm install -g supabase
```

### 2. Connexion à votre projet

```bash
supabase login
supabase link --project-ref ufeqnnbokyalwjfskhmw
```

### 3. Déploiement des fonctions

```bash
supabase functions deploy --project-ref ufeqnnbokyalwjfskhmw
```

Ou pour déployer une fonction spécifique :

```bash
supabase functions deploy signup --project-ref ufeqnnbokyalwjfskhmw
supabase functions deploy signin --project-ref ufeqnnbokyalwjfskhmw
supabase functions deploy logout --project-ref ufeqnnbokyalwjfskhmw
# Déployez toutes les autres fonctions nécessaires
```

### 4. Configuration des variables d'environnement

Après le déploiement, vous devez configurer les variables d'environnement dans votre projet Supabase :

1. Allez dans votre tableau de bord Supabase
2. Allez dans Settings > Environment Variables
3. Ajoutez les variables suivantes :
   - `SUPABASE_URL`: https://ufeqnnbokyalwjfskhmw.supabase.co
   - `SUPABASE_ANON_KEY`: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmZXFubmJva3lhbHdqZnNraG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NTg0NzAsImV4cCI6MjA3OTEzNDQ3MH0.R9hzOusA0ESMwCrZlmrNTFNgbj4c5YYpexPA4UksLcs
   - `SUPABASE_SERVICE_ROLE_KEY`: [Votre clé service_role - disponible dans Project Settings > API]
   - `SUPABASE_JWT_SECRET`: [Votre secret JWT - disponible dans Project Settings > API]

### 5. Configuration CORS dans votre projet Supabase

1. Allez dans votre tableau de bord Supabase
2. Allez dans Settings > API
3. Dans Configuration CORS, assurez-vous que l'origine `https://cideg-dev.github.io` est autorisée (ou utilisez `*` pour autoriser toutes les origines pendant le développement)

### 6. Vérification du déploiement

Après le déploiement, vos fonctions seront accessibles à l'URL :
```
https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/{function-name}
```

## Script de déploiement automatique

Un script PowerShell est disponible dans le projet :

```powershell
.\deploy_supabase_functions.bat
```

Ou :

```powershell
.\deploy_supabase_functions_corrected.bat
```

## Dépannage

Si vous continuez à rencontrer des erreurs après le déploiement :

1. Vérifiez que toutes les fonctions sont déployées dans votre tableau de bord Supabase
2. Vérifiez que les journaux des fonctions ne contiennent pas d'erreurs
3. Assurez-vous que les variables d'environnement sont correctement configurées
4. Vérifiez que les politiques RLS sont correctement mises en place dans votre base de données