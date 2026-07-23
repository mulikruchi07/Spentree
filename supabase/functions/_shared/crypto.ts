// Shared crypto helpers used by both encrypt-transaction and decrypt-transaction.
// AES-256-GCM throughout. Master key wraps a per-user Data Encryption Key (DEK).

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---- base64 helpers (loop-based, safe for any length, no call-stack risk) ----

export function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

export function base64ToBytes(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

// ---- master key ----

export async function importMasterKey(): Promise<CryptoKey> {
  const b64 = Deno.env.get("TRANSACTION_ENC_KEY");
  if (!b64) {
    throw new Error("TRANSACTION_ENC_KEY secret is not set on this project.");
  }
  const raw = base64ToBytes(b64);
  if (raw.length !== 32) {
    throw new Error(
      `TRANSACTION_ENC_KEY must decode to exactly 32 bytes for AES-256, got ${raw.length}.`
    );
  }
  return crypto.subtle.importKey("raw", raw, "AES-GCM", false, [
    "encrypt",
    "decrypt",
  ]);
}

// ---- per-field encrypt / decrypt ----
// Each encrypted field is stored as base64(iv[12 bytes] + ciphertext).

export async function encryptField(
  key: CryptoKey,
  plaintext: string
): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plaintext);
  const ciphertextBuf = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    encoded
  );
  const ciphertext = new Uint8Array(ciphertextBuf);
  const combined = new Uint8Array(iv.length + ciphertext.length);
  combined.set(iv, 0);
  combined.set(ciphertext, iv.length);
  return bytesToBase64(combined);
}

export async function decryptField(
  key: CryptoKey,
  packedB64: string
): Promise<string> {
  const combined = base64ToBytes(packedB64);
  if (combined.length < 13) {
    throw new Error("Encrypted field is malformed (too short).");
  }
  const iv = combined.slice(0, 12);
  const ciphertext = combined.slice(12);
  const plainBuf = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv },
    key,
    ciphertext
  );
  return new TextDecoder().decode(plainBuf);
}

// ---- per-user DEK: create on first use, unwrap on every subsequent call ----

export async function getOrCreateUserDek(
  adminClient: any,
  userId: string,
  masterKey: CryptoKey
): Promise<CryptoKey> {
  const { data: userRow, error: fetchError } = await adminClient
    .from("users")
    .select("wrapped_dek")
    .eq("id", userId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(`Could not read wrapped_dek: ${fetchError.message}`);
  }

  if (userRow?.wrapped_dek) {
    return unwrapDek(userRow.wrapped_dek, masterKey);
  }

  // No DEK yet for this user — mint one now.
  const rawDek = crypto.getRandomValues(new Uint8Array(32));
  const dek = await crypto.subtle.importKey("raw", rawDek, "AES-GCM", true, [
    "encrypt",
    "decrypt",
  ]);

  const iv = crypto.getRandomValues(new Uint8Array(12));
  const wrappedBuf = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    masterKey,
    rawDek
  );
  const wrapped = new Uint8Array(wrappedBuf);
  const combined = new Uint8Array(iv.length + wrapped.length);
  combined.set(iv, 0);
  combined.set(wrapped, iv.length);
  const wrappedB64 = bytesToBase64(combined);

  const { error: updateError } = await adminClient
    .from("users")
    .upsert({ id: userId, wrapped_dek: wrappedB64 });

  if (updateError) {
    throw new Error(`Could not store new wrapped_dek: ${updateError.message}`);
  }

  return dek;
}

async function unwrapDek(
  wrappedB64: string,
  masterKey: CryptoKey
): Promise<CryptoKey> {
  const combined = base64ToBytes(wrappedB64);
  if (combined.length < 13) {
    throw new Error("wrapped_dek is malformed (too short).");
  }
  const iv = combined.slice(0, 12);
  const ciphertext = combined.slice(12);
  const rawDekBuf = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv },
    masterKey,
    ciphertext
  );
  return crypto.subtle.importKey("raw", rawDekBuf, "AES-GCM", true, [
    "encrypt",
    "decrypt",
  ]);
}