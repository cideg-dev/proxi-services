import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    });
  }

  // Extraire le chemin de l'URL
  const url = new URL(req.url);
  const path = url.pathname;
  const pathParts = path.split('/').filter(part => part !== '');
  console.log('Path:', path);
  console.log('Path parts:', pathParts);

  // La fonction gère à la fois /profile et /api/profile
  // Le format attendu est /profile ou /profile/{userId} ou /api/profile ou /api/profile/{userId}
  let userId = null;
  
  // Gérer les deux formats d'URL
  if (pathParts.length >= 1) {
    // Vérifier si le premier segment est "api" et s'il y a un second segment "profile"
    if (pathParts[0] === 'api' && pathParts[1] === 'profile' && pathParts.length >= 3) {
      userId = pathParts[2]; // La troisième partie après /api/profile/
    } 
    // Ou si le premier segment est "profile"
    else if (pathParts[0] === 'profile' && pathParts.length >= 2) {
      userId = pathParts[1]; // La deuxième partie après /profile/
    }
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  if (req.method === 'GET') {
    try {
      let response;
      
      if (userId) {
        // Récupérer le profil d'un utilisateur spécifique
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select(`
            id, 
            email, 
            role, 
            created_at, 
            updated_at, 
            last_seen,
            is_blocked,
            user_profiles (
              nom_complet,
              nom_entreprise,
              telephone,
              adresse,
              ville,
              pays,
              code_postal,
              specialite,
              type_commerce,
              description,
              horaires_travail,
              certifications,
              assurance_professionnelle,
              sexe,
              langues_parlees,
              profile_photo_url,
              cover_image_url,
              rating,
              review_count
            )
          `)
          .eq('id', userId)
          .single();

        if (userError || !userData) {
          console.error('User fetch error:', userError);
          return new Response(JSON.stringify({ error: 'Utilisateur non trouvé' }), {
            status: 404,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            }
          });
        }

        // Fusionner les données utilisateur avec les données du profil
        const profile = {
          id: userData.id,
          email: userData.email,
          role: userData.role,
          created_at: userData.created_at,
          updated_at: userData.updated_at,
          last_seen: userData.last_seen,
          is_blocked: userData.is_blocked,
          ...userData.user_profiles?.[0] || {}
        };

        response = new Response(JSON.stringify({ 
          profile, 
          user: { 
            id: userData.id, 
            email: userData.email, 
            role: userData.role, 
            is_blocked: userData.is_blocked 
          } 
        }), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          }
        });
      } else {
        // Récupérer le profil de l'utilisateur authentifié
        const token = req.headers.get('Authorization')?.split(' ')[1];
        
        if (!token) {
          return new Response(JSON.stringify({ error: 'Token d\'authentification requis' }), {
            status: 401,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
              'Access-Control-Allow-Credentials': 'true',
            }
          });
        }

        // Extraire les informations utilisateur via Supabase Auth
        const { data: { user }, error: authError } = await supabase.auth.getUser(token);

        if (authError || !user) {
          return new Response(JSON.stringify({ error: 'Token invalide' }), {
            status: 401,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
              'Access-Control-Allow-Credentials': 'true',
            }
          });
        }

        // Récupérer les informations utilisateur de la table personnalisée
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select(`
            id, 
            email, 
            role, 
            created_at, 
            updated_at, 
            last_seen,
            is_blocked,
            user_profiles (
              nom_complet,
              nom_entreprise,
              telephone,
              adresse,
              ville,
              pays,
              code_postal,
              specialite,
              type_commerce,
              description,
              horaires_travail,
              certifications,
              assurance_professionnelle,
              sexe,
              langues_parlees,
              profile_photo_url,
              cover_image_url,
              rating,
              review_count
            )
          `)
          .eq('id', user.id)
          .single();

        if (userError || !userData) {
          console.error('User profile fetch error:', userError);
          return new Response(JSON.stringify({ error: 'Profil utilisateur non trouvé' }), {
            status: 404,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
              'Access-Control-Allow-Credentials': 'true',
            }
          });
        }

        // Fusionner les données utilisateur avec les données du profil
        const profile = {
          id: userData.id,
          email: userData.email,
          role: userData.role,
          created_at: userData.created_at,
          updated_at: userData.updated_at,
          last_seen: userData.last_seen,
          is_blocked: userData.is_blocked,
          ...userData.user_profiles?.[0] || {}
        };

        response = new Response(JSON.stringify({ 
          profile, 
          user: { 
            id: userData.id, 
            email: userData.email, 
            role: userData.role, 
            is_blocked: userData.is_blocked 
          } 
        }), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          }
        });
      }

      return response;
    } catch (error) {
      console.error('GET profile error:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      });
    }
  } else if (req.method === 'PUT') {
    // Mise à jour du profil
    const token = req.headers.get('Authorization')?.split(' ')[1];
    
    if (!token) {
      return new Response(JSON.stringify({ error: 'Token d\'authentification requis' }), {
        status: 401,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      });
    }

    try {
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);

      if (authError || !user) {
        return new Response(JSON.stringify({ error: 'Token invalide' }), {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          }
        });
      }

      const authenticatedUserId = user.id;

      // Vérifier si l'utilisateur essaie de modifier un autre utilisateur
      if (userId && userId !== authenticatedUserId.toString()) {
        return new Response(JSON.stringify({ error: 'Accès non autorisé' }), {
          status: 403,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          }
        });
      }

      const body = await req.json();
      console.log('Update body:', body);
      
      // Mettre à jour ou créer les informations du profil dans la table user_profiles
      const profileData = { 
        ...body,
        user_id: authenticatedUserId,
        updated_at: new Date().toISOString()
      };

      const { error: profileError } = await supabase
        .from('user_profiles')
        .upsert([profileData], { onConflict: ['user_id'] });

      if (profileError) {
        console.error('Profile update error:', profileError);
        throw profileError;
      }

      // Retourner le profil mis à jour
      const { data: updatedProfile, error: fetchError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', authenticatedUserId)
        .single();

      if (fetchError) {
        console.error('Fetch updated profile error:', fetchError);
        throw fetchError;
      }

      return new Response(JSON.stringify(updatedProfile), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      });
    } catch (error) {
      console.error('PUT profile error:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      });
    }
  } else {
    return new Response(JSON.stringify({ error: 'Méthode non autorisée' }), {
      status: 405,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With, X-Client-Info',
        'Access-Control-Allow-Credentials': 'true',
      }
    });
  }
})