import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createOptionsResponse, getCorsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return createOptionsResponse(req);
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  try {
    const origin = req.headers.get("Origin");
    const corsHeaders = getCorsHeaders(origin);

    // D'abord, récupérons les utilisateurs avec le rôle artisan
    const { data: usersData, error: usersError } = await supabase
      .from('users')
      .select('id, role, email')
      .eq('role', 'artisan')

    if (usersError) {
      console.error('Erreur lors de la récupération des utilisateurs artisans:', usersError)
      return new Response(JSON.stringify({ error: usersError.message }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
          'Access-Control-Allow-Credentials': 'true',
        }
      })
    }

    // Ensuite, pour chaque utilisateur artisan, récupérons son profil
    const artisansWithProfiles = await Promise.all(usersData.map(async (user) => {
      const { data: profileData, error: profileError } = await supabase
        .from('artisan_profiles')
        .select('nom_complet, specialite, location, photo_url')
        .eq('user_id', user.id)
        .single()

      if (profileError) {
        console.warn('Erreur lors de la récupération du profil pour l\'artisan', user.id, ':', profileError)
        // Retourner l'utilisateur avec un profil vide s'il n'existe pas
        return {
          id: user.id,
          role: user.role,
          email: user.email,
          nom_complet: null,
          specialite: null,
          location: null,
          photo_url: null
        }
      }

      return {
        id: user.id,
        role: user.role,
        email: user.email,
        ...profileData
      }
    }))

    return new Response(JSON.stringify(artisansWithProfiles), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
        'Access-Control-Allow-Credentials': 'true',
      }
    })
  } catch (error) {
    console.error('Erreur serveur lors de la récupération des artisans:', error)
    const origin = req.headers.get("Origin");
    const corsHeaders = getCorsHeaders(origin);

    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
        'Access-Control-Allow-Credentials': 'true',
      }
    })
  }
})