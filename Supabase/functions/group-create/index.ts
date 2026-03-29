import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!)
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""))
    if (authError || !user) return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    const { name, is_private } = await req.json()
    if (!name || name.trim().length === 0) return new Response(JSON.stringify({ error: "Name required" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    let invite_code = ""
    for (let i = 0; i < 6; i++) invite_code += chars[Math.floor(Math.random() * chars.length)]

    const { data: group, error: groupError } = await supabase.from("groups").insert({ name: name.trim(), invite_code, created_by: user.id, is_private: is_private ?? false }).select().single()
    if (groupError) return new Response(JSON.stringify({ error: groupError.message }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    await supabase.from("group_members").insert({ group_id: group.id, user_id: user.id, role: "owner" })

    return new Response(JSON.stringify({ group }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } })
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal error" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } })
  }
})
