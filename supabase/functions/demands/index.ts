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
        const path = url.pathname.replace("/demands", "").replace(/^\/|\/$/g, "");
        const pathParts = path.split("/");

        // GET /client - Get client demands
        if (req.method === "GET" && path === "client") {
            const { data, error } = await supabase
                .from("demandes")
                .select("*, artisan:artisan_profiles(nom_complet)")
                .eq("client_id", user.id);

            if (error) throw error;
            return new Response(JSON.stringify(data), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // GET /professional - Get professional demands
        if (req.method === "GET" && path === "professional") {
            // First find the artisan/merchant profile id for this user
            // Assuming user.id links to artisan_profiles.user_id
            const { data: artisan, error: artisanError } = await supabase
                .from("artisan_profiles")
                .select("id")
                .eq("user_id", user.id)
                .single();

            if (artisanError && artisanError.code !== 'PGRST116') throw artisanError;

            if (artisan) {
                const { data, error } = await supabase
                    .from("demandes")
                    .select("*, client:profiles(name)")
                    .eq("artisan_id", artisan.id); // Assuming demandes has artisan_id
                if (error) throw error;
                return new Response(JSON.stringify(data), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
            }

            // Check merchant if not artisan (logic can be expanded)
            return new Response(JSON.stringify([]), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // GET /:id - Get demand details
        if (req.method === "GET" && pathParts.length === 1) {
            const demandId = pathParts[0];
            const { data, error } = await supabase
                .from("demandes")
                .select("*")
                .eq("id", demandId)
                .single();

            if (error) throw error;
            return new Response(JSON.stringify(data), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // PUT /:id/status - Update status
        if (req.method === "PUT" && pathParts.length === 2 && pathParts[1] === "status") {
            const demandId = pathParts[0];
            const body = await req.json();
            const { error } = await supabase
                .from("demandes")
                .update({ status: body.status })
                .eq("id", demandId);

            if (error) throw error;
            return new Response(JSON.stringify({ message: "Status updated" }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // DELETE /:id - Cancel demand
        if (req.method === "DELETE" && pathParts.length === 1) {
            const demandId = pathParts[0];
            const { error } = await supabase
                .from("demandes")
                .delete()
                .eq("id", demandId);

            if (error) throw error;
            return new Response(JSON.stringify({ message: "Demand cancelled" }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        return new Response(JSON.stringify({ error: "Not Found" }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
});
