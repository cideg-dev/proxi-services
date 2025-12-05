// supabase/functions/conversations/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Helper function to get authenticated user
async function getUserFromToken(token: string) {
  try {
    // Supabase provides built-in authentication utilities
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error) {
      throw new Error(error.message);
    }
    return user;
  } catch (error) {
    console.error("Error getting user from token:", error);
    return null;
  }
}

serve(async (req) => {
  try {
    // Handle CORS preflight request
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 200,
        headers: {
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        },
      });
    }

    // Extract token from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized: Missing or invalid token" }), {
        status: 401,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }
    const token = authHeader.substring(7);

    // Get the authenticated user
    const user = await getUserFromToken(token);
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized: Invalid token" }), {
        status: 401,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Parse the request URL
    const url = new URL(req.url);
    const path = url.pathname.replace("/conversations", "").replace(/^\/|\/$/g, "");
    const pathParts = path.split("/");
    const method = req.method;

    // Main conversations routes
    if (method === "GET") {
      // GET /conversations - Get all conversations for the user
      if (pathParts.length === 0 || pathParts[0] === "") {
        return await getConversations(user.id);
      }
      
      // GET /conversations/:id/messages - Get messages from a conversation
      if (pathParts.length >= 2 && pathParts[1] === "messages") {
        const conversationId = pathParts[0];
        const queryParams = Object.fromEntries(url.searchParams);
        return await getConversationMessages(conversationId, user.id, queryParams);
      }
    } else if (method === "POST") {
      // POST /conversations - Start a new conversation
      if (pathParts.length === 0 || pathParts[0] === "") {
        const body = await req.json();
        return await startConversation(user.id, body);
      }
      
      // POST /conversations/:id/messages - Send a message to a conversation
      if (pathParts.length >= 2 && pathParts[1] === "messages") {
        const conversationId = pathParts[0];
        const body = await req.json();
        return await sendMessageToConversation(conversationId, user.id, body);
      }
    } else if (method === "PUT") {
      // PUT /conversations/:id/mark-as-read - Mark a conversation as read
      if (pathParts.length >= 2 && pathParts[1] === "mark-as-read") {
        const conversationId = pathParts[0];
        return await markConversationAsRead(conversationId, user.id);
      }
    }

    // If no route matches
    return new Response(JSON.stringify({ error: "Route not found" }), {
      status: 404,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in conversations function:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
});

