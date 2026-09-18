// JWT verification + Supabase clients for SmartBudget Edge Functions.
//
// Every request must carry the caller's Supabase session JWT
// (Authorization: Bearer <access_token>). We resolve it to a user id with the
// anon client, then use the SERVICE-ROLE client (which bypasses RLS) for the
// privileged reads/writes on the encrypted-key table.
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

export class HttpError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}

/** Service-role client — bypasses RLS. NEVER expose its key to clients. */
export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new HttpError(500, "server_misconfigured");
  return createClient(url, key, { auth: { persistSession: false } });
}

/** Resolves the caller's JWT to a verified user id, or throws HttpError(401). */
export async function requireUserId(req: Request): Promise<string> {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new HttpError(401, "missing_token");

  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anon) throw new HttpError(500, "server_misconfigured");

  const client = createClient(url, anon, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "invalid_token");
  return data.user.id;
}
