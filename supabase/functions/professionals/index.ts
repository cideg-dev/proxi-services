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
    const { data, error } = await supabase
      .from('users')
      .select(`
        id,
        role,
        COALESCE(artisan_profiles.nom_complet, commercant_profiles.nom_entreprise) AS nom,
        COALESCE(artisan_profiles.specialite, commercant_profiles.type_commerce) AS specialite,
        COALESCE(artisan_profiles.description, commercant_profiles.description) AS description,
        COALESCE(artisan_profiles.photo_url, commercant_profiles.photo_url) AS photo_url,
        COALESCE(artisan_profiles.location, commercant_profiles.location) AS location,
        COALESCE(avg_reviews.avg_rating, 0) AS rating
      `)
      .eq('role', 'artisan')
      .or('role.eq.commercant')
      .limit(10)
      .returns<any[]>()

    if (error) {
      console.error('Erreur lors de la récupération des professionnels mis en avant:', error)
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

    // Ajouter une logique pour calculer les notes moyennes
    const resultsWithRatings = await Promise.all(data.map(async (item) => {
      if (item.id) {
        const { data: avgData, error: avgError } = await supabase
          .from('reviews')
          .select('avg(rating)')
          .eq('artisan_id', item.id)

        if (!avgError && avgData && avgData[0]) {
          item.rating = avgData[0].avg || 0
        } else {
          item.rating = 0
        }
      }
      return item
    }))

    return new Response(JSON.stringify(resultsWithRatings), {
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