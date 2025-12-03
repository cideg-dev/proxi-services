# Vérification et dépannage du problème CORS et JWT

## Problèmes identifiés

1. Erreur CORS: La requête préflight OPTIONS échoue
2. Les variables d'environnement sont correctement configurées
3. La fonction est déployée mais ne répond pas correctement

## Étapes de dépannage

### 1. Vérification de la configuration CORS dans la fonction

Assurez-vous que la fonction signin gère correctement les requêtes OPTIONS.
Voici le code correct à utiliser dans supabase/functions/signin/index.ts :

```typescript
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT } from 'https://deno.land/x/djwt@v3.0.1/mod.ts'

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*', // Pour le développement, utilisez votre domaine exact en production
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept',
  }

  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Le reste du code de la fonction...
})
```

### 2. Redéploiement forcé

Redéployez la fonction avec la bonne gestion CORS :
```
supabase functions deploy signin --project-ref ufeqnnbokyalwjfskhmw
```

### 3. Vérification dans le dashboard Supabase

Consultez les logs de la fonction :
1. Allez sur https://supabase.com/dashboard/project/ufeqnnbokyalwjfskhmw/functions
2. Cliquez sur la fonction "signin"
3. Accédez à l'onglet "Logs" 
4. Essayez de vous connecter et regardez les erreurs dans les logs

### 4. Test de la fonction directe

Testez la fonction directement avec curl ou un outil API :
```
curl -X POST https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/signin \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"votre@email.com","password":"votre_mot_de_passe"}'
```

### 5. Configuration du dashboard Supabase

Allez dans Settings > API et vérifiez si CORS est configuré pour accepter votre origine GitHub Pages.