async function getConversations(userId: string) {
  try {
    // Get all conversation IDs where the user is a participant
    const { data: userConversations, error: convError } = await supabase
      .from('conversation_participants')
      .select('conversation_id')
      .eq('user_id', userId);

    if (convError) {
      console.error("Error getting user conversations:", convError);
      return new Response(JSON.stringify({ error: "Failed to get conversations" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    if (!userConversations || userConversations.length === 0) {
      // User has no conversations
      return new Response(JSON.stringify([]), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    const conversationIds = userConversations.map(c => c.conversation_id);

    // Get conversation details
    const { data: conversations, error: detailsError } = await supabase
      .from('conversations')
      .select('id, created_at, updated_at')
      .in('id', conversationIds);

    if (detailsError) {
      console.error("Error getting conversation details:", detailsError);
      return new Response(JSON.stringify({ error: "Failed to get conversation details" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // For each conversation, get the other participant
    const transformedConversations = await Promise.all(
      conversations.map(async (conv) => {
        // Get all participants of this conversation
        const { data: participants, error: partError } = await supabase
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conv.id);

        if (partError || !participants) {
          console.error("Error getting participants:", partError);
          return null;
        }

        // Find the other participant (not the current user)
        const otherParticipantId = participants.find(
          (p: any) => p.user_id !== userId
        )?.user_id;

        if (!otherParticipantId) {
          return null;
        }

        // Get the other participant's profile
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('name, email, avatar_url')
          .eq('id', otherParticipantId)
          .single();

        if (profileError) {
          console.error("Error getting profile:", profileError);
        }

        return {
          id: conv.id,
          updated_at: conv.updated_at,
          created_at: conv.created_at,
          partner: {
            id: otherParticipantId,
            name: profile?.name || null,
            email: profile?.email || null,
            avatar_url: profile?.avatar_url || null
          }
        };
      })
    );

    // Filter out null values
    const validConversations = transformedConversations.filter(c => c !== null);

    return new Response(JSON.stringify(validConversations), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in getConversations:", error);
    return new Response(JSON.stringify({ error: "Failed to get conversations" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
}

async function startConversation(userId: string, body: any) {
  try {
    const { receiverId } = body;
    if (!receiverId) {
      return new Response(JSON.stringify({ error: "Missing receiverId" }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Check if conversation already exists between these users
    // This is a simplified implementation - in a real app you might have a more complex logic
    
    // Create a new conversation
    const { data: newConversation, error: insertError } = await supabase
      .from('conversations')
      .insert({
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (insertError) {
      console.error("Error creating conversation:", insertError);
      return new Response(JSON.stringify({ error: "Failed to start conversation" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Add both users as participants to the conversation
    const { error: participantsError } = await supabase
      .from('conversation_participants')
      .insert([
        { conversation_id: newConversation.id, user_id: userId },
        { conversation_id: newConversation.id, user_id: receiverId }
      ]);

    if (participantsError) {
      console.error("Error adding participants:", participantsError);
      return new Response(JSON.stringify({ error: "Failed to add participants" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // In a real app, you might want to return more detailed information
    return new Response(JSON.stringify({ 
      id: newConversation.id,
      created_at: newConversation.created_at,
      participants: [userId, receiverId]
    }), {
      status: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in startConversation:", error);
    return new Response(JSON.stringify({ error: "Failed to start conversation" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
}

async function sendMessageToConversation(conversationId: string, userId: string, body: any) {
  try {
    const { content } = body;
    if (!content) {
      return new Response(JSON.stringify({ error: "Missing content" }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // First check if the user is part of this conversation
    const { data: participantCheck, error: checkError } = await supabase
      .from('conversation_participants')
      .select('*')
      .eq('conversation_id', conversationId)
      .eq('user_id', userId)
      .single();

    if (checkError || !participantCheck) {
      return new Response(JSON.stringify({ error: "Not authorized to access this conversation" }), {
        status: 403,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Insert the message into the database
    const { data: newMessage, error: insertError } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        sender_id: userId,
        content: content,
        sent_at: new Date().toISOString()
      })
      .select()
      .single();

    if (insertError) {
      console.error("Error sending message:", insertError);
      return new Response(JSON.stringify({ error: "Failed to send message" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    return new Response(JSON.stringify(newMessage), {
      status: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in sendMessageToConversation:", error);
    return new Response(JSON.stringify({ error: "Failed to send message" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
}

async function getConversationMessages(conversationId: string, userId: string, queryParams: any) {
  try {
    // First check if the user is part of this conversation
    const { data: participantCheck, error: checkError } = await supabase
      .from('conversation_participants')
      .select('*')
      .eq('conversation_id', conversationId)
      .eq('user_id', userId)
      .single();

    if (checkError || !participantCheck) {
      return new Response(JSON.stringify({ error: "Not authorized to access this conversation" }), {
        status: 403,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Build the query with pagination
    let query = supabase
      .from('messages')
      .select(`
        id,
        content,
        sent_at,
        sender_id,
        sender:profiles(name)
      `)
      .eq('conversation_id', conversationId)
      .order('sent_at', { ascending: true });

    // Apply pagination if specified
    if (queryParams.limit) {
      query = query.limit(parseInt(queryParams.limit));
    }
    if (queryParams.beforeId) {
      query = query.lt('id', parseInt(queryParams.beforeId));
    }
    if (queryParams.afterId) {
      query = query.gt('id', parseInt(queryParams.afterId));
    }

    const { data, error } = await query;

    if (error) {
      console.error("Error getting messages:", error);
      return new Response(JSON.stringify({ error: "Failed to get messages" }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Transform the data to match expected format
    const transformedMessages = data.map(msg => ({
      id: msg.id,
      content: msg.content,
      timestamp: msg.sent_at,
      senderId: msg.sender_id,
      senderName: msg.sender?.name || 'Unknown',
    }));

    return new Response(JSON.stringify(transformedMessages), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in getConversationMessages:", error);
    return new Response(JSON.stringify({ error: "Failed to get messages" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
}

async function markConversationAsRead(conversationId: string, userId: string) {
  try {
    // In a real implementation, you would update a read status in your database
    // This is a simplified version that simply returns success
    
    // Verify user is part of conversation
    const { data: participantCheck, error: checkError } = await supabase
      .from('conversation_participants')
      .select('*')
      .eq('conversation_id', conversationId)
      .eq('user_id', userId)
      .single();

    if (checkError || !participantCheck) {
      return new Response(JSON.stringify({ error: "Not authorized to access this conversation" }), {
        status: 403,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Update read status in your messages table
    // This would typically involve updating a read status field in a conversation_user table
    // For now, just return success
    
    return new Response(JSON.stringify({ message: "Conversation marked as read" }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  } catch (error) {
    console.error("Error in markConversationAsRead:", error);
    return new Response(JSON.stringify({ error: "Failed to mark conversation as read" }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://cideg-dev.github.io",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }
}