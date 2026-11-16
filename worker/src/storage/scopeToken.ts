/**
 * storage/scopeToken.ts — Contract §8.2's scope_cache_token: a short HMAC-signed token,
 * payload {state, district, school, grade, exp}, a dedicated GALLERY_SCOPE_TOKEN_SECRET.
 * exp is set to PROFILE_SCOPE_TTL_SECONDS at mint time so this token and the Worker's
 * own Frappe-scope Cache API entry (storage/profileScope.ts) go stale together. Opaque
 * to the app — it only ever echoes the string back, never decodes it.
 */

import { base64urlDecode, base64urlEncode, hmacSign, hmacVerify } from "../auth/hmac";
import { nowSeconds } from "../util/time";
import type { ProfileScope } from "./profileScope";

interface ScopeTokenPayload extends ProfileScope {
  exp: number;
}

export async function mintScopeToken(scope: ProfileScope, ttlSeconds: number, secret: string): Promise<string> {
  const payload: ScopeTokenPayload = { ...scope, exp: nowSeconds() + ttlSeconds };
  const encoder = new TextEncoder();
  const payloadB64 = base64urlEncode(encoder.encode(JSON.stringify(payload)));
  const sig = await hmacSign(secret, encoder.encode(payloadB64));
  return `${payloadB64}.${base64urlEncode(sig)}`;
}

/** Null on anything malformed/expired — caller treats null exactly like "no token given", never an error. */
export async function verifyScopeToken(token: string | null | undefined, secret: string): Promise<ProfileScope | null> {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 2) return null;
  const [payloadB64, sigB64] = parts as [string, string];
  try {
    const sig = base64urlDecode(sigB64);
    const verified = await hmacVerify(secret, new TextEncoder().encode(payloadB64), sig);
    if (!verified) return null;
    const payload = JSON.parse(new TextDecoder().decode(base64urlDecode(payloadB64))) as ScopeTokenPayload;
    if (payload.exp < nowSeconds()) return null;
    return { state: payload.state, district: payload.district, school: payload.school, grade: payload.grade };
  } catch {
    return null;
  }
}