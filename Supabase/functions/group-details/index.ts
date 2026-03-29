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

    const url = new URL(req.url)
    const groupId = url.searchParams.get("group_id")

    if (groupId) {
      const { data: group, error } = await supabase.from("groups").select("*, group_members(user_id, role, joined_at)").eq("id", groupId).single()
      if (error || !group) return new Response(JSON.stringify({ error: "Group not found" }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } })
      return new Response(JSON.stringify({ group }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } })
    } else {
      const { data: memberships } = await supabase.from("group_members").select("group_id").eq("user_id", user.id)
      if (!memberships || memberships.length === 0) return new Response(JSON.stringify({ groups: [] }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } })

      const groupIds = memberships.map((m: any) => m.group_id)
      const { data: groups } = await supabase.from("groups").select("*, group_members(count)").in("id", groupIds).order("created_at", { ascending: false })
      return new Response(JSON.stringify({ groups: groups ?? [] }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal error" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } })
  }
})
