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

    const { barcode } = await req.json();
    if (!barcode) {
      return new Response(
        JSON.stringify({ error: "Barcode required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Try Open Food Facts first (free, no key needed)
    const offResult = await lookupOpenFoodFacts(barcode);
    if (offResult) {
      return new Response(JSON.stringify(offResult), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fallback: try FatSecret barcode API
    const fsResult = await lookupFatSecret(barcode);
    if (fsResult) {
      return new Response(JSON.stringify(fsResult), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ error: "Product not found" }),
      {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
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

async function lookupOpenFoodFacts(barcode: string) {
  const res = await fetch(
    `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
    { headers: { "User-Agent": "Qyra-iOS/1.0" } }
  );

  if (!res.ok) return null;
  const data = await res.json();

  if (data.status !== 1 || !data.product) return null;

  const p = data.product;
  const n = p.nutriments || {};
  const servingQty = p.serving_quantity || 100;
  const scale = servingQty / 100;

  return {
    id: `off_${barcode}`,
    name: p.product_name || "Unknown Product",
    brand: p.brands || null,
    calories: (n["energy-kcal_100g"] || 0) * scale,
    protein: (n.proteins_100g || 0) * scale,
    carbs: (n.carbohydrates_100g || 0) * scale,
    fat: (n.fat_100g || 0) * scale,
    fiber: n.fiber_100g ? n.fiber_100g * scale : null,
    sugar: n.sugars_100g ? n.sugars_100g * scale : null,
    sodium: n.sodium_100g ? n.sodium_100g * scale : null,
    servingSize: p.serving_size || `${servingQty}g`,
    servingUnit: "g",
    source: "openfoodfacts",
    barcode,
    imageURL: p.image_front_url || null,
  };
}

async function lookupFatSecret(barcode: string) {
  const clientId = Deno.env.get("FATSECRET_CLIENT_ID");
  const clientSecret = Deno.env.get("FATSECRET_CLIENT_SECRET");
  if (!clientId || !clientSecret) return null;

  const tokenRes = await fetch(
    "https://oauth.fatsecret.com/connect/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=client_credentials&client_id=${clientId}&client_secret=${clientSecret}&scope=barcode`,
    }
  );

  if (!tokenRes.ok) return null;
  const { access_token } = await tokenRes.json();

  const searchRes = await fetch(
    `https://platform.fatsecret.com/rest/food/v4?format=json&barcode=${barcode}`,
    { headers: { Authorization: `Bearer ${access_token}` } }
  );

  if (!searchRes.ok) return null;
  const data = await searchRes.json();

  if (!data.food) return null;

  return {
    id: `fs_${data.food.food_id}`,
    name: data.food.food_name || "Unknown",
    brand: data.food.brand_name || null,
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: null,
    sugar: null,
    sodium: null,
    servingSize: "1 serving",
    servingUnit: "serving",
    source: "fatsecret",
    barcode,
    imageURL: null,
  };
}
