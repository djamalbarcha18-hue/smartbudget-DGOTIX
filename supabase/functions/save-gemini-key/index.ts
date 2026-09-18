// SmartBudget — save-gemini-key (Supabase Edge Function, Deno).
//
// BYOK key management for a single signed-in user. The plaintext key is
// submitted once, encrypted with AES-256-GCM, and stored as ciphertext. It is
// never returned to any client afterwards — the client can only learn WHETHER a
// key is set.
//
// POST-only, action-based (keeps the Flutter client on the default invoke path):
//   { "action": "status" }            -> { hasKey: boolean }
//   { "action": "save", "apiKey":"…" } -> { ok: true, hasKey: true }
//   { "action": "delete" }            -> { ok: true, hasKey: false }
//
// Deploy:  supabase functions deploy save-gemini-key
// Secrets: supabase secrets set KEY_ENCRYPTION_SECRET="$(openssl rand -base64 32)"
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId } from "../_shared/auth.ts";
import { deleteGeminiKey, hasGeminiKey, saveGeminiKey } from "../_shared/keys.ts";

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? "status");

    switch (action) {
      case "status":
        return jsonResponse({ hasKey: await hasGeminiKey(userId) }, 200, cors);

      case "delete":
        await deleteGeminiKey(userId);
        return jsonResponse({ ok: true, hasKey: false }, 200, cors);

      case "save": {
        const apiKey = String(body?.apiKey ?? "").trim();
        // Gemini keys are ~39 chars; reject obvious junk early.
        if (apiKey.length < 20) {
          return jsonResponse({ ok: false, error: "invalid_key" }, 400, cors);
        }
        await saveGeminiKey(userId, apiKey);
        return jsonResponse({ ok: true, hasKey: true }, 200, cors);
      }

      default:
        return jsonResponse({ error: "bad_action" }, 400, cors);
    }
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, cors);
  }
});
