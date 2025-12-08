import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createOptionsResponse, getCorsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return createOptionsResponse(req);
  }

  if (req.method !== 'POST') {
    const origin = req.headers.get("Origin");
    const corsHeaders = getCorsHeaders(origin);

    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
        'Access-Control-Allow-Credentials': 'true',
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
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
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
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
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
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
      }
    })
  }

  // Vérifier que l'utilisateur n'est pas bloqué
  if (userData.is_blocked) {
    return new Response(JSON.stringify({ error: 'Votre compte a été bloqué.' }), {
      status: 401,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
      }
    })
  }

  // Générer des tokens personnalisés comme dans le backend local
  // Pour cette version, utilisons les tokens fournis par Supabase
  // Plutôt que de générer nos propres tokens JWT personnalisés
  const token = authData.session?.access_token;
  const refreshToken = authData.session?.refresh_token;

  // Si les tokens n'existent pas, c'est une erreur
  if (!token) {
    return new Response(JSON.stringify({ error: 'Impossible de générer le token d\'accès' }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
      }
    })
  }

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
      'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
      'Access-Control-Allow-Credentials': 'true',
    }
  })
})