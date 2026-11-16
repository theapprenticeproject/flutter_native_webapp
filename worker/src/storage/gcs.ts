/**
 * storage/gcs.ts — Worker signs every GCS URL it hands out, holding GCS credentials
 * directly (Contract §1.1). A submission's media stays on GCS at grading time; R2
 * promotion happens later as a separate background job outside this request path
 * (§0, §7.4) — nothing here ever deletes from GCS.
 */

import type { ConfigSchema } from "../config/defaults";
import type { SubmissionType } from "./keys";
import { CONTENT_TYPE_FOR } from "./keys";
import { getGoogleAccessTokenCached, importRsaPrivateKey, parseServiceAccountJson, type ServiceAccount } from "./gcsAuth";

const HOST = "storage.googleapis.com";

function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function sha256Hex(data: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(data));
  return toHex(digest);
}
function dateStamp(d: Date): string {
  return d.toISOString().slice(0, 10).replace(/-/g, "");
}
function amzDate(d: Date): string {
  return d.toISOString().replace(/[:-]|\.\d{3}/g, "");
}

function buildLowercaseHeaderMap(input: Record<string, string>): Map<string, string> {
  const out = new Map<string, string>();
  for (const [k, v] of Object.entries(input)) {
    const lower = k.toLowerCase();
    if (out.has(lower)) throw new Error(`duplicate header (case-insensitive) in GCS V4 signing: "${lower}"`);
    out.set(lower, v);
  }
  return out;
}

interface V4SignParams {
  sa: ServiceAccount;
  bucket: string;
  objectKey: string;
  method: "PUT" | "GET" | "HEAD";
  expiresInSeconds: number;
  extraHeaders?: Record<string, string>;
}

async function signV4Url(params: V4SignParams): Promise<string> {
  const now = new Date();
  const dstamp = dateStamp(now);
  const amz = amzDate(now);
  const credentialScope = `${dstamp}/auto/storage/goog4_request`;
  const credential = `${params.sa.client_email}/${credentialScope}`;

  const headerMap = buildLowercaseHeaderMap({ host: HOST, ...(params.extraHeaders ?? {}) });
  const signedHeaderNames = [...headerMap.keys()].sort();
  const signedHeaders = signedHeaderNames.join(";");
  const canonicalHeaders = signedHeaderNames.map((h) => `${h}:${(headerMap.get(h) as string).trim()}\n`).join("");

  const query: Record<string, string> = {
    "X-Goog-Algorithm": "GOOG4-RSA-SHA256",
    "X-Goog-Credential": credential,
    "X-Goog-Date": amz,
    "X-Goog-Expires": String(params.expiresInSeconds),
    "X-Goog-SignedHeaders": signedHeaders,
  };
  const canonicalQuery = Object.keys(query)
    .sort()
    .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(query[k] as string)}`)
    .join("&");

  const canonicalUri = `/${params.bucket}/${params.objectKey.split("/").map(encodeURIComponent).join("/")}`;
  const canonicalRequest = [params.method, canonicalUri, canonicalQuery, canonicalHeaders, signedHeaders, "UNSIGNED-PAYLOAD"].join(
    "\n"
  );
  const hashedCanonicalRequest = await sha256Hex(canonicalRequest);
  const stringToSign = ["GOOG4-RSA-SHA256", amz, credentialScope, hashedCanonicalRequest].join("\n");

  const key = await importRsaPrivateKey(params.sa.private_key);
  const sigBuf = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(stringToSign));
  const signatureHex = toHex(sigBuf);

  return `https://${HOST}${canonicalUri}?${canonicalQuery}&X-Goog-Signature=${signatureHex}`;
}

export interface SignedUploadResult {
  uploadUrl: string;
  contentType: string;
  maxSizeBytes: number;
  expiresIn: number;
  uploadHeaders: Record<string, string>;
}

export async function gcsSignUpload(
  env: { GCS_SERVICE_ACCOUNT_JSON: string; GCS_AUTHENTICATED_BUCKET: string },
  objectKey: string,
  submissionType: SubmissionType,
  cfg: Pick<ConfigSchema, "UPLOAD_MAX_BYTES_IMAGE" | "UPLOAD_MAX_BYTES_VIDEO" | "UPLOAD_URL_EXPIRY_SECONDS">
): Promise<SignedUploadResult> {
  const sa = parseServiceAccountJson(env.GCS_SERVICE_ACCOUNT_JSON);
  const contentType = CONTENT_TYPE_FOR[submissionType];
  const maxSizeBytes = submissionType === "image" ? cfg.UPLOAD_MAX_BYTES_IMAGE : cfg.UPLOAD_MAX_BYTES_VIDEO;

  const uploadHeaders: Record<string, string> = {
    "content-type": contentType,
    "x-goog-content-length-range": `1,${maxSizeBytes}`,
  };

  const uploadUrl = await signV4Url({
    sa,
    bucket: env.GCS_AUTHENTICATED_BUCKET,
    objectKey,
    method: "PUT",
    expiresInSeconds: cfg.UPLOAD_URL_EXPIRY_SECONDS,
    extraHeaders: uploadHeaders,
  });

  return { uploadUrl, contentType, maxSizeBytes, expiresIn: cfg.UPLOAD_URL_EXPIRY_SECONDS, uploadHeaders };
}

/** view_url/audio_url are signed fresh on every call, per Contract §7.2. */
export async function gcsSignRead(
  env: { GCS_SERVICE_ACCOUNT_JSON: string; GCS_AUTHENTICATED_BUCKET: string },
  objectKey: string,
  expiresInSeconds: number
): Promise<string> {
  const sa = parseServiceAccountJson(env.GCS_SERVICE_ACCOUNT_JSON);
  return signV4Url({ sa, bucket: env.GCS_AUTHENTICATED_BUCKET, objectKey, method: "GET", expiresInSeconds });
}

export interface UploadConfirmation {
  exists: boolean;
  sizeBytes: number | null;
  contentType: string | null;
  generation: string | null;
  md5Hash: string | null;
}

/** submit_artwork confirms the object exists, then checks size, then content type — strictly in that order (§7.2). */
export async function confirmUploaded(
  env: { GCS_SERVICE_ACCOUNT_JSON: string; GCS_AUTHENTICATED_BUCKET: string },
  objectKey: string
): Promise<UploadConfirmation> {
  const sa = parseServiceAccountJson(env.GCS_SERVICE_ACCOUNT_JSON);
  const token = await getGoogleAccessTokenCached(sa, "https://www.googleapis.com/auth/devstorage.read_only");

  const url = `https://storage.googleapis.com/storage/v1/b/${encodeURIComponent(
    env.GCS_AUTHENTICATED_BUCKET
  )}/o/${encodeURIComponent(objectKey)}`;

  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (res.status === 404) {
    return { exists: false, sizeBytes: null, contentType: null, generation: null, md5Hash: null };
  }
  if (!res.ok) throw new Error(`GCS metadata lookup failed: ${res.status}`);

  const meta = (await res.json()) as { size?: string; contentType?: string; generation?: string; md5Hash?: string };
  return {
    exists: true,
    sizeBytes: meta.size ? Number(meta.size) : null,
    contentType: meta.contentType ?? null,
    generation: meta.generation ?? null,
    md5Hash: meta.md5Hash ?? null,
  };
}

export function publicHttpsUrl(bucket: string, objectKey: string): string {
  return `https://storage.googleapis.com/${bucket}/${objectKey.split("/").map(encodeURIComponent).join("/")}`;
}