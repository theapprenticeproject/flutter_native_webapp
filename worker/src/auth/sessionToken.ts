/**
 * auth/sessionToken.ts — mints and verifies the two session tokens:
 *   - STUDENT token, scoped to one student_id — minted after /auth/redeem (for every
 *     student in the roster, embedded directly in that student's own payload object)
 *     or /auth/select_profile (fallback path, for whichever student the app switches
 *     to when its cached student token is gone).
 *   - PHONE token, scoped to one phone number — minted on every /auth/redeem, so the
 *     app can always call /auth/select_profile as a fallback to re-derive a student
 *     token for any student on the phone, regardless of how many there are.
 *
 * v5 change: tokens are no longer rolling/refreshed. Each token is minted once with a
 * FIXED expiry (ConfigSchema.STUDENT_TOKEN_TTL_SECONDS / PHONE_TOKEN_TTL_SECONDS) and
 * nothing extends it on subsequent calls — there is no more refreshed_token anywhere
 * in the response surface. When a student token expires or the app's local cache of
 * it is cleared, the app re-derives one via /auth/select_profile using its still-valid
 * phone token.
 */

import { unauthorized, invalidInput } from "../env";
import { base32Decode, base32Encode, dashGroup, hmacSign, stripDashes } from "./hmac";
import { nowSeconds } from "../util/time";

export type TokenKind = "student" | "phone";

const VERSION = 1;
const TAG_BYTES = 12;
const KIND_BYTE: Record<TokenKind, number> = { student: 0, phone: 1 };
const BYTE_TO_KIND: Record<number, TokenKind> = { 0: "student", 1: "phone" };

export interface StudentTokenClaims {
  sid: string;
}
export interface PhoneTokenClaims {
  phone: string;
}
export type TokenClaims = StudentTokenClaims | PhoneTokenClaims;

interface TokenSecrets {
  STUDENT_TOKEN_SECRET: string;
  PHONE_TOKEN_SECRET: string;
}

function secretFor(kind: TokenKind, env: TokenSecrets): string {
  return kind === "student" ? env.STUDENT_TOKEN_SECRET : env.PHONE_TOKEN_SECRET;
}

async function mintToken(kind: TokenKind, subject: string, secret: string, ttlSeconds: number): Promise<string> {
  const exp = nowSeconds() + ttlSeconds;
  const subjectBytes = new TextEncoder().encode(subject);
  if (subjectBytes.length > 255) throw invalidInput("token subject too long");

  // version(1) + kind(1) + exp(4) + subjectLen(1) + subject(n)
  const bodyLen = 1 + 1 + 4 + 1 + subjectBytes.length;
  const buf = new Uint8Array(bodyLen);
  const view = new DataView(buf.buffer);

  let offset = 0;
  buf[offset++] = VERSION;
  buf[offset++] = KIND_BYTE[kind];
  view.setUint32(offset, exp, false);
  offset += 4;
  buf[offset++] = subjectBytes.length;
  buf.set(subjectBytes, offset);

  const tagFull = await hmacSign(secret, buf);
  const tag = tagFull.slice(0, TAG_BYTES);

  const combined = new Uint8Array(buf.length + tag.length);
  combined.set(buf, 0);
  combined.set(tag, buf.length);

  return dashGroup(base32Encode(combined));
}

/** Fixed-TTL mint — ttlSeconds is required (caller passes cfg.STUDENT_TOKEN_TTL_SECONDS). */
export async function mintStudentToken(studentId: string, env: TokenSecrets, ttlSeconds: number): Promise<string> {
  return mintToken("student", studentId, secretFor("student", env), ttlSeconds);
}

/** Fixed-TTL mint — ttlSeconds is required (caller passes cfg.PHONE_TOKEN_TTL_SECONDS). */
export async function mintPhoneToken(phone: string, env: TokenSecrets, ttlSeconds: number): Promise<string> {
  return mintToken("phone", phone, secretFor("phone", env), ttlSeconds);
}

async function constantTimeTagCompare(a: Uint8Array, b: Uint8Array): Promise<boolean> {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= (a[i] as number) ^ (b[i] as number);
  return diff === 0;
}

export async function verifySessionToken(
  token: string | null,
  expectedKind: TokenKind,
  env: TokenSecrets
): Promise<TokenClaims> {
  if (!token) throw unauthorized("missing bearer token");

  const stripped = stripDashes(token.trim());
  if (!/^[A-Za-z2-7]+$/.test(stripped)) throw unauthorized("token is not in the expected format");

  let combined: Uint8Array;
  try {
    combined = base32Decode(stripped);
  } catch {
    throw unauthorized("token could not be decoded");
  }

  const HEADER_LEN = 1 + 1 + 4 + 1; // version + kind + exp + subjectLen
  if (combined.length < HEADER_LEN + TAG_BYTES) throw unauthorized("token is too short to be valid");

  const version = combined[0] as number;
  if (version !== VERSION) throw unauthorized("unsupported token version");

  const kindByte = combined[1] as number;
  const kind = BYTE_TO_KIND[kindByte];
  if (!kind || kind !== expectedKind) throw unauthorized("token kind does not match this route");

  const subjectLen = combined[HEADER_LEN - 1] as number;
  const bodyLen = HEADER_LEN + subjectLen;
  if (combined.length !== bodyLen + TAG_BYTES) throw unauthorized("token length does not match its declared payload length");

  const payloadBytes = combined.slice(0, bodyLen);
  const tag = combined.slice(bodyLen, bodyLen + TAG_BYTES);

  const secret = secretFor(kind, env);
  const expectedFull = await hmacSign(secret, payloadBytes);
  const expectedTag = expectedFull.slice(0, TAG_BYTES);
  if (!(await constantTimeTagCompare(expectedTag, tag))) {
    throw unauthorized("token signature does not verify");
  }

  const view = new DataView(payloadBytes.buffer, payloadBytes.byteOffset, payloadBytes.byteLength);
  const exp = view.getUint32(2, false);
  if (exp < nowSeconds()) throw unauthorized("token has expired");

  const subjectBytes = payloadBytes.slice(HEADER_LEN);
  const subject = new TextDecoder().decode(subjectBytes);

  return kind === "student" ? { sid: subject } : { phone: subject };
}