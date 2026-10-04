// JWT verification + Supabase clients for SmartBudget Edge Functions.
//
// Every request must carry the caller's Supabase session JWT
// (Authorization: Bearer <access_token>). We resolve it to a user id with the
// anon client, then use the SERVICE-ROLE client (which bypasses RLS) for the
// privileged reads/writes on the encrypted-key table.
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.117.2";

export class HttpError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}

/**
 * A project API key provided by Supabase to every Edge Function: the legacy
 * JWT key when the project has one, otherwise the new-style key from the
 * JSON map (`{"default": "sb_..."}`) Supabase provides alongside.
 */
function projectKey(legacy: string, map: string): string | undefined {
  const key = Deno.env.get(legacy);
  if (key) return key;
  try {
    const keys = JSON.parse(Deno.env.get(map) ?? "{}") as Record<
      string,
      string
    >;
    return keys["default"] ?? Object.values(keys)[0];
  } catch {
    return undefined;
  }
}

/** Service-role client — bypasses RLS. NEVER expose its key to clients. */
export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const key = projectKey("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEYS");
  if (!url || !key) throw new HttpError(500, "server_misconfigured");
  return createClient(url, key, { auth: { persistSession: false } });
}

/** Resolves the caller's JWT to a verified user id, or throws HttpError(401). */
export async function requireUserId(req: Request): Promise<string> {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new HttpError(401, "missing_token");

  const url = Deno.env.get("SUPABASE_URL");
  const anon = projectKey("SUPABASE_ANON_KEY", "SUPABASE_PUBLISHABLE_KEYS");
  if (!url || !anon) throw new HttpError(500, "server_misconfigured");

  const client = createClient(url, anon, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "invalid_token");
  return data.user.id;
}
