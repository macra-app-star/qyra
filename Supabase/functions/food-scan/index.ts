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

    const { image_base64 } = await req.json();
    if (!image_base64) {
      return new Response(
        JSON.stringify({ error: "Image data required" }),
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
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "image",
                  source: {
                    type: "base64",
                    media_type: "image/jpeg",
                    data: image_base64,
                  },
                },
                {
                  type: "text",
                  text: `Analyze this food photo. Identify every food item visible and estimate nutritional content.

Return ONLY a JSON array where each object has:
- "name": string (specific food name)
- "calories": number
- "protein": number (grams)
- "carbs": number (grams)
- "fat": number (grams)
- "fiber": number or null
- "sugar": number or null
- "sodium": number or null (mg)
- "serving_size": string (estimated portion)
- "confidence": number (0-100)

Be precise with portions. Return only the JSON array.`,
                },
              ],
            },
          ],
        }),
      }
    );

    if (!claudeRes.ok) {
      const errBody = await claudeRes.text();
      throw new Error(`Claude API error: ${claudeRes.status} ${errBody}`);
    }

    const claudeData = await claudeRes.json();
    const textContent = claudeData.content?.find(
      (c: any) => c.type === "text"
    );
    if (!textContent?.text) {
      throw new Error("No text response from Claude");
    }

    // Parse the JSON array from Claude's response
    const jsonStr = extractJSON(textContent.text);
    const foods = JSON.parse(jsonStr);

    const results = foods.map((food: any, i: number) => ({
      id: `scan_${Date.now()}_${i}`,
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
      source: "ai_scan",
      barcode: null,
      confidence: food.confidence || 70,
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
