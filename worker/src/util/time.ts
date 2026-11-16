export function nowSeconds(): number {
  return Math.floor(Date.now() / 1000);
}

export function nowMs(): number {
  return Date.now();
}

export function utcDateString(d: Date = new Date()): string {
  return d.toISOString().slice(0, 10);
}