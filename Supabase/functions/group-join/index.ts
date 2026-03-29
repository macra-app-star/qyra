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

    const { invite_code } = await req.json()
    if (!invite_code) return new Response(JSON.stringify({ error: "Invite code required" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    const { data: group, error: findError } = await supabase.from("groups").select("*").eq("invite_code", invite_code.toUpperCase().trim()).single()
    if (findError || !group) return new Response(JSON.stringify({ error: "No group found with that code" }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    const { data: existing } = await supabase.from("group_members").select("id").eq("group_id", group.id).eq("user_id", user.id).single()
    if (existing) return new Response(JSON.stringify({ error: "Already a member", group }), { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } })

    await supabase.from("group_members").insert({ group_id: group.id, user_id: user.id, role: "member" })

    return new Response(JSON.stringify({ success: true, group: { id: group.id, name: group.name, invite_code: group.invite_code } }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } })
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal error" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } })
  }
})
