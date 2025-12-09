import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { createOptionsResponse, getCorsHeaders } from '../_shared/cors.ts'
import { extractTokenFromHeaders, isValidJWTFormat } from '../_shared/tokenUtils.ts';

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function getUserFromToken(token: string) {
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error) throw error;
  return user;
}

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return createOptionsResponse(req);
  }

  try {
    const origin = req.headers.get("Origin");
    const corsHeaders = getCorsHeaders(origin);

    const token = extractTokenFromHeaders(req.headers);
    if (!token || !isValidJWTFormat(token)) {
      return new Response(JSON.stringify({ error: "Invalid or missing authorization token" }), {
        status: 401,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    const user = await getUserFromToken(token);
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    const url = new URL(req.url);
    const path = url.pathname.replace("/profile", "").replace(/^\/|\/$/g, "");

    // GET / - Get current user profile
    if (req.method === "GET" && path === "") {
      // Fetch basic profile
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", user.id)
        .limit(1)
        .maybeSingle();

      if (profileError) throw profileError;

      // Fetch role-specific profile
      let roleProfile = {};
      const { data: userData, error: userError } = await supabase
        .from("users")
        .select("role")
        .eq("id", user.id)
        .limit(1)
        .maybeSingle();

      if (userError) {
        console.error("Error fetching user data:", userError);
        throw userError;
      }

      if (userData && userData.role === 'artisan') {
        const { data: artisan, error: artisanError } = await supabase
          .from("artisan_profiles")
          .select("*")
          .eq("user_id", user.id)
          .limit(1)
          .maybeSingle();
        if (artisanError) {
          console.error("Error fetching artisan profile:", artisanError);
        } else if (artisan) {
          roleProfile = artisan;
        }
      } else if (userData && userData.role === 'commercant') {
        const { data: merchant, error: merchantError } = await supabase
          .from("commercant_profiles")
          .select("*")
          .eq("user_id", user.id)
          .limit(1)
          .maybeSingle();
        if (merchantError) {
          console.error("Error fetching commercant profile:", merchantError);
        } else if (merchant) {
          roleProfile = merchant;
        }
      }

      // Check for profile existence and log if not found
      if (!profile) {
        console.warn(`No entry in 'profiles' table for user ID: ${user.id}`);
      }
      
      // Check for user data existence and log if not found
      if (!userData) {
        console.warn(`No entry in 'users' table for user ID: ${user.id}`);
      }

      return new Response(JSON.stringify({
        user: {
          ...user,
          ...profile,
          role: userData?.role, // Use optional chaining for safety
          ...roleProfile
        }
      }), {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    // PUT / - Update current user profile
    if (req.method === "PUT" && path === "") {
      const body = await req.json();

      // Update profiles table
      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          name: body.name,
          // Add other fields as needed
        })
        .eq("id", user.id);

      if (profileError) throw profileError;

      // Update role-specific table if needed
      // ... (Implementation depends on what fields are being updated)

      return new Response(JSON.stringify({ message: "Profile updated" }), {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    return new Response(JSON.stringify({ error: "Not Found" }), {
      status: 404,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        'Access-Control-Allow-Credentials': 'true',
      }
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        'Access-Control-Allow-Credentials': 'true',
      }
    });
  }
});