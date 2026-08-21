function base64UrlEncode(bytes) {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlDecode(str) {
  const padded = str
    .replace(/-/g, '+')
    .replace(/_/g, '/')
    .padEnd(str.length + ((4 - (str.length % 4)) % 4), '=');
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function encodeJson(obj) {
  return base64UrlEncode(new TextEncoder().encode(JSON.stringify(obj)));
}

function decodeJson(str) {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(str)));
}

async function importKey(secret) {
  return crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

export async function sign(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const fullPayload = { jti: crypto.randomUUID(), iat: now, ...payload };

  const headerPart = encodeJson(header);
  const payloadPart = encodeJson(fullPayload);
  const signingInput = `${headerPart}.${payloadPart}`;

  const key = await importKey(secret);
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signingInput));
  const signaturePart = base64UrlEncode(new Uint8Array(signature));

  return `${signingInput}.${signaturePart}`;
}

export async function verify(token, secret) {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('malformed_token');
  }
  const [headerPart, payloadPart, signaturePart] = parts;
  const signingInput = `${headerPart}.${payloadPart}`;

  const key = await importKey(secret);
  const signatureBytes = base64UrlDecode(signaturePart);
  const valid = await crypto.subtle.verify(
    'HMAC',
    key,
    signatureBytes,
    new TextEncoder().encode(signingInput)
  );

  if (!valid) {
    throw new Error('invalid_signature');
  }

  const payload = decodeJson(payloadPart);
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) {
    throw new Error('token_expired');
  }

  return payload;
}

export async function signAccessToken(phone, secret) {
  const now = Math.floor(Date.now() / 1000);
  return sign(
    {
      phone,
      type: 'access',
      iat: now,
      exp: now + 60 * 60 * 24 * 90,
    },
    secret
  );
}

export async function signResetToken(phone, secret) {
  const now = Math.floor(Date.now() / 1000);
  return sign({ phone, type: 'reset', iat: now, exp: now + 600 }, secret);
}

export function extractBearerToken(request) {
  for (const header of ['X-Flutter-Authorization', 'Authorization']) {
    const value = request.headers.get(header);
    if (value && value.startsWith('Bearer ')) {
      return value.slice(7);
    }
  }
  return null;
}
