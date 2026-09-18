// AES-256-GCM encryption for user API keys, using the Web Crypto API.
//
// The symmetric key comes from KEY_ENCRYPTION_SECRET (a 32-byte value, base64).
// Generate one with:  openssl rand -base64 32
// The database only ever stores ciphertext produced here — plaintext keys never
// touch Postgres, logs, or the client after they are submitted once.
import { HttpError } from "./auth.ts";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function bytesToBase64(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

async function importKey(): Promise<CryptoKey> {
  const secret = Deno.env.get("KEY_ENCRYPTION_SECRET");
  if (!secret) throw new HttpError(500, "server_misconfigured");
  const raw = base64ToBytes(secret);
  if (raw.length !== 32) throw new HttpError(500, "bad_encryption_secret");
  return crypto.subtle.importKey("raw", raw, { name: "AES-GCM" }, false, [
    "encrypt",
    "decrypt",
  ]);
}

/** Returns "<ivB64>:<ciphertextB64>". */
export async function encryptSecret(plaintext: string): Promise<string> {
  const key = await importKey();
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const cipher = new Uint8Array(
    await crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      key,
      encoder.encode(plaintext),
    ),
  );
  return `${bytesToBase64(iv)}:${bytesToBase64(cipher)}`;
}

export async function decryptSecret(payload: string): Promise<string> {
  const key = await importKey();
  const [ivB64, cipherB64] = payload.split(":");
  if (!ivB64 || !cipherB64) throw new HttpError(500, "corrupt_ciphertext");
  const plain = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: base64ToBytes(ivB64) },
    key,
    base64ToBytes(cipherB64),
  );
  return decoder.decode(plain);
}
