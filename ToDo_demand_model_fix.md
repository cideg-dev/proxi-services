# TODO: Résoudre le problème de permission de demand_model.dart

## Objectif
Corriger le problème de permission Git sur `frontend/lib/models/demand_model.dart` et le commiter/pousser vers le repository pour l'équipe de test en ligne.

## Erreur Actuelle
```
error: read error while indexing frontend/lib/models/demand_model.dart: Permission denied
error: frontend/lib/models/demand_model.dart: failed to insert into database
error: unable to index file 'frontend/lib/models/demand_model.dart'
fatal: adding files failed
```

## Plan d'Action

### Étape 1: Vérifier le fichier actuel
- [ ] Vérifier que le fichier existe et fonctionne localement
- [ ] Lire le contenu du fichier pour sauvegarde

### Étape 2: Retirer de .gitignore
- [ ] Éditer `.gitignore` pour retirer `frontend/lib/models/demand_model.dart`
- [ ] Sauvegarder les modifications

### Étape 3: Corriger les permissions (Windows)
- [ ] Vérifier les permissions du fichier avec PowerShell
- [ ] Appliquer les permissions appropriées si nécessaire
- [ ] Option A: `icacls` pour modifier les permissions
- [ ] Option B: Copier le fichier vers un nouveau nom temporaire

### Étape 4: Alternative - Recréer le fichier
- [ ] Copier le contenu du fichier actuel
- [ ] Supprimer l'ancien fichier
- [ ] Créer un nouveau fichier avec le même contenu
- [ ] Vérifier que le nouveau fichier n'a pas de problèmes de permission

### Étape 5: Ajouter à Git
- [ ] Exécuter `git add frontend/lib/models/demand_model.dart`
- [ ] Vérifier avec `git status` que le fichier est staged
- [ ] Si erreur, essayer `git add -f frontend/lib/models/demand_model.dart`

### Étape 6: Commit et Push
- [ ] Commiter avec message: "fix: Add demand_model.dart (permission issue resolved)"
- [ ] Pousser vers le repository
- [ ] Vérifier sur GitHub que le fichier est bien présent

## Commandes à Exécuter

```bash
# 1. Vérifier le fichier
type frontend\lib\models\demand_model.dart

# 2. Retirer de .gitignore (manuel ou via commande)
# Éditer .gitignore et supprimer la ligne

# 3. Vérifier permissions (Windows PowerShell)
icacls frontend\lib\models\demand_model.dart

# 4. Si recréation nécessaire
copy frontend\lib\models\demand_model.dart frontend\lib\models\demand_model_backup.dart
del frontend\lib\models\demand_model.dart
copy frontend\lib\models\demand_model_backup.dart frontend\lib\models\demand_model.dart

# 5. Git add
git add frontend/lib/models/demand_model.dart
git status

# 6. Commit et push
git commit -m "fix: Add demand_model.dart (permission issue resolved)"
git push
```

## Statut
- [ ] Problème résolu
- [ ] Fichier commité
- [ ] Fichier poussé vers GitHub
- [ ] Vérifié en ligne
