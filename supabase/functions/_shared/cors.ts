// Shared CORS headers for SmartBudget Edge Functions.
//
// ALLOWED_ORIGIN should be set to the site origin in production
// (e.g. https://djamalbarcha18-hue.github.io) instead of "*".
export function corsHeaders(): HeadersInit {
  return {
    "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") ?? "*",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, content-type, apikey, x-client-info",
    "Content-Type": "application/json",
  };
}

export function jsonResponse(
  body: unknown,
  status: number,
  headers: HeadersInit,
): Response {
  return new Response(JSON.stringify(body), { status, headers });
}
