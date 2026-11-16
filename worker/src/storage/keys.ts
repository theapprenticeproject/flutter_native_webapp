/**
 * storage/keys.ts — Contract §7.1: tapapp/{assignment_id}/{student_id}/{submission_id}-
 * {attempt}.{ext}. No academic_year, no state/district/school/grade anywhere in the
 * path — that location data moves to D1's gallery_items row at promotion time instead
 * (§7.1, §8). Fixed shape, not a configurable template: the contract freezes this
 * exactly, so there's nothing left to make a KEY_TEMPLATE config knob for.
 *
 * submission_id is a bare random mint with no "-<attempt>" suffix baked in — attempt is
 * always its own path segment, never parsed back out of submission_id.
 *
 * v5 change: `SubmissionType` — the value accepted on request_upload's
 * `submission_type` field — is restricted to exactly Frappe's own `submission_type`
 * Select options: "image\nvideo". There is no "audio" submission type a student can
 * ever request an upload for. "audio" still exists as an internal-only content type
 * (`AUDIO_CONTENT_TYPE` / `AUDIO_EXT`) used solely for signing/reading a submission's
 * own feedback_audio_key (overall_feedback_audio_url) — never something the app picks
 * or sends as submission_type.
 */

import { invalidInput } from "../env";

/** Exactly Frappe's Submission doctype `submission_type` Select options:
 *  "image\nvideo". This is the only set of values request_upload's submission_type
 *  field accepts. */
export type SubmissionType = "image" | "video";

export const EXT_FOR: Record<SubmissionType, string> = {
  image: "webp",
  video: "mp4",
};

export const CONTENT_TYPE_FOR: Record<SubmissionType, string> = {
  image: "image/webp",
  video: "video/mp4",
};

/** Internal only — never a value submission_type can hold. Used exclusively when
 *  signing/reading a submission's feedback_audio_key. */
export const AUDIO_EXT = "mp3";
export const AUDIO_CONTENT_TYPE = "audio/mpeg";

export const FIELD_PATTERNS = {
  assignment_id: /^[A-Za-z0-9_-]{3,80}$/,
  student_id: /^[A-Za-z0-9_-]{3,80}$/,
  submission_id: /^[a-z2-7]{6,16}$/,
  attempt: /^[1-9][0-9]?$/,
} as const;

export interface KeyFields {
  assignmentId: string;
  studentId: string;
  submissionId: string;
  attempt: number;
  ext: string;
}

export function buildObjectKey(fields: KeyFields): string {
  return `tapapp/${fields.assignmentId}/${fields.studentId}/${fields.submissionId}-${fields.attempt}.${fields.ext}`;
}

/** Mints a bare random submission id — no attempt suffix. Attempt is always a separate path segment. */
export function mintSubmissionId(randomChars: number): string {
  const bytes = crypto.getRandomValues(new Uint8Array(randomChars));
  const alphabet = "abcdefghijklmnopqrstuvwxyz234567";
  let out = "";
  for (let i = 0; i < randomChars; i++) {
    out += alphabet[(bytes[i] as number) % alphabet.length];
  }
  return out;
}

/**
 * Parses an object_key's physical shape (4 segments: tapapp/assignment/student/file,
 * file = submissionId-attempt.ext) without trusting any of it — caller still must
 * compare every field against server-known expected values.
 */
export interface ParsedObjectKey {
  assignmentId: string;
  studentId: string;
  submissionId: string;
  attempt: number;
  ext: string;
}

export function parseObjectKey(objectKey: string): ParsedObjectKey {
  const keyParts = objectKey.split("/");
  if (keyParts.length !== 4 || keyParts[0] !== "tapapp") {
    throw invalidInput("object_key does not match the expected shape");
  }
  const [, assignmentId, studentId, filename] = keyParts as [string, string, string, string];
  const fileMatch = /^([a-z2-7]{6,16})-([1-9][0-9]?)\.([a-z0-9]+)$/.exec(filename);
  if (!fileMatch) throw invalidInput("object_key filename does not match the expected shape");
  const [, submissionId, attemptStr, ext] = fileMatch as unknown as [string, string, string, string];

  return { assignmentId, studentId, submissionId, attempt: Number(attemptStr), ext };
}

/**
 * Re-derives the EXPECTED key from server-known fields and requires an exact string
 * match — never trusts a client-parsed key's pieces individually.
 */
export function assertObjectKeyMatches(candidate: string, expectedFields: KeyFields): void {
  if (!FIELD_PATTERNS.assignment_id.test(expectedFields.assignmentId)) throw invalidInput("assignment_id is malformed");
  if (!FIELD_PATTERNS.student_id.test(expectedFields.studentId)) throw invalidInput("student_id is malformed");
  if (!FIELD_PATTERNS.submission_id.test(expectedFields.submissionId)) throw invalidInput("submission_id is malformed");
  if (!FIELD_PATTERNS.attempt.test(String(expectedFields.attempt))) throw invalidInput("attempt is malformed");

  const expected = buildObjectKey(expectedFields);
  if (candidate !== expected) {
    throw invalidInput("object_key does not match the key request_upload issued");
  }
}