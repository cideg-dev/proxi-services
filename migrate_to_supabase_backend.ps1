# Script de migration complète vers Supabase Backend
# Ce script crée automatiquement les fonctions Edge, les politiques RLS et met à jour le frontend Flutter

Write-Host "=== Migration vers Supabase Backend ===" -ForegroundColor Green

# Variables à configurer
$PROJECT_URL = Read-Host "Entrez l'URL de votre projet Supabase (https://xxx.supabase.co)"
$ANON_KEY = Read-Host "Entrez votre clé anon de Supabase"
$SERVICE_ROLE_KEY = Read-Host "Entrez votre clé service_role de Supabase"

Write-Host "`n1. Création des fonctions Edge Supabase..." -ForegroundColor Yellow

# Création du répertoire functions
if (!(Test-Path "supabase/functions")) {
    New-Item -ItemType Directory -Path "supabase/functions" | Out-Null
}

# Fonction pour l'inscription
@"
// supabase/functions/signup.ts
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
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const body = await req.json()
  const { email, password, role, profileData } = body

  // Validation des données
  if (!email || !password || !role) {
    return new Response(JSON.stringify({ error: 'Missing required fields' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Vérifier si l'utilisateur existe déjà
  const { data: existingUser, error: fetchError } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .single()

  if (existingUser) {
    return new Response(JSON.stringify({ error: 'User already exists' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Créer l'utilisateur dans Supabase Auth
  const { data: authData, error: authError } = await supabase.auth.admin
    .createUser({
      email,
      password,
      email_confirm: true,
    })

  if (authError) {
    return new Response(JSON.stringify({ error: authError.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Ajouter l'utilisateur à la table users
  const { data: user, error: dbError } = await supabase
    .from('users')
    .insert([{ 
      id: authData.user.id,
      email,
      role,
      password: ''
    }])
    .select()
    .single()

  if (dbError) {
    // Nettoyer l'utilisateur auth s'il y a une erreur
    await supabase.auth.admin.deleteUser(authData.user.id)
    return new Response(JSON.stringify({ error: dbError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Créer le profil utilisateur selon le rôle
  let profileResult
  if (role === 'client') {
    profileResult = await supabase
      .from('client_profiles')
      .insert([{ user_id: user.id, ...profileData }])
  } else if (role === 'artisan') {
    profileResult = await supabase
      .from('artisan_profiles')
      .insert([{ user_id: user.id, ...profileData }])
  } else if (role === 'commercant') {
    profileResult = await supabase
      .from('commercant_profiles')
      .insert([{ user_id: user.id, ...profileData }])
  }

  if (profileResult.error) {
    return new Response(JSON.stringify({ error: profileResult.error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ user, profile: profileResult.data }), {
    status: 201,
    headers: { 'Content-Type': 'application/json' }
  })
})
"@ | Out-File -FilePath "supabase/functions/signup.ts" -Encoding UTF8

# Fonction pour la connexion
@"
// supabase/functions/signin.ts
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
"@ | Out-File -FilePath "supabase/functions/signin.ts" -Encoding UTF8

# Fonction pour récupérer les artisans
@"
// supabase/functions/artisans.ts
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
"@ | Out-File -FilePath "supabase/functions/artisans.ts" -Encoding UTF8

# Fonction pour ajouter un avis
@"
// supabase/functions/reviews.ts
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
        client_id: user.id, 
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
    // Pour récupérer les avis d'un artisan spécifique
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
"@ | Out-File -FilePath "supabase/functions/reviews.ts" -Encoding UTF8

Write-Host "`n2. Création des politiques RLS..." -ForegroundColor Yellow

# Création du fichier SQL pour les politiques RLS
@"
-- supabase/rls_policies.sql
-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE artisan_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE commercant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE demandes ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW_LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Politiques d'accès pour la table users
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- Politiques pour artisan_profiles
CREATE POLICY "Artisans can manage own profile" ON artisan_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politiques pour client_profiles
CREATE POLICY "Clients can manage own profile" ON client_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politiques pour commercant_profiles
CREATE POLICY "Commercants can manage own profile" ON commercant_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politiques pour reviews
CREATE POLICY "Everyone can read reviews" ON reviews
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Clients can create own reviews" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Clients can update own reviews" ON reviews
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id);

-- Politiques pour messages
CREATE POLICY "Users can read own messages" ON messages
  FOR SELECT TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send own messages" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages" ON messages
  FOR UPDATE TO authenticated
  USING (auth.uid() = sender_id);

-- Politiques pour demandes
CREATE POLICY "Users can manage own demands" ON demandes
  FOR ALL TO authenticated
  USING (auth.uid() = client_id OR auth.uid() = artisan_id);

-- Politiques pour portfolios
CREATE POLICY "Users can read all portfolios" ON portfolio_items
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own portfolio" ON portfolio_items
  FOR ALL TO authenticated
  USING (auth.uid() = artisan_id);

-- Politiques pour services
CREATE POLICY "Users can read all services" ON services
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "Artisans can manage own services" ON services
  FOR ALL TO authenticated
  USING (auth.uid() = artisan_id);
"@ | Out-File -FilePath "supabase/rls_policies.sql" -Encoding UTF8

Write-Host "`n3. Création des fichiers Flutter pour Supabase..." -ForegroundColor Yellow

# Mise à jour de la dépendance dans pubspec.yaml
$pubspecPath = "frontend/pubspec.yaml"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    $content = $content -replace '(dependencies:.*?)(\r?\n)([ \t]*#\s*other dependencies|$)', "`$1`$2  supabase_flutter: ^2.0.0`$2`$3"
    $content | Out-File -FilePath $pubspecPath -Encoding UTF8
    Write-Host "Mise à jour de pubspec.yaml pour ajouter supabase_flutter" -ForegroundColor Cyan
} else {
    Write-Host "ERREUR: Le fichier pubspec.yaml n'a pas été trouvé dans frontend/" -ForegroundColor Red
}

# Création du service Supabase
@"
// frontend/lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = '$PROJECT_URL';
  static const String _anonKey = '$ANON_KEY';
  
  final SupabaseClient _client = SupabaseClient(_url, _anonKey);

  SupabaseClient get client => _client;
  
  // Méthode pour s'inscrire
  Future<User?> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.user;
  }

  // Méthode pour se connecter
  Future<User?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  // Méthode pour se déconnecter
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Méthode pour récupérer les artisans
  Future<List<Map<String, dynamic>>> getArtisans() async {
    final response = await _client
      .from('users')
      .select('id, role, artisan_profiles (nom_complet, specialite, location, photo_url)')
      .eq('role', 'artisan');
    
    return response;
  }

  // Méthode pour récupérer les avis d'un artisan
  Future<List<Map<String, dynamic>>> getArtisanReviews(int artisanId) async {
    final response = await _client
      .from('reviews')
      .select('id, artisan_id, client_id, rating, comment, created_at')
      .eq('artisan_id', artisanId);
    
    return response;
  }

  // Méthode pour ajouter un avis
  Future<Map<String, dynamic>?> addReview(int artisanId, int rating, String comment) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
      .from('reviews')
      .insert({
        'artisan_id': artisanId,
        'client_id': user.id,
        'rating': rating,
        'comment': comment,
      })
      .select()
      .single();

    return response;
  }
}
"@ | Out-File -FilePath "frontend/lib/services/supabase_service.dart" -Encoding UTF8

# Mise à jour de api_constants.dart
@"
// frontend/lib/services/api_constants.dart
// Utilisation directe des variables Supabase
class ApiConstants {
  static const String supabaseUrl = '$PROJECT_URL';
  static const String supabaseAnonKey = '$ANON_KEY';
}
"@ | Out-File -FilePath "frontend/lib/services/api_constants.dart" -Encoding UTF8

Write-Host "`n4. Instructions de déploiement :" -ForegroundColor Green
Write-Host "
1. Installez l'interface de ligne de commande Supabase :
   npm install -g supabase

2. Connectez-vous à votre projet :
   supabase login
   supabase link --project-ref VOTRE_PROJECT_REF

3. Déployez les fonctions :
   cd supabase
   supabase functions deploy

4. Exécutez les politiques RLS :
   Copiez le contenu de supabase/rls_policies.sql dans l'éditeur SQL de votre tableau de bord Supabase

5. Dans votre projet Flutter :
   - Exécutez 'flutter pub get' pour installer supabase_flutter
   - Remplacez les appels d'API existants par les méthodes du service SupabaseService
   - Testez l'application

Tous les fichiers nécessaires à la migration vers Supabase ont été créés dans le répertoire 'supabase/'.
Votre frontend Flutter a été préparé avec les fichiers nécessaires dans 'frontend/lib/services/'.
" -ForegroundColor White

Write-Host "`nMigration préparée avec succès!" -ForegroundColor Green