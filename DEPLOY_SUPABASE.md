# Configuration Supabase

## URL de connexion

L'application Proxi-Services est maintenant correctement configurée pour fonctionner avec Supabase.

### Format de l'URL de connexion

```
postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-1-eu-west-3.pooler.supabase.com:5432/postgres
```

### Configuration SSL

Pour établir une connexion réussie avec Supabase, la configuration SSL suivante est requise :

```javascript
ssl: {
  rejectUnauthorized: false  // Important pour les connexions Supabase
}
```

### Points de configuration critiques

1. Le hostname correct est : `aws-1-eu-west-3.pooler.supabase.com`
2. Le format d'utilisateur est : `postgres.[PROJECT_REF]` (pas seulement `postgres`)
3. La configuration SSL avec `rejectUnauthorized: false` est essentielle
4. Utiliser le port 5432 pour les connexions directes (non poolées)

## Test de connexion

Les tests de connexion doivent être effectués en utilisant la même configuration SSL que dans `db.config.js` pour assurer la cohérence.