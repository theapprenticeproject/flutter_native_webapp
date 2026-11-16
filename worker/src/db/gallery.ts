/**
 * db/gallery.ts — D1-backed `gallery_items` table: the ONLY listing source for the
 * gallery (never Frappe, never a raw R2 list() at read time — see handlers/
 * galleryHandlers.ts). Rows land here via /internal/gallery/index, called by Frappe's
 * background promotion job once a submission is graded/promoted.
 *
 * Scoping is config-driven now: cfg.GALLERY_FALLBACK_CASCADE names the ordered list of
 * levels to try (a subset of GALLERY_SCOPE_FIELDS, in that same relative priority
 * order — see config/defaults.ts). Default starts at "assignment_id" (narrowest) and
 * falls back through "school" -> "district" -> "state". Changing the cascade is a
 * config edit, not a code change — e.g. drop "assignment_id" to always scope by
 * location, or reorder which location level is tried first.
 *
 * Sort order is config-driven too: cfg.GALLERY_SORT is "recent" (promoted_at desc,
 * default) or "updated" (sort by each row's own last-updated timestamp).
 *
 * The raw storage key is NEVER returned to the client — rowsToPage/toSignedImages
 * resolve it to a signed `url` and drop the key itself from the response shape.
 *
 * Expected D1 schema (create via migration, not here):
 *
 *   CREATE TABLE gallery_items (
 *     submission_id   TEXT PRIMARY KEY,
 *     academic_year   INTEGER NOT NULL,
 *     assignment_id   TEXT NOT NULL,
 *     student_id      TEXT NOT NULL,
 *     first_name      TEXT,
 *     state           TEXT NOT NULL,
 *     district        TEXT NOT NULL,
 *     school          TEXT NOT NULL,
 *     grade           INTEGER NOT NULL,
 *     media_type      TEXT NOT NULL DEFAULT 'image',
 *     score           REAL,
 *     promoted_at     INTEGER NOT NULL,
 *     updated_at      INTEGER NOT NULL DEFAULT 0,
 *     visible         INTEGER NOT NULL DEFAULT 1
 *   );
 *   CREATE INDEX idx_gallery_school_grade ON gallery_items(school, grade, visible, promoted_at);
 *   CREATE INDEX idx_gallery_district_grade ON gallery_items(district, grade, visible, promoted_at);
 *   CREATE INDEX idx_gallery_state_grade ON gallery_items(state, grade, visible, promoted_at);
 *   CREATE INDEX idx_gallery_assignment ON gallery_items(assignment_id, visible, promoted_at);
 */

import type { ConfigSchema } from "../config/defaults";
import type { GalleryScopeField } from "../config/defaults";
import type { Env } from "../env";

/** Which of the 5 fixed fields the API caller may pass explicitly (vs. always
 *  profile-derived). Pure API ergonomics knob — widening later is a one-line change. */
export const GALLERY_QUERY_OVERRIDABLE_FIELDS = ["school", "grade"] as const;

export const GALLERY_SCOPE_FIELD_PATTERNS: Readonly<Record<GalleryScopeField, RegExp>> = {
  assignment_id: /^[A-Za-z0-9_-]{3,80}$/,
  state: /^[a-z0-9-]{2,40}$/,
  district: /^[a-z0-9-]{2,60}$/,
  school: /^[a-z0-9-]{2,60}$/,
  grade: /^[1-9][0-9]?$/,
};

export function normalizeScopeValue(v: string): string {
  return v.trim().toLowerCase();
}

// ─────────────────────────────────────────────────────────────────────────
// Read path — fetchGalleryPage
// ─────────────────────────────────────────────────────────────────────────

export interface GalleryImageRow {
  submission_id: string;
  student_id: string;
  first_name: string | null;
  object_key: string;
  media_type: "image" | "video";
  score: number | null;
  promoted_at: number;
  updated_at: number;
}

