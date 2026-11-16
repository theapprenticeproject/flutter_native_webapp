/**
 * handlers/submissionHandlers.ts — request_upload/submit_artwork accept an explicit
 * `context: "program" | "event"` field (shared default/validator —
 * parseActivityContext + cfg.DEFAULT_SUBMISSION_CONTEXT), passed through to Frappe
 * untouched. No Worker-side attempt-cap check anywhere — Frappe owns the attempt cap
 * AND first-attempt-points reward computation. The Worker still mints the signed
 * upload URL (it's the only thing holding GCS credentials) and still confirms/
 * validates the upload server-side before handing off to Frappe, strictly in that
 * order — it just never decides "has this cap been reached," only Frappe's response
 * carries that information now.
 *
 * No refreshed_token anywhere — tokens are fixed-TTL, minted once at redeem/
 * select_profile time.
 *
 * No raw storage key (object_key) is ever returned to the app on request_upload,
 * submit_artwork, list, or get — it's an internal addressing detail the client never
 * needs once the upload itself (which does need it, to know WHERE to PUT) is done. The
 * client never sees it echoed back on reads.
 *
 * There is no "skip" here anymore — skipping an assignment (program OR event) is
 * handled entirely by /submission/do_later (handlers/laterHandlers.ts), which is a
 * server-side no-op that now also accepts context.
 *
 * v5 change: submission_type accepts exactly "image" | "video" — Frappe's own
 * submission_type Select has no "audio" option (see storage/keys.ts docblock).
 *
 * FIX (applied): GCS can echo back a content-type with a charset suffix, e.g.
 * "image/webp; charset=utf-8" instead of the bare "image/webp" the Worker signed for.
 * Matching confirmation.contentType directly against CONTENT_TYPE_FOR's values would
 * then silently fail to find a match, incorrectly throwing upload_type_mismatch on a
 * perfectly valid upload. We now strip any ";..." suffix and trim whitespace before
 * comparing.
 */

import { requireStudentToken } from "../auth/middleware";
import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import type { Env, ActivityContext } from "../env";
import { invalidInput, upstreamError, parseActivityContext } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { withIdempotency } from "../cache/idempotency";
import { isValidIdempotencyKey } from "../util/ids";
import { collectTelemetry } from "../telemetry/collector";
import { config } from "../config/index";
import {
  buildObjectKey,
  mintSubmissionId,
  parseObjectKey,
  assertObjectKeyMatches,
  EXT_FOR,
  CONTENT_TYPE_FOR,
  FIELD_PATTERNS,
  type SubmissionType,
} from "../storage/keys";
import { confirmUploaded, gcsSignUpload, publicHttpsUrl } from "../storage/gcs";
import { signSubmission, type RawSubmission } from "../storage/resign";

function isValidSubmissionType(v: unknown): v is SubmissionType {
  return v === "image" || v === "video";
}

// ── request_upload ──
// NOTE: object_key IS returned here, and only here — the app needs it as the exact
// path segment to PUT the file to (it's embedded in upload_url already, but the app
// also needs the bare key to echo back on submit_artwork). This is the one endpoint
// where the key is unavoidable; it is never echoed on any READ endpoint.

interface RequestUploadBody {
  assignment_id?: string;
  submission_type?: SubmissionType;
  context?: unknown;
  _t?: unknown;
}

async function requestUpload(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as RequestUploadBody;

  if (!body.assignment_id || !FIELD_PATTERNS.assignment_id.test(body.assignment_id)) {
    throw invalidInput("assignment_id missing or malformed");
  }
  if (!isValidSubmissionType(body.submission_type)) {
    throw invalidInput("submission_type must be image or video");
  }

  const activityContext: ActivityContext = parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  // No Worker-side cap check anymore — Frappe owns check_attempt_cap entirely. The
  // Worker still needs an attempt NUMBER to build the object key's path segment, so it
  // still calls Frappe for that — it just never rejects on the Worker's own say-so; a
  // CONFLICT from Frappe here (cap already reached) is forwarded untouched.
  const cap = await fetchFrappe<{ attempt_number: number; attempts_remaining?: number }>(
    env,
    FRAPPE_METHODS.checkAttemptCap,
    {
      student_id: studentId,
      assignment_id: body.assignment_id,
      context: activityContext,
    }
  );

  const submissionId = mintSubmissionId(cfg.ID_RANDOM_CHARS);
  const ext = EXT_FOR[body.submission_type];
  const objectKey = buildObjectKey({
    assignmentId: body.assignment_id,
    studentId,
    submissionId,
    attempt: cap.attempt_number,
    ext,
  });

  const signed = await gcsSignUpload(env, objectKey, body.submission_type, cfg);

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({
    upload_url: signed.uploadUrl,
    object_key: objectKey,
    content_type: signed.contentType,
    upload_headers: signed.uploadHeaders,
    expires_in: signed.expiresIn,
    max_size_bytes: signed.maxSizeBytes,
    attempt_number: cap.attempt_number,
    attempts_remaining: cap.attempts_remaining,
    context: activityContext,
  });
}

