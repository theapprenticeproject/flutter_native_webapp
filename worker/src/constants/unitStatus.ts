/**
 * constants/unitStatus.ts — Frappe's Unit Progress doctype, field `unit_status`
 * (Select, default "Not Started"): "Not Started\nIn Progress\nCompleted\nStopped".
 *
 * This describes a student's overall progress through one Learning Unit (video watched
 * + quiz attempted + any required submission, combined) — it is Frappe-internal
 * bookkeeping on the Unit Progress row, scoped per (student_id, unit_id, context)
 * exactly like everything else context-scoped. It is DISTINCT from a Submission row's
 * own `status` field (Pending/Processing/Completed/Failed — see storage/resign.ts) and
 * is never returned by any current Worker endpoint. It is modeled here only so the
 * Worker's type surface matches Frappe's doctype exactly, in case a future endpoint
 * (e.g. an explicit "unit status" read) needs to expose it — nothing in this codebase
 * presently reads or writes this field; Frappe owns it entirely today.
 */

export type UnitStatus = "Not Started" | "In Progress" | "Completed" | "Stopped";

export const UNIT_STATUS_OPTIONS: readonly UnitStatus[] = [
  "Not Started",
  "In Progress",
  "Completed",
  "Stopped",
] as const;

export const UNIT_STATUS_DEFAULT: UnitStatus = "Not Started";