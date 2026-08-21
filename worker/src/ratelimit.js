const OTP_ROUTE_PREFIXES = ['/auth/forgot-password/send-otp'];
const GROQ_ROUTE_PREFIXES = ['/tapbuddy/chat', '/submission-review/review'];

const OTP_LIMIT = 5;
const OTP_WINDOW_SECONDS = 3600;

const GROQ_LIMIT = 20;
const GROQ_WINDOW_SECONDS = 3600;

const DEFAULT_LIMIT = 60;
const DEFAULT_WINDOW_SECONDS = 60;

function bucketFor(pathname) {
  if (OTP_ROUTE_PREFIXES.some((p) => pathname.startsWith(p))) return 'otp';
  if (GROQ_ROUTE_PREFIXES.some((p) => pathname.startsWith(p))) return 'groq';
  return 'default';
}

function limitsFor(bucket) {
  if (bucket === 'otp') return { limit: OTP_LIMIT, windowSeconds: OTP_WINDOW_SECONDS };
  if (bucket === 'groq') return { limit: GROQ_LIMIT, windowSeconds: GROQ_WINDOW_SECONDS };
  return { limit: DEFAULT_LIMIT, windowSeconds: DEFAULT_WINDOW_SECONDS };
}

function clientIp(request) {
  return request.headers.get('CF-Connecting-IP') || 'unknown';
}

export async function checkLimit(request, env) {
  const url = new URL(request.url);
  const ip = clientIp(request);
  const bucket = bucketFor(url.pathname);
  const { limit, windowSeconds } = limitsFor(bucket);
  const key = `rl:${bucket}:${ip}`;

  if (!env.KV) {
    return { allowed: true, remaining: limit, limit };
  }

  try {
    const current = await env.KV.get(key);
    const count = current ? parseInt(current, 10) : 0;

    if (count >= limit) {
      return { allowed: false, remaining: 0, limit };
    }

    if (count === 0) {
      await env.KV.put(key, '1', { expirationTtl: windowSeconds });
    } else {
      await env.KV.put(key, String(count + 1), { expirationTtl: windowSeconds });
    }

    return { allowed: true, remaining: limit - (count + 1), limit };
  } catch {
    return { allowed: true, remaining: limit, limit };
  }
}

export function rateLimitResponse(result) {
  return new Response(JSON.stringify({ success: false, error: 'rate_limited' }), {
    status: 429,
    headers: {
      'Content-Type': 'application/json',
      'Retry-After': '60',
    },
  });
}