// ── submit_artwork ──
// object_key is accepted as INPUT (the app must send back what request_upload gave it)
// but is never echoed in the response.

interface SubmitArtworkBody {
  assignment_id?: string;
  object_key?: string;
  idempotency_key?: string;
  context?: unknown;
  _t?: unknown;
}
interface SubmitArtworkFrappeResult {
  name: string;
  status: string;
  created_at: string;
  assignment_id_link: string;
  attempt_number: number;
  attempts_remaining: number;
  points_awarded?: number;
  points_total?: number;
  updated_at: number;
}

/**
 * Strips any ";..." parameter suffix (e.g. "; charset=utf-8") and surrounding
 * whitespace from a raw Content-Type header value, so it can be compared against the
 * bare MIME types in CONTENT_TYPE_FOR exactly as the Worker originally signed them.
 */
function baseContentTypeOf(rawContentType: string | null | undefined): string | undefined {
  return rawContentType?.split(";")[0]?.trim();
}

async function submitArtwork(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "write");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as SubmitArtworkBody;

  if (!body.assignment_id || !FIELD_PATTERNS.assignment_id.test(body.assignment_id)) {
    throw invalidInput("assignment_id missing or malformed");
  }
  if (!body.object_key) throw invalidInput("object_key missing");
  if (!isValidIdempotencyKey(body.idempotency_key)) throw invalidInput("idempotency_key missing or invalid");

  const objectKey = body.object_key;
  const assignmentId = body.assignment_id;
  const idempotencyKey = body.idempotency_key;
  const activityContext: ActivityContext = parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  const { result, repeat } = await withIdempotency(
    "submit_artwork",
    studentId,
    idempotencyKey,
    cfg.IDEMPOTENCY_TTL_BY_ROUTE.submit_artwork ?? cfg.DEFAULT_IDEMPOTENCY_TTL_SECONDS,
    async () => {
      // Never trust the client's key: parse its physical shape, then re-derive the
      // EXPECTED key from server-known fields and require an exact string match.
      const parsed = parseObjectKey(objectKey);
      if (parsed.assignmentId !== assignmentId) throw invalidInput("object_key assignment does not match request");
      if (parsed.studentId !== studentId) throw invalidInput("object_key does not belong to this student");

      assertObjectKeyMatches(objectKey, {
        assignmentId,
        studentId,
        submissionId: parsed.submissionId,
        attempt: parsed.attempt,
        ext: parsed.ext,
      });

      // Strictly in this order: confirm existence, then size, then content type. This
      // is Worker-only verification (it holds the GCS credentials) — it has nothing to
      // do with the attempt cap, which Frappe decides once the hand-off below happens.
      const confirmation = await confirmUploaded(env, objectKey);
      if (!confirmation.exists) throw invalidInput("upload_not_confirmed");

      // FIX: compare against the base content type (charset suffix stripped), not the
      // raw header value — GCS may echo "image/webp; charset=..." etc.
      const baseContentType = baseContentTypeOf(confirmation.contentType);
      const inferredType = (Object.entries(CONTENT_TYPE_FOR).find(([, ct]) => ct === baseContentType)?.[0] as
        | SubmissionType
        | undefined) ?? undefined;

      const cap = inferredType === "video" ? cfg.UPLOAD_MAX_BYTES_VIDEO : cfg.UPLOAD_MAX_BYTES_IMAGE;
      if (!confirmation.sizeBytes || confirmation.sizeBytes < 1 || confirmation.sizeBytes > cap) {
        throw invalidInput("upload_size_invalid");
      }
      if (!inferredType) throw invalidInput("upload_type_mismatch");

      const gcsUrl = publicHttpsUrl(env.GCS_AUTHENTICATED_BUCKET, objectKey);

      let frappeResult: SubmitArtworkFrappeResult;
      try {
        // Frappe owns: attempt-cap enforcement (CONFLICT if exceeded), the Unit
        // Progress write for the resolved (program|event) scope, and the
        // first-attempt-points reward. The Worker passes context through untouched and
        // never second-guesses whatever Frappe decides.
        frappeResult = await fetchFrappe<SubmitArtworkFrappeResult>(env, FRAPPE_METHODS.submitArtwork, {
          assignment_id: assignmentId,
          student_id: studentId,
          submission: gcsUrl,
          source: "tapapp",
          object_key: objectKey,
          submission_id: parsed.submissionId,
          attempt: parsed.attempt,
          generation: confirmation.generation,
          md5: confirmation.md5Hash,
          idempotency_key: idempotencyKey,
          context: activityContext,
        });
      } catch (err) {
        throw upstreamError(err instanceof Error ? err.message : "submission hand-off failed");
      }

      // object_key intentionally NOT included in the returned shape — it's an internal
      // addressing detail, never echoed back on a read or write response.
      return {
        name: frappeResult.name,
        status: frappeResult.status,
        created_at: frappeResult.created_at,
        assignment_id_link: frappeResult.assignment_id_link,
        attempt_number: frappeResult.attempt_number,
        attempts_remaining: frappeResult.attempts_remaining,
        points_awarded: frappeResult.points_awarded,
        points_total: frappeResult.points_total,
        context: activityContext,
        updated_at: frappeResult.updated_at,
      };
    }
  );

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({ ...result, repeat });
}

