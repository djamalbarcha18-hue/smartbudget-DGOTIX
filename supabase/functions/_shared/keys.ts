// Per-user Gemini API key storage (BYOK), encrypted at rest.
//
// All access here uses the service-role client, so it must ONLY be called from
// an Edge Function AFTER the caller's user id has been verified (see auth.ts).
import { serviceClient } from "./auth.ts";
import { decryptSecret, encryptSecret } from "./crypto.ts";

const TABLE = "user_ai_keys";

export async function saveGeminiKey(
  userId: string,
  apiKey: string,
): Promise<void> {
  const ciphertext = await encryptSecret(apiKey);
  const { error } = await serviceClient().from(TABLE).upsert({
    user_id: userId,
    provider: "gemini",
    ciphertext,
    updated_at: new Date().toISOString(),
  });
  if (error) throw new Error(error.message);
}

export async function deleteGeminiKey(userId: string): Promise<void> {
  const { error } = await serviceClient()
    .from(TABLE)
    .delete()
    .eq("user_id", userId);
  if (error) throw new Error(error.message);
}

export async function hasGeminiKey(userId: string): Promise<boolean> {
  const { data } = await serviceClient()
    .from(TABLE)
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();
  return !!data;
}

/** Returns the decrypted key, or null if the user has not set one. */
export async function loadGeminiKey(userId: string): Promise<string | null> {
  const { data } = await serviceClient()
    .from(TABLE)
    .select("ciphertext")
    .eq("user_id", userId)
    .maybeSingle();
  if (!data?.ciphertext) return null;
  return await decryptSecret(data.ciphertext as string);
}
