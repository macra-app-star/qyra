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

    const { description, weight_kg, duration_minutes } = await req.json();
    if (!description || !weight_kg || !duration_minutes) {
      return new Response(
        JSON.stringify({
          error: "description, weight_kg, and duration_minutes required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      // Fallback: use basic MET calculation
      const fallback = basicMETEstimate(
        description,
        weight_kg,
        duration_minutes
      );
      return new Response(JSON.stringify(fallback), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
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
          max_tokens: 256,
          system:
            "You are a fitness expert. Estimate calories burned using standard MET values. Be conservative. Return ONLY a JSON object, no other text.",
          messages: [
            {
              role: "user",
              content: `User weighs ${weight_kg} kg and exercised for ${duration_minutes} minutes.
Exercise: ${description}

Return JSON: { "exercise_name": string, "duration_minutes": number, "calories_burned": number, "met_value": number }`,
            },
          ],
        }),
      }
    );

    if (!claudeRes.ok) {
      const fallback = basicMETEstimate(
        description,
        weight_kg,
        duration_minutes
      );
      return new Response(JSON.stringify(fallback), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const claudeData = await claudeRes.json();
    const textContent = claudeData.content?.find(
      (c: any) => c.type === "text"
    );

    if (!textContent?.text) {
      const fallback = basicMETEstimate(
        description,
        weight_kg,
        duration_minutes
      );
      return new Response(JSON.stringify(fallback), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const jsonStr = textContent.text
      .replace(/```json\s*/g, "")
      .replace(/```/g, "")
      .trim();
    const result = JSON.parse(jsonStr);

    return new Response(JSON.stringify(result), {
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

function basicMETEstimate(
  description: string,
  weightKg: number,
  durationMinutes: number
) {
  const desc = description.toLowerCase();
  let met = 4.0; // default moderate activity
  let name = description;

  if (desc.includes("run") || desc.includes("jog")) {
    met = 8.0;
    name = "Running";
  } else if (desc.includes("walk")) {
    met = 3.5;
    name = "Walking";
  } else if (desc.includes("cycl") || desc.includes("bike")) {
    met = 7.5;
    name = "Cycling";
  } else if (desc.includes("swim")) {
    met = 6.0;
    name = "Swimming";
  } else if (
    desc.includes("weight") ||
    desc.includes("lift") ||
    desc.includes("strength")
  ) {
    met = 5.0;
    name = "Weight Training";
  } else if (desc.includes("yoga")) {
    met = 3.0;
    name = "Yoga";
  } else if (desc.includes("hiit")) {
    met = 9.0;
    name = "HIIT";
  }

  // Calories = MET * weight(kg) * duration(hours)
  const caloriesBurned = met * weightKg * (durationMinutes / 60);

  return {
    exercise_name: name,
    duration_minutes: durationMinutes,
    calories_burned: Math.round(caloriesBurned),
    met_value: met,
  };
}
