function resolveOrigin(request, env) {
  const origin = request.headers.get('Origin');
  if (!origin) return '*';
  const allowedRaw = (env.ALLOWED_ORIGINS || '').trim();
  if (allowedRaw === '*' || allowedRaw === '') return origin;
  const allowed = allowedRaw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  return allowed.includes(origin) ? origin : null;
}

export function corsHeaders(request, env) {
  const origin = resolveOrigin(request, env);
  const headers = {
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Flutter-Authorization',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
  if (origin) {
    headers['Access-Control-Allow-Origin'] = origin;
  }
  return headers;
}

export function applyCors(response, request, env) {
  const headers = new Headers(response.headers);
  const cors = corsHeaders(request, env);
  for (const key in cors) {
    headers.set(key, cors[key]);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export function handlePreflight(request, env) {
  return new Response(null, {
    status: 204,
    headers: corsHeaders(request, env),
  });
}
