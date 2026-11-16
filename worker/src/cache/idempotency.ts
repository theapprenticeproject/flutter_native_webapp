/**
 * cache/idempotency.ts — Contract §2 rule table: every write takes idempotency_key,
 * unique per action-attempt. The same key sent twice performs the work once and
 * returns the first result again, with "repeat": true.
 */

const NAMESPACE = "idempotency";

export interface IdempotentResult<T> {
  result: T;
  repeat: boolean;
}

export async function withIdempotency<T>(
  route: string,
  studentId: string,
  idempotencyKey: string,
  ttlSeconds: number,
  fn: () => Promise<T>
): Promise<IdempotentResult<T>> {
  const cache = await caches.open(NAMESPACE);
  const key = new Request(
    `https://idem.internal/${encodeURIComponent(route)}/${encodeURIComponent(studentId)}/${encodeURIComponent(idempotencyKey)}`
  );

  const cached = await cache.match(key);
  if (cached) {
    const stored = (await cached.json()) as { result: T };
    return { result: stored.result, repeat: true };
  }

  const result = await fn();

  await cache.put(key, new Response(JSON.stringify({ result }), { headers: { "Cache-Control": `max-age=${ttlSeconds}` } }));
  return { result, repeat: false };
}