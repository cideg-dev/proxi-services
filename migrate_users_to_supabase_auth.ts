-- Script pour migrer les utilisateurs existants vers l'authentification Supabase
-- Ce script crée les utilisateurs dans Supabase Auth et peuple la table de correspondance

-- Fonction pour migrer un utilisateur existant vers Supabase Auth
-- ATTENTION : Ce script doit être exécuté avec une fonction Edge ou un script côté serveur
-- car il nécessite la clé SERVICE_ROLE_KEY de Supabase pour créer des utilisateurs

-- 1. Créez d'abord un script Edge Supabase pour migrer les utilisateurs (à exécuter une seule fois)

-- migrate_users.ts
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // ATTENTION : Ce script nécessite la clé SERVICE_ROLE_KEY
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    // Récupérer tous les utilisateurs de la table users
    const { data: users, error } = await supabase
      .from('users')
      .select('id, email, password, role')
    
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Créer un utilisateur Supabase pour chaque utilisateur existant
    const results = []
    for (const user of users) {
      try {
        // Créer l'utilisateur dans Supabase Auth
        const { data: authData, error: authError } = await supabase.auth.admin
          .createUser({
            email: user.email,
            password: user.password, // ATTENTION: Si les mots de passe sont hashés différemment
            email_confirm: true,
          })

        if (authError) {
          console.error(`Erreur lors de la création de l'utilisateur ${user.email}:`, authError.message)
          results.push({ email: user.email, success: false, error: authError.message })
          continue
        }

        // Créer l'entrée dans la table de correspondance
        const { error: mappingError } = await supabase
          .from('user_id_mapping')
          .insert({
            supabase_user_id: authData.user.id,
            app_user_id: user.id
          })

        if (mappingError) {
          console.error(`Erreur lors de la création du mapping pour ${user.email}:`, mappingError.message)
          results.push({ email: user.email, success: false, error: mappingError.message })
          // Nettoyer l'utilisateur auth en cas d'erreur de mapping
          await supabase.auth.admin.deleteUser(authData.user.id)
        } else {
          results.push({ email: user.email, success: true, id: user.id })
        }
      } catch (userError) {
        console.error(`Erreur lors du traitement de l'utilisateur ${user.email}:`, userError)
        results.push({ email: user.email, success: false, error: userError.message })
      }
    }

    return new Response(JSON.stringify({
      message: 'Migration des utilisateurs terminée',
      results: results,
      success_count: results.filter(r => r.success).length,
      error_count: results.filter(r => !r.success).length
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})