// ── list ──

interface ListBody {
  _t?: unknown;
}
interface ListFrappeResult {
  submissions: RawSubmission[];
  count: number;
  total_count: number;
  has_more: boolean;
}

async function list(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as ListBody;

  const result = await fetchFrappe<ListFrappeResult>(env, FRAPPE_METHODS.listSubmissions, { student_id: studentId });

  const signed = await Promise.all(result.submissions.map((s) => signSubmission(env, s, cfg)));

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({ submissions: signed, count: result.count, total_count: result.total_count, has_more: result.has_more });
}

// ── get ──
// v5 note: get now also accepts an optional `context` filter so the app can ask for
// "this student's submission for this assignment, within this track" when the same
// assignment_id could in principle be attempted under both program and event scopes.
// context here is ONLY a filter passed through to Frappe's get_submission lookup — it
// changes nothing about the Worker's own behavior beyond validating the two allowed
// values, exactly like every other context-carrying endpoint.

interface GetBody {
  submission_id?: string;
  context?: unknown;
  _t?: unknown;
}

async function get(
  req: Request,
  env: Env,
  ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const cfg = config(env, env as unknown as Record<string, string>, ctx);
  const body = (await req.json().catch(() => ({}))) as GetBody;
  if (!body.submission_id) throw invalidInput("submission_id missing");

  // context is OPTIONAL here (unlike the write endpoints) — omitting it means "don't
  // filter by track," since submission_id alone is already unique. When present it is
  // still validated against the same two-value enum and passed through untouched.
  const activityContext: ActivityContext | undefined =
    body.context === undefined || body.context === null || body.context === ""
      ? undefined
      : parseActivityContext(body.context, cfg.DEFAULT_SUBMISSION_CONTEXT);

  const result = await fetchFrappe<RawSubmission>(env, FRAPPE_METHODS.getSubmission, {
    student_id: studentId,
    submission_id: body.submission_id,
    ...(activityContext ? { context: activityContext } : {}),
  });

  const signed = await signSubmission(env, result, cfg);

  ctx.waitUntil(collectTelemetry(env, studentId, body._t).catch(() => {}));

  return ok({ ...signed });
}

export const submissionHandlers = { requestUpload, submitArtwork, list, get };