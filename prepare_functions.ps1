# Script de préparation et déploiement des fonctions Edge Supabase
Write-Host "=== Préparation des fonctions Edge Supabase ===" -ForegroundColor Green

# Créer la structure de répertoires pour les fonctions
$functionsDir = "E:\projet_services\supabase\functions"
if (!(Test-Path $functionsDir)) {
    New-Item -ItemType Directory -Path $functionsDir -Force | Out-Null
    Write-Host "✅ Répertoire supabase/functions créé" -ForegroundColor Green
}

# Créer les sous-répertoires pour chaque fonction
$functions = @("signup", "signin", "artisans", "reviews", "migrate-users")
foreach ($func in $functions) {
    $funcPath = Join-Path $functionsDir $func
    if (!(Test-Path $funcPath)) {
        New-Item -ItemType Directory -Path $funcPath -Force | Out-Null
        Write-Host "✅ Répertoire pour la fonction '$func' créé" -ForegroundColor Green
    }
}

# Copier les fichiers de fonctions dans les bons répertoires
$signupContent = Get-Content "E:\projet_services\signup_with_mapping.ts" -Raw
$signupContent | Out-File -FilePath "E:\projet_services\supabase\functions\signup\index.ts" -Encoding UTF8

# Créer une fonction générique signin
@"
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
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
      headers: { 'Content-Type': 'application/json' }
    })
  }

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ 
    session: data.session,
    user: data.user
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
})
"@ | Out-File -FilePath "E:\projet_services\supabase\functions\signin\index.ts" -Encoding UTF8

# Créer une fonction générique artisans
@"
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  const { data, error } = await supabase
    .from('users')
    .select('id, role, artisan_profiles (nom_complet, specialite, location, photo_url)')
    .eq('role', 'artisan')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
})
"@ | Out-File -FilePath "E:\projet_services\supabase\functions\artisans\index.ts" -Encoding UTF8

# Créer une fonction générique reviews
@"
import { serve } from 'https://deno.land/std@0.114.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  if (req.method === 'POST') {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } }
    )

    const { data: { user }, error } = await supabase.auth.getUser()
    
    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const appUserId = await supabase.rpc('get_app_user_id', { supabase_uuid: user.id });
    
    const body = await req.json()
    const { artisanId, rating, comment } = body

    if (!artisanId || !rating || !comment) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    if (rating < 1 || rating > 5) {
      return new Response(JSON.stringify({ error: 'Rating must be between 1 and 5' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const { data: review, error: insertError } = await supabase
      .from('reviews')
      .insert([{ 
        artisan_id: artisanId, 
        client_id: appUserId.data[0].app_user_id, 
        rating, 
        comment 
      }])
      .select()
      .single()

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify(review), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    })
  } else if (req.method === 'GET') {
    const url = new URL(req.url)
    const artisanId = url.searchParams.get('artisan_id')

    if (!artisanId) {
      return new Response(JSON.stringify({ error: 'Artisan ID required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select('id, artisan_id, client_id, rating, comment, created_at')
      .eq('artisan_id', artisanId)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify(reviews), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })
  } else {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
"@ | Out-File -FilePath "E:\projet_services\supabase\functions\reviews\index.ts" -Encoding UTF8

# Copier la fonction de migration
$migrateContent = Get-Content "E:\projet_services\migrate_users_function.ts" -Raw
$migrateContent | Out-File -FilePath "E:\projet_services\supabase\functions\migrate-users\index.ts" -Encoding UTF8

Write-Host "`n=== Fichiers de fonctions prêts ===" -ForegroundColor Green
Write-Host "
Les fichiers de fonctions Edge sont prêts dans le répertoire supabase/functions/
Chaque fonction est dans son propre sous-répertoire avec un fichier index.ts

Pour déployer :
1. Assurez-vous d'être connecté à Supabase : supabase login
2. Lier votre projet : supabase link --project-ref ufeqnnbokyalwjfskhmw
3. Déployer les fonctions : supabase functions deploy --project-ref ufeqnnbokyalwjfskhmw
" -ForegroundColor White