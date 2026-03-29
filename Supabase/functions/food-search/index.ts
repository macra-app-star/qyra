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

    const { query } = await req.json();
    if (!query || query.length < 2) {
      return new Response(JSON.stringify([]), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fan out to USDA + FatSecret in parallel
    const [usdaResults, fatSecretResults] = await Promise.allSettled([
      searchUSDA(query),
      searchFatSecret(query),
    ]);

    const usda =
      usdaResults.status === "fulfilled" ? usdaResults.value : [];
    const fatSecret =
      fatSecretResults.status === "fulfilled" ? fatSecretResults.value : [];

    // Merge and deduplicate by name similarity
    const merged = [...fatSecret, ...usda]
      .sort(
        (a, b) => relevanceScore(b, query) - relevanceScore(a, query)
      )
      .slice(0, 30);

    return new Response(JSON.stringify(merged), {
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

interface FoodItem {
  id: string;
  name: string;
  brand: string | null;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number | null;
  sugar: number | null;
  sodium: number | null;
  servingSize: string;
  servingUnit: string;
  source: string;
  barcode: string | null;
}

async function searchUSDA(query: string): Promise<FoodItem[]> {
  const apiKey = Deno.env.get("USDA_API_KEY");
  if (!apiKey) return [];

  const res = await fetch(
    `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${apiKey}&query=${encodeURIComponent(query)}&pageSize=15&dataType=Foundation,SR%20Legacy,Branded`
  );

  if (!res.ok) return [];
  const data = await res.json();

  return (data.foods || []).map((food: any) => {
    const nutrients = food.foodNutrients || [];
    const getNutrient = (id: number) =>
      nutrients.find((n: any) => n.nutrientId === id)?.value ?? 0;

    return {
      id: `usda_${food.fdcId}`,
      name: food.description || "Unknown",
      brand: food.brandName || food.brandOwner || null,
      calories: getNutrient(1008),
      protein: getNutrient(1003),
      carbs: getNutrient(1005),
      fat: getNutrient(1004),
      fiber: getNutrient(1079) || null,
      sugar: getNutrient(2000) || null,
      sodium: getNutrient(1093) ? getNutrient(1093) / 1000 : null,
      servingSize: food.servingSize
        ? `${food.servingSize}${food.servingSizeUnit || "g"}`
        : "100g",
      servingUnit: food.servingSizeUnit || "g",
      source: "usda",
      barcode: null,
    };
  });
}

async function searchFatSecret(query: string): Promise<FoodItem[]> {
  const clientId = Deno.env.get("FATSECRET_CLIENT_ID");
  const clientSecret = Deno.env.get("FATSECRET_CLIENT_SECRET");
  if (!clientId || !clientSecret) return [];

  // OAuth 2.0 client credentials
  const tokenRes = await fetch(
    "https://oauth.fatsecret.com/connect/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=client_credentials&client_id=${clientId}&client_secret=${clientSecret}&scope=basic`,
    }
  );

  if (!tokenRes.ok) return [];
  const { access_token } = await tokenRes.json();

  const searchRes = await fetch(
    `https://platform.fatsecret.com/rest/foods/search/v1?format=json&search_expression=${encodeURIComponent(query)}&max_results=20`,
    {
      headers: { Authorization: `Bearer ${access_token}` },
    }
  );

  if (!searchRes.ok) return [];
  const searchData = await searchRes.json();

  const foods = searchData?.foods?.food;
  if (!Array.isArray(foods)) return [];

  return foods.map((food: any) => {
    // FatSecret returns nutrition in a description string
    const desc = food.food_description || "";
    const parseNum = (pattern: RegExp) => {
      const match = desc.match(pattern);
      return match ? parseFloat(match[1]) : 0;
    };

    return {
      id: `fs_${food.food_id}`,
      name: food.food_name || "Unknown",
      brand: food.brand_name || null,
      calories: parseNum(/Calories:\s*([\d.]+)/),
      protein: parseNum(/Protein:\s*([\d.]+)/),
      carbs: parseNum(/Carbs:\s*([\d.]+)/),
      fat: parseNum(/Fat:\s*([\d.]+)/),
      fiber: null,
      sugar: null,
      sodium: null,
      servingSize: desc.split("-")[0]?.trim() || "1 serving",
      servingUnit: "serving",
      source: "fatsecret",
      barcode: null,
    };
  });
}

function relevanceScore(item: FoodItem, query: string): number {
  const name = item.name.toLowerCase();
  const q = query.toLowerCase();
  let score = 0;
  if (name === q) score += 100;
  else if (name.startsWith(q)) score += 80;
  else if (name.includes(q)) score += 50;
  if (item.brand) score += 5;
  if (item.source === "fatsecret") score += 10;
  return score;
}
