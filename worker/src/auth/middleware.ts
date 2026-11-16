/**
 * auth/middleware.ts — the Worker verifies every session token on every request that
 * carries one, before anything is forwarded to Frappe (Contract §1.1). studentId here
 * always comes from the verified token, never from the request body — Contract §2's
 * rule table: "Never student_id or phone in the JSON body."
 */

import type { Env } from "../env";
import { verifySessionToken } from "./sessionToken";

function extractBearer(req: Request): string | null {
  const header = req.headers.get("Authorization");
  if (!header) return null;
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match ? (match[1] as string).trim() : null;
}

export async function requireStudentToken(req: Request, env: Env): Promise<{ studentId: string }> {
  const token = extractBearer(req);
  const claims = await verifySessionToken(token, "student", env);
  return { studentId: (claims as { sid: string }).sid };
}

export async function requirePhoneToken(req: Request, env: Env): Promise<{ phone: string }> {
  const token = extractBearer(req);
  const claims = await verifySessionToken(token, "phone", env);
  return { phone: (claims as { phone: string }).phone };
}

export { extractBearer };