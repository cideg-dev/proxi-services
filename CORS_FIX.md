# Solution pour le problème CORS avec Supabase Functions

## Problème identifié

Votre application rencontre toujours des erreurs CORS malgré le déploiement des fonctions et la configuration des variables d'environnement.

```
Access to fetch at 'https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/signin' from origin 'https://cideg-dev.github.io' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: It does not have HTTP ok status.
```

## Solutions possibles

### Solution 1 : Configuration CORS dans le projet Supabase

1. Allez dans votre dashboard Supabase : https://supabase.com/dashboard/project/ufeqnnbokyalwjfskhmw/settings/api

2. Dans la section "API", cherchez la configuration CORS

3. Ajoutez `https://cideg-dev.github.io` (ou `*` pour développement) dans les origines autorisées

### Solution 2 : Mise à jour des fonctions Supabase avec une gestion CORS améliorée

Votre fonction signin devrait inclure une gestion des requêtes préflight plus robuste :

```typescript
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT } from 'https://deno.land/x/djwt@v3.0.1/mod.ts'

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Client-Info',
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

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  const body = await req.json()
  const { email, password } = body

  if (!email || !password) {
    return new Response(JSON.stringify({ error: 'Email and password required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Authentification avec Supabase
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (authError) {
    return new Response(JSON.stringify({ error: authError.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Récupération des informations utilisateur
  const { data: userData, error: userError } = await supabase
    .from('users')
    .select('id, email, role')
    .eq('email', email)
    .single()

  if (userError || !userData) {
    return new Response(JSON.stringify({ error: 'Utilisateur non trouvé dans la base de données' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Vérification du blocage de l'utilisateur
  if (userData.is_blocked) {
    return new Response(JSON.stringify({ error: 'Votre compte a été bloqué.' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Vérification de la clé JWT
  const jwtSecret = Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_SECRET')
  if (!jwtSecret) {
    return new Response(JSON.stringify({ error: 'Clé JWT manquante' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Génération des tokens
  const tokenPayload = {
    id: userData.id,
    email: userData.email,
    role: userData.role,
    exp: Math.floor(Date.now() / 1000) + (15 * 60),
  }

  const token = await new SignJWT(tokenPayload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(tokenPayload.exp * 1000)
    .sign(new TextEncoder().encode(jwtSecret))

  const refreshTokenPayload = {
    id: userData.id,
    email: userData.email,
    role: userData.role,
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60),
  }

  const refreshToken = await new SignJWT(refreshTokenPayload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(refreshTokenPayload.exp * 1000)
    .sign(new TextEncoder().encode(Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_REFRESH_SECRET') || 'fallback_refresh_secret'))

  // Mise à jour du last_seen
  await supabase
    .from('users')
    .update({ last_seen: new Date().toISOString() })
    .eq('id', userData.id)

  return new Response(JSON.stringify({
    token,
    refreshToken,
    user: {
      id: userData.id,
      email: userData.email,
      role: userData.role
    }
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
```

### Solution 3 : Redéploiement des fonctions avec la configuration mise à jour

Après avoir mis à jour les fonctions avec une gestion CORS améliorée, redéployez-les :

```
.\deploy_supabase_functions_complete.bat
```

### Solution 4 : Configuration des headers de requête dans l'application Flutter

Dans vos requêtes API, assurez-vous d'inclure les headers appropriés :

```dart
final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Info': 'flutter/1.0', // En-tête supplémentaire qui peut aider
  },
  body: body,
);
```

### Solution 5 : Vérification des logs des fonctions

Consultez les logs des fonctions dans votre dashboard Supabase pour identifier d'éventuelles erreurs de runtime qui pourraient causer l'échec des requêtes préflight.