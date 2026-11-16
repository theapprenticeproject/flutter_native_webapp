/**
 * storage/resign.ts — Contract §2 rule table: a submission's graded result is always
 * `score`, never `grade` (grade is reserved for the student's class/standard, which
 * lives only in profile responses). attempts_remaining is present on every row now,
 * not just request_upload's response (Reference §4.3).
 *
 * `status` and `result_status` are typed directly against Frappe's own Submission
 * doctype Select field options (see the Submission doctype's JSON) — not an
 * independently-guessed string union:
 *
 *   status        (Select, no default): "Pending" | "Processing" | "Completed" | "Failed"
 *   result_status (Select, default "Pending"): "Pending" | "Success - Original" |
 *                 "Success - Flagged" | "Failed"
 *
 * There is no "Skipped" value in either field. An assignment the student hasn't
 * submitted for (including one /submission/do_later was called on) simply has no
 * Submission row at all, so it never reaches this function in the first place — the
 * Worker has nothing to sign or pass through for it.
 *
 * "Success - Flagged" means the submission passed analysis but was flagged for review
 * (e.g. suspected non-original work) — the app should treat it as a completed/scored
 * submission like "Success - Original", not as a failure.
 *
 * Separately, Frappe's Unit Progress doctype carries its own `unit_status` Select,
 * independent of a submission's status: "Not Started" | "In Progress" | "Completed" |
 * "Stopped" (default "Not Started"). This describes a student's progress through a
 * Learning Unit as a whole (video + quiz + any submission combined), not any single
 * submission row — it is not part of SignedSubmission and is never returned by any
 * endpoint in this file. See constants/unitStatus.ts for its canonical type.
 */

import type { Env } from "../env";
import type { ConfigSchema } from "../config/defaults";
import { gcsSignRead } from "./gcs";
import { buildMediaUrl } from "./r2";

/** Frappe Submission doctype, field `status` (Select, no default):
 *  "Pending\nProcessing\nCompleted\nFailed". There is no "Skipped" option — see module
 *  docblock. */
export type SubmissionStatus = "Pending" | "Processing" | "Completed" | "Failed";
export const SUBMISSION_STATUS_OPTIONS: readonly SubmissionStatus[] = [
  "Pending",
  "Processing",
  "Completed",
  "Failed",
] as const;

/** Frappe Submission doctype, field `result_status` (Select, default "Pending"):
 *  "Pending\nSuccess - Original\nSuccess - Flagged\nFailed". Set once overall feedback
 *  analysis has run; "Success - Flagged" means the submission passed analysis but was
 *  flagged for review (e.g. suspected non-original work) — the app should treat it as
 *  a completed/scored submission like "Success - Original", not as a failure. */
export type ResultStatus = "Pending" | "Success - Original" | "Success - Flagged" | "Failed";
export const RESULT_STATUS_OPTIONS: readonly ResultStatus[] = [
  "Pending",
  "Success - Original",
  "Success - Flagged",
  "Failed",
] as const;

export interface RawSubmission {
  name?: string; // absent only if no Submission record was ever created for this attempt
  assignment_id_link: string;
  status: SubmissionStatus;
  result_status?: ResultStatus;
  object_key?: string;
  media_location?: "gcs" | "r2";
  feedback_audio_key?: string | null;
  feedback_audio_location?: "gcs" | "r2" | null;
  score?: number;
  overall_feedback_translated?: string;
  attempt_number: number;
  attempts_remaining: number;
  created_at?: string;
  updated_at: number;
}

export interface SignedSubmission {
  name?: string;
  assignment_id_link: string;
  status: SubmissionStatus;
  result_status?: ResultStatus;
  view_url?: string;
  score?: number;
  overall_feedback_translated?: string;
  overall_feedback_audio_url?: string;
  attempt_number: number;
  attempts_remaining: number;
  created_at?: string;
  updated_at: number;
}

export async function signSubmission(
  env: Env,
  raw: RawSubmission,
  cfg: Pick<ConfigSchema, "MEDIA_MODE_OWN" | "PRESIGN_WINDOW_SECONDS" | "PRESIGN_EXPIRY_SECONDS">
): Promise<SignedSubmission> {
  if (!raw.object_key || !raw.media_location) {
    // Pending/early-Processing rows, or a malformed upstream row, may carry no media
    // fields yet — treat as a media-less response rather than crash the whole call.
    return {
      name: raw.name,
      assignment_id_link: raw.assignment_id_link,
      status: raw.status,
      result_status: raw.result_status,
      attempt_number: raw.attempt_number,
      attempts_remaining: raw.attempts_remaining,
      created_at: raw.created_at,
      updated_at: raw.updated_at,
    };
  }

  const [viewUrl, audioUrl] = await Promise.all([
    raw.media_location === "r2"
      ? buildMediaUrl(raw.object_key, cfg.MEDIA_MODE_OWN, env, cfg)
      : gcsSignRead(env, raw.object_key, cfg.PRESIGN_EXPIRY_SECONDS),
    raw.feedback_audio_key
      ? raw.feedback_audio_location === "r2"
        ? buildMediaUrl(raw.feedback_audio_key, "presigned", env, cfg)
        : gcsSignRead(env, raw.feedback_audio_key, cfg.PRESIGN_EXPIRY_SECONDS)
      : Promise.resolve(undefined),
  ]);

  return {
    name: raw.name,
    assignment_id_link: raw.assignment_id_link,
    status: raw.status,
    result_status: raw.result_status,
    view_url: viewUrl,
    score: raw.score,
    overall_feedback_translated: raw.overall_feedback_translated,
    overall_feedback_audio_url: audioUrl,
    attempt_number: raw.attempt_number,
    attempts_remaining: raw.attempts_remaining,
    created_at: raw.created_at,
    updated_at: raw.updated_at,
  };
}