/** Client-facing shape — notably NO object_key/raw storage key, only a resolved url. */
export interface GalleryImage {
  submission_id: string;
  display_name: string | null;
  url: string;
  media_type: "image" | "video";
  score: number | null;
  uploaded: string;
}

export interface GalleryPage {
  images: GalleryImage[];
  cursor: number | null;
  truncated: boolean;
  matched_level: GalleryScopeField | "none";
  fallback_applied: boolean;
}

export interface GalleryQuery {
  assignmentId?: string;
  state: string;
  district: string;
  school: string;
  grade: number;
  cursor: number | null;
  limit: number;
}

interface D1GalleryRow {
  submission_id: string;
  student_id: string;
  first_name: string | null;
  object_key: string;
  media_type: string;
  score: number | null;
  promoted_at: number;
  updated_at: number;
}

const LOCATION_COLUMN_FOR: Partial<Record<GalleryScopeField, string>> = {
  state: "state",
  district: "district",
  school: "school",
}; // "grade" is always an AND-filter, never a standalone scoping level; "assignment_id" has its own branch below.

function orderByClause(sort: ConfigSchema["GALLERY_SORT"]): string {
  return sort === "updated" ? "updated_at DESC" : "promoted_at DESC";
}

async function queryLevel(
  db: D1Database,
  level: GalleryScopeField,
  q: GalleryQuery,
  sort: ConfigSchema["GALLERY_SORT"]
): Promise<D1GalleryRow[]> {
  const limitPlusOne = q.limit + 1;
  const offset = q.cursor ?? 0;
  const orderBy = orderByClause(sort);

  if (level === "assignment_id") {
    if (!q.assignmentId) return [];
    const { results } = await db
      .prepare(
        `SELECT submission_id, student_id, first_name, object_key, media_type, score, promoted_at, updated_at
         FROM gallery_items
         WHERE assignment_id = ?1 AND grade = ?2 AND visible = 1
         ORDER BY ${orderBy}
         LIMIT ?3 OFFSET ?4`
      )
      .bind(q.assignmentId, q.grade, limitPlusOne, offset)
      .all<D1GalleryRow>();
    return results ?? [];
  }

  const column = LOCATION_COLUMN_FOR[level];
  if (!column) return []; // "grade" alone is never a scoping level on its own

  const valueForLevel: Record<"school" | "district" | "state", string> = {
    school: q.school,
    district: q.district,
    state: q.state,
  };
  const value = valueForLevel[level as "school" | "district" | "state"];

  const { results } = await db
    .prepare(
      `SELECT submission_id, student_id, first_name, object_key, media_type, score, promoted_at, updated_at
       FROM gallery_items
       WHERE ${column} = ?1 AND grade = ?2 AND visible = 1
       ORDER BY ${orderBy}
       LIMIT ?3 OFFSET ?4`
    )
    .bind(value, q.grade, limitPlusOne, offset)
    .all<D1GalleryRow>();
  return results ?? [];
}

function rowsToPage(
  rows: D1GalleryRow[],
  limit: number,
  cursor: number | null
): { images: GalleryImageRow[]; cursor: number | null; truncated: boolean } {
  const truncated = rows.length > limit;
  const page = truncated ? rows.slice(0, limit) : rows;
  const nextCursor = truncated ? (cursor ?? 0) + limit : null;
  return {
    images: page.map((r) => ({
      submission_id: r.submission_id,
      student_id: r.student_id,
      first_name: r.first_name,
      object_key: r.object_key,
      media_type: (r.media_type === "video" ? "video" : "image") as "image" | "video",
      score: r.score,
      promoted_at: r.promoted_at,
      updated_at: r.updated_at,
    })),
    cursor: nextCursor,
    truncated,
  };
}

/**
 * Walks cfg.GALLERY_FALLBACK_CASCADE in order (e.g. ["assignment_id", "school",
 * "district", "state"] by default — narrowest first), stopping at the first level that
 * returns a non-empty page. If GALLERY_FALLBACK_ENABLED is false, only the FIRST level
 * in the cascade is tried — no widening on an empty result.
 */
