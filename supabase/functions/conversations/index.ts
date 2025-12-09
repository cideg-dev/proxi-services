import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { createOptionsResponse, getCorsHeaders } from '../_shared/cors.ts'

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

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }
    const token = authHeader.replace("Bearer ", "");
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
    const path = url.pathname.replace("/conversations", "").replace(/^\/|\/$/g, "");
    const pathParts = path.split("/");

    // GET / - Get all conversations
    if (req.method === "GET" && path === "") {
      const { data, error } = await supabase
        .from("conversations")
        .select(`
          id,
          created_at,
          updated_at,
          participants:conversation_participants(
            user_id,
            user:profiles(name, avatar_url)
          ),
          last_message:messages(content, sent_at, sender_id)
        `)
        .order("updated_at", { ascending: false });

      if (error) throw error;

      // Filter conversations where current user is a participant
      const userConversations = data ? data.filter((c: any) =>
        c.participants && c.participants.some((p: any) => p.user_id === user.id)
      ) : [];

      // Transform data for frontend
      const formattedConversations = userConversations.map((c: any) => {
        const otherParticipant = c.participants.find((p: any) => p.user_id !== user.id);
        const lastMsg = c.last_message && c.last_message.length > 0 ? c.last_message[0] : null;

        return {
          id: c.id,
          name: otherParticipant?.user?.name || "Utilisateur",
          avatar_url: otherParticipant?.user?.avatar_url,
          last_message: lastMsg?.content || "Pas de message",
          last_message_time: lastMsg?.sent_at || c.updated_at,
          unread_count: 0 // TODO: Implement unread count
        };
      });

      return new Response(JSON.stringify(formattedConversations), {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    // POST / - Create conversation
    if (req.method === "POST" && path === "") {
      const body = await req.json();
      const { receiverId } = body;

      // Check if conversation exists
      // ... (Simplified for now, just create new)

      const { data: conversation, error: convError } = await supabase
        .from("conversations")
        .insert({})
        .select()
        .single();

      if (convError) throw convError;

      // Add participants
      const { error: partError } = await supabase
        .from("conversation_participants")
        .insert([
          { conversation_id: conversation.id, user_id: user.id },
          { conversation_id: conversation.id, user_id: receiverId }
        ]);

      if (partError) throw partError;

      return new Response(JSON.stringify(conversation), {
        status: 201,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    // GET /:id/messages - Get messages for a conversation
    if (req.method === "GET" && pathParts.length === 2 && pathParts[1] === "messages") {
      const conversationId = pathParts[0];
      const url = new URL(req.url);
      const limit = parseInt(url.searchParams.get("limit") || "20");
      const beforeId = url.searchParams.get("beforeId");

      let query = supabase
        .from("messages")
        .select("*")
        .eq("conversation_id", conversationId)
        .order("sent_at", { ascending: false })
        .limit(limit);

      if (beforeId) {
        query = query.lt("id", beforeId);
      }

      const { data, error } = await query;

      if (error) throw error;

      return new Response(JSON.stringify(data), {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    // POST /:id/messages - Send a message
    if (req.method === "POST" && pathParts.length === 2 && pathParts[1] === "messages") {
      const conversationId = pathParts[0];
      const body = await req.json();
      const { content } = body;

      const { data, error } = await supabase
        .from("messages")
        .insert({
          conversation_id: conversationId,
          sender_id: user.id,
          content: content,
          sent_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;

      // Update conversation updated_at
      await supabase
        .from("conversations")
        .update({ updated_at: new Date().toISOString() })
        .eq("id", conversationId);

      return new Response(JSON.stringify(data), {
        status: 201,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          'Access-Control-Allow-Credentials': 'true',
        }
      });
    }

    // PUT /:id/mark-as-read - Mark messages as read
    if (req.method === "PUT" && pathParts.length === 2 && pathParts[1] === "mark-as-read") {
      const conversationId = pathParts[0];

      // Update read_at for messages where receiver is current user and read_at is null
      // This assumes we have a way to know who the receiver is or we mark all messages not sent by us as read
      const { error } = await supabase
        .from("messages")
        .update({ read_at: new Date().toISOString() })
        .eq("conversation_id", conversationId)
        .neq("sender_id", user.id)
        .is("read_at", null);

      if (error) throw error;

      return new Response(JSON.stringify({ success: true }), {
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
    const origin = req.headers.get("Origin");
    const corsHeaders = getCorsHeaders(origin);

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