export function newId(): string {
  return crypto.randomUUID();
}

export function isValidIdempotencyKey(key: unknown): key is string {
  return typeof key === "string" && key.length >= 4 && key.length <= 200;
}

export function slugify(input: string): string {
  return (
    input
      .toLowerCase()
      .normalize("NFKD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 40) || "student"
  );
}