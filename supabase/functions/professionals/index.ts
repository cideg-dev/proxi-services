import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  try {
    // Cette requête récupère les artisans et commercants avec leurs profils
    // Utilisons d'abord une requête simple pour éviter les problèmes de jointure
    const { data: usersData, error: usersError } = await supabase
      .from('users')
      .select('id, role')
      .in('role', ['artisan', 'commercant'])
      .limit(10)
      .returns<any[]>()

    if (usersError) {
      console.error('Erreur lors de la récupération des utilisateurs:', usersError)
      return new Response(JSON.stringify({ message: "Erreur serveur lors de la récupération des professionnels mis en avant" }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      })
    }

    // Récupérons les données détaillées pour chaque utilisateur
    const resultsWithDetails = await Promise.all(usersData.map(async (user) => {
      let profileData = {};

      if (user.role === 'artisan') {
        // Récupérer les détails du profil artisan
        const { data: artisanProfile, error: profileError } = await supabase
          .from('artisan_profiles')
          .select('nom_complet, specialite, description, photo_url, location')
          .eq('user_id', user.id)
          .single()
          .returns<any[]>()

        if (!profileError && artisanProfile) {
          profileData = {
            nom: artisanProfile.nom_complet,
            specialite: artisanProfile.specialite,
            description: artisanProfile.description,
            photo_url: artisanProfile.photo_url,
            location: artisanProfile.location,
          };
        }
      } else if (user.role === 'commercant') {
        // Récupérer les détails du profil commerçant
        const { data: commercantProfile, error: profileError } = await supabase
          .from('commercant_profiles')
          .select('nom_entreprise, type_commerce, description, photo_url, location')
          .eq('user_id', user.id)
          .single()
          .returns<any[]>()

        if (!profileError && commercantProfile) {
          profileData = {
            nom: commercantProfile.nom_entreprise,
            specialite: commercantProfile.type_commerce,
            description: commercantProfile.description,
            photo_url: commercantProfile.photo_url,
            location: commercantProfile.location,
          };
        }
      }

      // Récupérer la note moyenne - utiliser artisan_id pour les artisans, mais pour les commerçants il se peut qu'il n'y ait pas de reviews
      let avgRating = 0;
      if (user.role === 'artisan') {
        const { data: avgData, error: avgError } = await supabase
          .from('reviews')
          .select('avg(rating)')
          .eq('artisan_id', user.id)  // Supposons que reviews.artisan_id est lié à users.id dans ce contexte
          .single();

        avgRating = (!avgError && avgData) ? avgData.avg : 0;
      }
      // Pour les commerçants, on suppose qu'il n'y a pas de système de notation basé sur les avis

      return {
        id: user.id,
        role: user.role,
        ...profileData,
        rating: avgRating || 0
      }
    }))

    return new Response(JSON.stringify(resultsWithDetails), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',  // Autoriser l'accès depuis n'importe quelle origine
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  } catch (error) {
    console.error('Erreur serveur lors de la récupération des professionnels mis en avant:', error)
    return new Response(JSON.stringify({ message: "Erreur serveur lors de la récupération des professionnels mis en avant" }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }
})