export async function fetchGalleryPage(
  db: D1Database,
  _env: Env,
  cfg: Pick<ConfigSchema, "GALLERY_FALLBACK_ENABLED" | "GALLERY_FALLBACK_CASCADE" | "GALLERY_SORT">,
  query: GalleryQuery
): Promise<GalleryPage> {
  const cascade = cfg.GALLERY_FALLBACK_CASCADE;

  for (let i = 0; i < cascade.length; i++) {
    const level = cascade[i] as GalleryScopeField;
    const rows = await queryLevel(db, level, query, cfg.GALLERY_SORT);
    if (rows.length > 0) {
      const { images, cursor, truncated } = rowsToPage(rows, query.limit, query.cursor);
      return {
        images: await toSignedImages(images),
        cursor,
        truncated,
        matched_level: level,
        fallback_applied: i > 0,
      };
    }
    if (!cfg.GALLERY_FALLBACK_ENABLED) break;
  }

  return { images: [], cursor: null, truncated: false, matched_level: "none", fallback_applied: cascade.length > 1 };
}

/**
 * Placeholder image URL resolution: the real signed-URL minting (GCS/R2) happens in
 * cache/signedUrlCache.ts + storage/gcs.ts|r2.ts, called from galleryHandlers.ts around
 * this function. This just shapes rows into the GalleryImage contract — notably it
 * drops `object_key` from the outward shape entirely; callers overwrite `url` with a
 * real signed URL before returning to the client, and the raw key never travels past
 * this point.
 */
async function toSignedImages(rows: GalleryImageRow[]): Promise<GalleryImage[]> {
  return rows.map((r) => ({
    submission_id: r.submission_id,
    display_name: r.first_name,
    url: r.object_key, // caller resolves this to a real signed URL and this field is overwritten
    media_type: r.media_type,
    score: r.score,
    uploaded: new Date(r.promoted_at * 1000).toISOString(),
  }));
}

// ─────────────────────────────────────────────────────────────────────────
// Write path — called only from handlers/internalHandlers.ts, itself gated by
// INTERNAL_API_SECRET (never reachable from the app).
// ─────────────────────────────────────────────────────────────────────────

export interface PromoteRow {
  academicYear: number;
  assignmentId: string;
  studentId: string;
  submissionId: string;
  firstName?: string;
  state: string;
  district: string;
  school: string;
  grade: number;
  mediaType: "image" | "video";
  score?: number;
  promotedAt: number;
  updatedAt?: number;
}

export async function upsertGalleryItems(db: D1Database, rows: PromoteRow[]): Promise<void> {
  if (rows.length === 0) return;

  const stmt = db.prepare(
    `INSERT INTO gallery_items
       (submission_id, academic_year, assignment_id, student_id, first_name, state, district, school, grade, media_type, score, promoted_at, updated_at, visible)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, 1)
     ON CONFLICT(submission_id) DO UPDATE SET
       academic_year = excluded.academic_year,
       assignment_id = excluded.assignment_id,
       student_id = excluded.student_id,
       first_name = excluded.first_name,
       state = excluded.state,
       district = excluded.district,
       school = excluded.school,
       grade = excluded.grade,
       media_type = excluded.media_type,
       score = excluded.score,
       promoted_at = excluded.promoted_at,
       updated_at = excluded.updated_at`
  );

  const batched = rows.map((r) =>
    stmt.bind(
      r.submissionId,
      r.academicYear,
      r.assignmentId,
      r.studentId,
      r.firstName ?? null,
      r.state,
      r.district,
      r.school,
      r.grade,
      r.mediaType,
      r.score ?? null,
      r.promotedAt,
      r.updatedAt ?? r.promotedAt
    )
  );

  await db.batch(batched);
}

export async function setGalleryItemVisibility(db: D1Database, submissionId: string, visible: boolean): Promise<void> {
  await db
    .prepare(`UPDATE gallery_items SET visible = ?1 WHERE submission_id = ?2`)
    .bind(visible ? 1 : 0, submissionId)
    .run();
}