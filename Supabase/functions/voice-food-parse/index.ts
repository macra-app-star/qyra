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

    const { transcript } = await req.json();
    if (!transcript) {
      return new Response(
        JSON.stringify({ error: "Transcript required" }),
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
          max_tokens: 2048,
          system:
            "Parse this food description into structured nutrition data. Return a JSON array of foods with name, estimated calories, protein, carbs, fat per item. Use USDA standard portions when not specified.",
          messages: [
            {
              role: "user",
              content: `Parse this into individual food items with nutrition estimates:

"${transcript}"

Return ONLY a JSON array where each object has:
- "name": string (specific food name)
- "calories": number
- "protein": number (grams)
- "carbs": number (grams)
- "fat": number (grams)
- "fiber": number or null
- "sugar": number or null
- "sodium": number or null (mg)
- "serving_size": string
- "confidence": number (0-100)`,
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
    if (!textContent?.text) {
      throw new Error("No text response from Claude");
    }

    const jsonStr = extractJSON(textContent.text);
    const foods = JSON.parse(jsonStr);

    const results = foods.map((food: any, i: number) => ({
      id: `voice_${Date.now()}_${i}`,
      name: food.name,
      calories: food.calories || 0,
      protein: food.protein || 0,
      carbs: food.carbs || 0,
      fat: food.fat || 0,
      fiber: food.fiber || null,
      sugar: food.sugar || null,
      sodium: food.sodium || null,
      servingSize: food.serving_size || "1 serving",
      servingUnit: "serving",
      source: "ai_voice",
      barcode: null,
      confidence: food.confidence || 65,
    }));

    return new Response(JSON.stringify(results), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

function extractJSON(text: string): string {
  let cleaned = text;
  if (cleaned.includes("```json")) {
    cleaned = cleaned.replace(/```json\s*/g, "").replace(/```/g, "");
  } else if (cleaned.includes("```")) {
    cleaned = cleaned.replace(/```/g, "");
  }
  return cleaned.trim();
}
