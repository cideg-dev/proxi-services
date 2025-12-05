import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

async function getUserFromToken(token: string) {
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error) throw error;
  return user;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }
    const token = authHeader.replace("Bearer ", "");
    const user = await getUserFromToken(token);
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
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
        .single();

      if (profileError) throw profileError;

      // Fetch role-specific profile
      let roleProfile = {};
      const { data: userData, error: userError } = await supabase
        .from("users")
        .select("role")
        .eq("id", user.id)
        .single();

      if (userError) throw userError;

      if (userData.role === 'artisan') {
        const { data: artisan, error: artisanError } = await supabase
          .from("artisan_profiles")
          .select("*")
          .eq("user_id", user.id)
          .single();
        if (!artisanError) roleProfile = artisan;
      } else if (userData.role === 'commercant') {
        const { data: merchant, error: merchantError } = await supabase
          .from("commercant_profiles")
          .select("*")
          .eq("user_id", user.id)
          .single();
        if (!merchantError) roleProfile = merchant;
      }

      return new Response(JSON.stringify({
        user: {
          ...user,
          ...profile,
          role: userData.role,
          ...roleProfile
        }
      }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
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

      return new Response(JSON.stringify({ message: "Profile updated" }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify({ error: "Not Found" }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});