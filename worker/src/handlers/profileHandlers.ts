import { requireStudentToken } from "../auth/middleware";
import { fetchFrappe } from "../frappe/client";
import { FRAPPE_METHODS } from "../frappe/mapRequest";
import type { Env } from "../env";
import { ok } from "../util/errors";
import { enforceRateLimit } from "../util/rateLimit";
import { collectTelemetry } from "../telemetry/collector";

interface GetProfileBody {
  _t?: unknown;
}

interface ProfileResult {
  student_id: string;
  name1: string;
  gender: string;
  language: string;
  grade: string;
  course_id: string;
  state_id: string;
  district_id: string;
  school_id: string;
  state_name: string;
  district_name: string;
  school_name: string;
}

async function getProfile(
  req: Request,
  env: Env,
  _ctx: ExecutionContext,
  setStudentId: (sid: string) => void
): Promise<Response> {
  const { studentId } = await requireStudentToken(req, env);
  setStudentId(studentId);
  await enforceRateLimit(env, studentId, "read");

  const body = (await req.json().catch(() => ({}))) as GetProfileBody;

  const profile = await fetchFrappe<ProfileResult>(env, FRAPPE_METHODS.getProfile, { student_id: studentId });

  void collectTelemetry(env, studentId, body._t).catch(() => {});

  return ok({ ...profile });
}

export const profileHandlers = { getProfile };