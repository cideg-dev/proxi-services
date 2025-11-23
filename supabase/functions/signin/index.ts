import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT } from 'https://deno.land/x/djwt@v3.0.1/mod.ts'

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
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
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  // D'abord, authentifier l'utilisateur avec Supabase
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (authError) {
    return new Response(JSON.stringify({ error: authError.message }), {
      status: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  // Récupérer les informations utilisateur de la table personnalisée
  const { data: userData, error: userError } = await supabase
    .from('users')
    .select('id, email, role')
    .eq('email', email)
    .single()

  if (userError || !userData) {
    return new Response(JSON.stringify({ error: 'Utilisateur non trouvé dans la base de données' }), {
      status: 404,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  // Vérifier que l'utilisateur n'est pas bloqué
  if (userData.is_blocked) {
    return new Response(JSON.stringify({ error: 'Votre compte a été bloqué.' }), {
      status: 401,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  // Générer des tokens personnalisés comme dans le backend local
  // Utiliser le secret JWT de Supabase ou un secret personnalisé
  const jwtSecret = Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_SECRET')
  if (!jwtSecret) {
    return new Response(JSON.stringify({ error: 'Clé JWT manquante' }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  // Générer le token d'accès
  const tokenPayload = {
    id: userData.id,
    email: userData.email,
    role: userData.role,
    exp: Math.floor(Date.now() / 1000) + (15 * 60), // 15 minutes
  }

  const token = await new SignJWT(tokenPayload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(tokenPayload.exp * 1000)
    .sign(new TextEncoder().encode(jwtSecret))

  // Générer le refresh token
  const refreshTokenPayload = {
    id: userData.id,
    email: userData.email,
    role: userData.role,
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60), // 7 jours
  }

  const refreshToken = await new SignJWT(refreshTokenPayload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(refreshTokenPayload.exp * 1000)
    .sign(new TextEncoder().encode(Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_REFRESH_SECRET') || 'fallback_refresh_secret'))

  // Mettre à jour le last_seen
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
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    }
  })
})