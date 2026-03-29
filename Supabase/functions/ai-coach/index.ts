import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { context } = await req.json();
    if (!context) {
      return new Response(
        JSON.stringify({ error: "Context required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const claudeRes = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 512,
          system:
            "You are Qyra AI, a concise nutrition coach. Given the user's daily intake and goals, provide a brief insight (2-3 sentences max). Be specific about what they should eat next. Never give medical advice. Be encouraging but honest.",
          messages: [
            {
              role: "user",
              content: context,
            },
          ],
        }),
      }
    );

    if (!claudeRes.ok) {
      throw new Error(`Claude API error: ${claudeRes.status}`);
    }

    const claudeData = await claudeRes.json();
    const textContent = claudeData.content?.find(
      (c: any) => c.type === "text"
    );

    return new Response(
      JSON.stringify({ insight: textContent?.text || "Keep logging your meals to get personalized insights!" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        insight: "Keep logging your meals to get personalized insights!",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
