import { verify, signAccessToken, signResetToken, extractBearerToken } from './jwt.js';

const REFRESH_THRESHOLD_SECONDS = 60 * 60 * 24 * 30;

export async function validateAccessToken(request, env, expectedPhone) {
  const token = extractBearerToken(request);
  if (!token) {
    return { valid: false, error: 'missing_token' };
  }

  let payload;
  try {
    payload = await verify(token, env.JWT_SECRET);
  } catch (err) {
    return { valid: false, error: err.message || 'invalid_or_expired_token' };
  }

  if (payload.type !== 'access') {
    return { valid: false, error: 'invalid_token_type' };
  }

  if (expectedPhone && payload.phone !== expectedPhone) {
    return { valid: false, error: 'token_phone_mismatch' };
  }

  return { valid: true, payload };
}

export async function validateResetToken(request, env, expectedPhone) {
  const token = extractBearerToken(request);
  if (!token) {
    return { valid: false, error: 'missing_token' };
  }

  let payload;
  try {
    payload = await verify(token, env.JWT_SECRET);
  } catch (err) {
    return { valid: false, error: err.message || 'invalid_or_expired_token' };
  }

  if (payload.type !== 'reset') {
    return { valid: false, error: 'invalid_token_type' };
  }

  if (expectedPhone && payload.phone !== expectedPhone) {
    return { valid: false, error: 'token_phone_mismatch' };
  }

  return { valid: true, payload };
}

export function tokenNeedsRefresh(payload) {
  if (!payload.exp) return false;
  const now = Math.floor(Date.now() / 1000);
  return payload.exp - now < REFRESH_THRESHOLD_SECONDS;
}

export async function issueAccessToken(phone, env) {
  return signAccessToken(phone, env.JWT_SECRET);
}

export async function issueResetToken(phone, env) {
  return signResetToken(phone, env.JWT_SECRET);
}

export function unauthorizedResponse(error) {
  return new Response(JSON.stringify({ success: false, error }), {
    status: 401,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function forbiddenResponse(error) {
  return new Response(JSON.stringify({ success: false, error }), {
    status: 403,
    headers: { 'Content-Type': 'application/json' },
  });
}
