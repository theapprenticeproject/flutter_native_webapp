import { base64urlEncode } from "../auth/hmac";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  private_key_id?: string;
}

export function parseServiceAccountJson(json: string): ServiceAccount {
  const parsed = JSON.parse(json) as Partial<ServiceAccount>;
  if (!parsed.client_email || !parsed.private_key) {
    throw new Error("service account JSON missing client_email or private_key");
  }
  return parsed as ServiceAccount;
}

export async function importRsaPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
}

export async function getGoogleAccessToken(sa: ServiceAccount, scope: string): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;
  const claims = { iss: sa.client_email, scope, aud: "https://oauth2.googleapis.com/token", iat, exp };

  const encoder = new TextEncoder();
  const headerB64 = base64urlEncode(encoder.encode(JSON.stringify(header)));
  const claimsB64 = base64urlEncode(encoder.encode(JSON.stringify(claims)));
  const signingInput = `${headerB64}.${claimsB64}`;

  const key = await importRsaPrivateKey(sa.private_key);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(signingInput));
  const jwt = `${signingInput}.${base64urlEncode(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Google OAuth2 token exchange failed: ${res.status} ${text}`);
  }
  const json = (await res.json()) as { access_token: string };
  return json.access_token;
}

// Token cached per (service_account_email, scope) in the Worker Cache API — a token is
// valid 3600s; without this, every confirmUploaded/BQ-flush call mints a fresh one.
const TOKEN_CACHE_NAMESPACE = "google-oauth-token";
const TOKEN_SAFETY_MARGIN_SECONDS = 120;

export async function getGoogleAccessTokenCached(sa: ServiceAccount, scope: string): Promise<string> {
  const cache = await caches.open(TOKEN_CACHE_NAMESPACE);
  const cacheKey = new Request(
    `https://oauth-token.internal/${encodeURIComponent(sa.client_email)}/${encodeURIComponent(scope)}`
  );

  const hit = await cache.match(cacheKey);
  if (hit) return hit.text();

  const token = await getGoogleAccessToken(sa, scope);
  const ttl = 3600 - TOKEN_SAFETY_MARGIN_SECONDS;
  await cache.put(cacheKey, new Response(token, { headers: { "Cache-Control": `max-age=${ttl}` } }));
  return token;
}