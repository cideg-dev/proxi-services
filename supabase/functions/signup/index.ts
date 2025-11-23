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
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const body = await req.json()
  const { email, password, role, profileData } = body

  // Validation des données
  if (!email || !password || !role) {
    return new Response(JSON.stringify({ error: 'Missing required fields' }), {
      status: 400,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }

  try {
    // 1. Créer l'utilisateur dans Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin
      .createUser({
        email: email,
        password: password,
        email_confirm: true,
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

    // 2. Générer un ID INTEGER et créer l'utilisateur dans la table users
    const { data: maxIdResult } = await supabase
      .from('users')
      .select('id')
      .order('id', { ascending: false })
      .limit(1)

    const nextId = maxIdResult && maxIdResult.length > 0 ? maxIdResult[0].id + 1 : 1

    const { data: user, error: dbError } = await supabase
      .from('users')
      .insert([{ 
        id: nextId,
        email: email,
        role: role,
        password: ''
      }])
      .select()
      .single()

    if (dbError) {
      // Nettoyer l'utilisateur auth en cas d'erreur
      await supabase.auth.admin.deleteUser(authData.user.id)
      return new Response(JSON.stringify({ error: dbError.message }), {
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      })
    }

    // 3. Insérer l'entrée dans la table de correspondance
    const { error: mappingError } = await supabase
      .from('user_id_mapping')
      .insert({
        supabase_user_id: authData.user.id,
        app_user_id: nextId
      })

    if (mappingError) {
      // Nettoyer l'utilisateur et la table users en cas d'erreur de mapping
      await supabase.from('users').delete().eq('id', nextId)
      await supabase.auth.admin.deleteUser(authData.user.id)
      return new Response(JSON.stringify({ error: mappingError.message }), {
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      })
    }

    // Créer le profil utilisateur selon le rôle
    let profileResult
    if (role === 'client') {
      profileResult = await supabase
        .from('client_profiles')
        .insert([{ user_id: nextId, ...profileData }])
    } else if (role === 'artisan') {
      profileResult = await supabase
        .from('artisan_profiles')
        .insert([{ user_id: nextId, ...profileData }])
    } else if (role === 'commercant') {
      profileResult = await supabase
        .from('commercant_profiles')
        .insert([{ user_id: nextId, ...profileData }])
    }

    if (profileResult.error) {
      return new Response(JSON.stringify({ error: profileResult.error.message }), {
        status: 500,
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
      id: nextId,
      email: email,
      role: role,
      exp: Math.floor(Date.now() / 1000) + (15 * 60), // 15 minutes
    }

    const token = await new SignJWT(tokenPayload)
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime(tokenPayload.exp * 1000)
      .sign(new TextEncoder().encode(jwtSecret))

    // Générer le refresh token
    const refreshTokenPayload = {
      id: nextId,
      email: email,
      role: role,
      exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60), // 7 jours
    }

    const refreshToken = await new SignJWT(refreshTokenPayload)
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime(refreshTokenPayload.exp * 1000)
      .sign(new TextEncoder().encode(Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_REFRESH_SECRET') || 'fallback_refresh_secret'))

    return new Response(JSON.stringify({
      token,
      refreshToken,
      user: {
        id: nextId,
        email: email,
        role: role
      }
    }), {
      status: 201,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }
    })
  }
})