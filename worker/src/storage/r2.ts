/**
 * storage/r2.ts — true direct-to-R2 presigned GET via SigV4 against R2's S3-compatible
 * endpoint. The client fetches bytes straight from R2's edge; the Worker is never in
 * the read path, which matters since gallery reads happen far more often than writes.
 */

import type { ConfigSchema } from "../config/defaults";

export interface R2SignEnv {
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_ACCOUNT_ID: string;
  R2_SUBMISSIONS_BUCKET_NAME: string;
}

const R2_REGION = "auto";
const R2_SERVICE = "s3";

function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function sha256Hex(data: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(data));
  return toHex(digest);
}
async function hmacRaw(keyBytes: Uint8Array, data: string): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey("raw", keyBytes, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
  return new Uint8Array(sig);
}
function dateStamp(d: Date): string {
  return d.toISOString().slice(0, 10).replace(/-/g, "");
}
function amzDate(d: Date): string {
  return d.toISOString().replace(/[:-]|\.\d{3}/g, "");
}

// Memoised per (secret prefix, dateStamp) in module scope — a 50-image gallery page
// signs with one key derivation, not 50.
const signingKeyCache = new Map<string, Uint8Array>();

async function derivedSigningKey(secretAccessKey: string, dstamp: string): Promise<Uint8Array> {
  const cacheKey = `${secretAccessKey.slice(0, 8)}:${dstamp}`;
  const cached = signingKeyCache.get(cacheKey);
  if (cached) return cached;

  const encoder = new TextEncoder();
  const kDate = await hmacRaw(encoder.encode(`AWS4${secretAccessKey}`), dstamp);
  const kRegion = await hmacRaw(kDate, R2_REGION);
  const kService = await hmacRaw(kRegion, R2_SERVICE);
  const kSigning = await hmacRaw(kService, "aws4_request");

  if (signingKeyCache.size > 4) signingKeyCache.clear();
  signingKeyCache.set(cacheKey, kSigning);
  return kSigning;
}

/**
 * Signs on the START of the current PRESIGN_WINDOW_SECONDS window, not "now" — keeps
 * the URL string identical for the whole window so the app's URL-keyed image cache
 * actually caches, and guarantees every URL has at least (expiry - window) seconds left.
 */
export async function r2SignGetDirect(
  key: string,
  env: R2SignEnv,
  cfg: Pick<ConfigSchema, "PRESIGN_WINDOW_SECONDS" | "PRESIGN_EXPIRY_SECONDS">
): Promise<string> {
  const windowMs = cfg.PRESIGN_WINDOW_SECONDS * 1000;
  const windowStart = new Date(Math.floor(Date.now() / windowMs) * windowMs);

  const dstamp = dateStamp(windowStart);
  const amz = amzDate(windowStart);
  const credentialScope = `${dstamp}/${R2_REGION}/${R2_SERVICE}/aws4_request`;
  const credential = `${env.R2_ACCESS_KEY_ID}/${credentialScope}`;
  const host = `${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const canonicalUri = `/${env.R2_SUBMISSIONS_BUCKET_NAME}/${key.split("/").map(encodeURIComponent).join("/")}`;

  const query: Record<string, string> = {
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": credential,
    "X-Amz-Date": amz,
    "X-Amz-Expires": String(cfg.PRESIGN_EXPIRY_SECONDS),
    "X-Amz-SignedHeaders": "host",
  };
  const canonicalQuery = Object.keys(query)
    .sort()
    .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(query[k] as string)}`)
    .join("&");

  const canonicalHeaders = `host:${host}\n`;
  const canonicalRequest = ["GET", canonicalUri, canonicalQuery, canonicalHeaders, "host", "UNSIGNED-PAYLOAD"].join("\n");
  const hashedCanonicalRequest = await sha256Hex(canonicalRequest);
  const stringToSign = ["AWS4-HMAC-SHA256", amz, credentialScope, hashedCanonicalRequest].join("\n");

  const signingKey = await derivedSigningKey(env.R2_SECRET_ACCESS_KEY, dstamp);
  const signatureBytes = await hmacRaw(signingKey, stringToSign);
  const signature = toHex(signatureBytes.buffer as ArrayBuffer);

  return `https://${host}${canonicalUri}?${canonicalQuery}&X-Amz-Signature=${signature}`;
}

export async function buildMediaUrl(
  key: string,
  mode: "public" | "presigned",
  env: R2SignEnv,
  cfg: Pick<ConfigSchema, "PRESIGN_WINDOW_SECONDS" | "PRESIGN_EXPIRY_SECONDS">
): Promise<string> {
  if (mode === "public") {
    return `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${env.R2_SUBMISSIONS_BUCKET_NAME}/${key
      .split("/")
      .map(encodeURIComponent)
      .join("/")}`;
  }
  return r2SignGetDirect(key, env, cfg);
}