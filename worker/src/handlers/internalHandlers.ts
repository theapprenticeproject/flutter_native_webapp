/**
 * handlers/internalHandlers.ts — routes called only by Frappe's background promotion
 * job and the magic-link sender, never by the app. Protected by a dedicated
 * INTERNAL_API_SECRET (constant-time compare), never a student or magic-link secret.
 */

import type { Env } from "../env";
import { invalidInput, unauthorized } from "../env";
import { ok } from "../util/errors";
import { config } from "../config/index";
import { upsertGalleryItems, setGalleryItemVisibility, type PromoteRow } from "../db/gallery";
import { FIELD_PATTERNS } from "../storage/keys";
import { normalizeScopeValue } from "../db/gallery";

async function constantTimeEquals(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const aBytes = enc.encode(a);
  const bBytes = enc.encode(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= (aBytes[i] as number) ^ (bBytes[i] as number);
  return diff === 0;
}

async function requireInternalSecret(req: Request, env: Env): Promise<void> {
  const header = req.headers.get("X-Internal-Secret") ?? "";
  const expected = env.INTERNAL_API_SECRET ?? "";
  if (!expected || !(await constantTimeEquals(header, expected))) {
    throw unauthorized("invalid internal secret");
  }
}

interface IndexBatchBody {
  rows?: Array<{
    academic_year: number;
    assignment_id: string;
    student_id: string;
    submission_id: string;
    first_name?: string;
    state: string;
    district: string;
    school: string;
    grade: number;
    media_type?: "image" | "video";
    score?: number;
    promoted_at: number;
  }>;
}

function validateRow(r: NonNullable<IndexBatchBody["rows"]>[number]): PromoteRow {
  if (!FIELD_PATTERNS.assignment_id.test(r.assignment_id)) throw invalidInput("assignment_id invalid");
  if (!FIELD_PATTERNS.student_id.test(r.student_id)) throw invalidInput("student_id invalid");
  if (!FIELD_PATTERNS.submission_id.test(r.submission_id)) throw invalidInput("submission_id invalid");
  if (!Number.isInteger(r.academic_year) || r.academic_year < 2000 || r.academic_year > 2100) {
    throw invalidInput("academic_year invalid");
  }
  if (!Number.isInteger(r.grade) || r.grade < 1 || r.grade > 99) throw invalidInput("grade invalid");
  if (!r.state || !r.district || !r.school) throw invalidInput("state/district/school required");
  if (!Number.isInteger(r.promoted_at) || r.promoted_at <= 0) throw invalidInput("promoted_at invalid");

  return {
    academicYear: r.academic_year,
    assignmentId: r.assignment_id,
    studentId: r.student_id,
    submissionId: r.submission_id,
    firstName: r.first_name,
    state: normalizeScopeValue(r.state),
    district: normalizeScopeValue(r.district),
    school: normalizeScopeValue(r.school),
    grade: r.grade,
    mediaType: r.media_type ?? "image",
    score: r.score,
    promotedAt: r.promoted_at,
  };
}

async function indexBatch(req: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
  await requireInternalSecret(req, env);
  const cfg = config(env, env as unknown as Record<string, string>);

  const body = (await req.json().catch(() => ({}))) as IndexBatchBody;
  if (!Array.isArray(body.rows) || body.rows.length === 0) {
    throw invalidInput("rows missing or empty");
  }
  if (body.rows.length > cfg.INDEX_BATCH_MAX) {
    throw invalidInput(`too many rows in one batch (max ${cfg.INDEX_BATCH_MAX})`);
  }

  const validated = body.rows.map(validateRow);
  await upsertGalleryItems(env.DB, validated);

  return ok({ indexed: validated.length });
}

interface VisibilityBody {
  submission_id?: string;
  visible?: boolean;
}

async function visibility(req: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
  await requireInternalSecret(req, env);

  const body = (await req.json().catch(() => ({}))) as VisibilityBody;
  if (!body.submission_id) throw invalidInput("submission_id missing");
  if (typeof body.visible !== "boolean") throw invalidInput("visible missing or not boolean");

  await setGalleryItemVisibility(env.DB, body.submission_id, body.visible);
  return ok({ submission_id: body.submission_id, visible: body.visible });
}

export const internalHandlers = { indexBatch, visibility };