import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  return new Response(
    JSON.stringify({
      currentVersion: "1.0.0",
      newFeatures: [
        "Появилось то-то то-то",
        "Исправили то-то то-то"
      ]
    }),
    { headers: { "Content-Type": "application/json" } },
  )
})