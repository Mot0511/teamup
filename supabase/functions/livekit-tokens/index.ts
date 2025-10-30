import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

Deno.serve(async (req) => {
  try {
    const { uid, roomID } = await req.json()

    const apiKey = Deno.env.get("LIVEKIT_API_KEY");
    const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    const now = Math.floor(Date.now() / 1000);

    const payload = {
      iss: apiKey,
      sub: uid,
      nbf: now,
      exp: now + 60 * 60,
      video: {
        room: roomID.toString(),
        roomJoin: true,
      },
    };

    const secret = new TextEncoder().encode(apiSecret);
    
    const token = await new jose.SignJWT(payload)
        .setProtectedHeader({ alg: "HS256" })
        .sign(secret)

    return new Response(
      JSON.stringify({
        'token': token
      }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
})