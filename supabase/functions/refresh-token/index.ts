// supabase/functions/refresh-token/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SignJWT } from 'https://deno.land/x/djwt@v3.0.1/mod.ts';

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

// Fonction pour vérifier si un token est valide
async function verifyToken(token: string) {
  try {
    // Dans une implémentation complète, vous voudriez vérifier le JWT
    // Pour l'instant, on fait une vérification basique
    const parts = token.split('.');
    if (parts.length !== 3) {
      return { isValid: false };
    }

    // Décoder l'en-tête et le payload (sans vérifier la signature pour le moment)
    try {
      const payload = JSON.parse(atob(parts[1]));
      const currentTime = Math.floor(Date.now() / 1000);
      
      // Vérifier l'expiration
      if (payload.exp && payload.exp < currentTime) {
        return { isValid: false, error: 'Token expiré' };
      }
      
      return { isValid: true, payload };
    } catch (e) {
      return { isValid: false, error: 'Format de token invalide' };
    }
  } catch (e) {
    return { isValid: false, error: e.message };
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }

  try {
    // Extraire le token d'authentification
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Token d\'authentification requis' }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    const refreshToken = authHeader.substring(7); // Enlever 'Bearer '
    
    // Vérifier si le refresh token est valide
    const tokenValidation = await verifyToken(refreshToken);
    if (!tokenValidation.isValid) {
      return new Response(JSON.stringify({ error: 'Refresh token invalide ou expiré' }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Trouver l'utilisateur associé à ce token
    // Dans une vraie implémentation, vous devriez avoir une table de correspondance
    // ou vérifier l'utilisateur via Supabase Auth
    const tokenPayload = tokenValidation.payload;
    const userId = tokenPayload.id;
    
    if (!userId) {
      return new Response(JSON.stringify({ error: 'Informations utilisateur manquantes dans le token' }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Récupérer les informations utilisateur
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, role')
      .eq('id', userId)
      .single();

    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Utilisateur non trouvé' }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Générer un nouveau token d'accès
    const jwtSecret = Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_SECRET');
    if (!jwtSecret) {
      return new Response(JSON.stringify({ error: 'Clé JWT manquante' }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Générer un nouveau token d'accès (expire dans 15 minutes)
    const newTokenPayload = {
      id: user.id,
      email: user.email,
      role: user.role,
      exp: Math.floor(Date.now() / 1000) + (15 * 60), // 15 minutes
    };

    const newAccessToken = await new SignJWT(newTokenPayload)
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime(newTokenPayload.exp * 1000)
      .sign(new TextEncoder().encode(jwtSecret));

    // Générer un nouveau refresh token (expire dans 7 jours)
    const newRefreshTokenPayload = {
      id: user.id,
      email: user.email,
      role: user.role,
      exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60), // 7 jours
    };

    const newRefreshToken = await new SignJWT(newRefreshTokenPayload)
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime(newRefreshTokenPayload.exp * 1000)
      .sign(new TextEncoder().encode(Deno.env.get('SUPABASE_JWT_SECRET') || Deno.env.get('JWT_REFRESH_SECRET') || 'fallback_refresh_secret'));

    return new Response(JSON.stringify({
      token: newAccessToken,
      refreshToken: newRefreshToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      }
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });

  } catch (error) {
    console.error('Erreur dans refresh-token:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});