export interface TurnCheckResult {
  allowed: boolean;
  count: number;
  maxCalls: number;
}

const NAMESPACE = "turn-budget";

export async function checkAndIncrementTurn(
  identityKey: string,
  turnId: string,
  routePath: string,
  turnBudgets: Readonly<Record<string, number>>,
  defaultBudget: number,
  windowSeconds: number
): Promise<TurnCheckResult> {
  const maxCalls = turnBudgets[routePath] ?? defaultBudget;
  const cache = await caches.open(NAMESPACE);
  const key = new Request(`https://turn.internal/${encodeURIComponent(identityKey)}/${encodeURIComponent(turnId)}`);

  const hit = await cache.match(key);
  const count = hit ? Number(await hit.text()) : 0;

  if (count >= maxCalls) {
    return { allowed: false, count, maxCalls };
  }

  const nextCount = count + 1;
  await cache.put(key, new Response(String(nextCount), { headers: { "Cache-Control": `max-age=${windowSeconds}` } }));
  return { allowed: true, count: nextCount, maxCalls };
}