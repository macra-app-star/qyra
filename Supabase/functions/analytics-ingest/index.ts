import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

interface AnalyticsEvent {
  name: string
  properties: Record<string, string>
  timestamp: string
  session_id: string
  user_id: string | null
  device_id: string
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const token = authHeader.replace("Bearer ", "")
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const { events } = await req.json() as { events: AnalyticsEvent[] }

    if (!events || !Array.isArray(events) || events.length === 0) {
      return new Response(JSON.stringify({ error: "No events provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const batch = events.slice(0, 100)

    const rows = batch.map((event) => ({
      user_id: user.id,
      event_name: event.name,
      properties: event.properties,
      event_timestamp: event.timestamp,
      session_id: event.session_id,
      device_id: event.device_id,
      ingested_at: new Date().toISOString(),
    }))

    const { error: insertError } = await supabase
      .from("analytics_events")
      .insert(rows)

    if (insertError) {
      console.error("Insert error:", insertError)
      return new Response(JSON.stringify({ error: "Insert failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    return new Response(JSON.stringify({
      success: true,
      ingested: batch.length
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })

  } catch (err) {
    console.error("Unexpected error:", err)
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
