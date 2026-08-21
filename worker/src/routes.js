import {
  validateAccessToken,
  validateResetToken,
  tokenNeedsRefresh,
  issueAccessToken,
  unauthorizedResponse,
} from './auth.js';

export const ROUTES = [
  {
    method: 'POST',
    path: '/auth/check-phone',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.check_phone',
    auth: false,
  },
  {
    method: 'POST',
    path: '/auth/login',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.login_with_password',
    auth: false,
  },
  {
    method: 'POST',
    path: '/auth/forgot-password/send-otp',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.forgot_password_send_otp',
    auth: false,
  },
  {
    method: 'POST',
    path: '/auth/forgot-password/verify-otp',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.forgot_password_verify_otp',
    auth: false,
  },
  {
    method: 'POST',
    path: '/auth/reset-password',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.reset_password',
    auth: 'reset',
  },

  {
    method: 'GET',
    path: '/profiles',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.get_profiles',
    auth: true,
  },
  {
    method: 'GET',
    path: '/profiles/search',
    target: 'tap_lms.tapapp.api.auth.tapapp_auth.search_profiles',
    auth: true,
  },
  {
    method: 'POST',
    path: '/profiles/select',
    target: 'tap_lms.tapapp.api.profile.profile.select_profile',
    auth: true,
  },
  {
    method: 'POST',
    path: '/profiles/avatar',
    target: 'tap_lms.tapapp.api.profile.profile.update_avatar',
    auth: true,
  },
  {
    method: 'POST',
    path: '/profiles/update',
    target: 'tap_lms.tapapp.api.profile.profile.update_profile',
    auth: true,
  },

  {
    method: 'GET',
    path: '/students/search',
    target: 'tap_lms.tapapp.api.profile.profile.search_student',
    auth: true,
  },
  {
    method: 'GET',
    path: '/students',
    target: 'tap_lms.tapapp.api.profile.profile.get_bulk_students',
    auth: true,
  },
  {
    method: 'POST',
    path: '/students/update',
    target: 'tap_lms.tapapp.api.profile.profile.update_student',
    auth: true,
  },
  {
    method: 'POST',
    path: '/students/bulk-update',
    target: 'tap_lms.tapapp.api.profile.profile.bulk_update_students',
    auth: true,
  },

  {
    method: 'GET',
    path: '/learner/state',
    target: 'tap_lms.tapapp.api.progress.learner.get_learner_state',
    auth: true,
  },
  {
    method: 'POST',
    path: '/learner/enroll',
    target: 'tap_lms.tapapp.api.progress.learner.enroll_course',
    auth: true,
  },
  {
    method: 'POST',
    path: '/learner/submit-progress',
    target: 'tap_lms.tapapp.api.progress.learner.submit_progress',
    auth: true,
  },

  {
    method: 'GET',
    path: '/achievements',
    target: 'tap_lms.tapapp.api.progress.achievements.get_learner_achievements',
    auth: true,
  },
  {
    method: 'POST',
    path: '/achievements/award',
    target: 'tap_lms.tapapp.api.progress.achievements.award_achievement',
    auth: true,
  },
  {
  method: 'POST',
  path: '/onboarding/complete',
  target: 'tap_lms.tapapp.api.profile.onboarding.complete_onboarding',
  auth: true,
  },
];

function matchRoute(method, pathname) {
  return ROUTES.find((r) => r.method === method && r.path === pathname) || null;
}

async function readBody(request) {
  const method = request.method;
  if (method === 'GET' || method === 'HEAD') return {};
  const contentType = request.headers.get('Content-Type') || '';
  if (!contentType.includes('application/json')) return {};
  const raw = await request.text();
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function queryParams(url) {
  const params = {};
  for (const [key, value] of url.searchParams.entries()) {
    params[key] = value;
  }
  return params;
}

function extractAppToken(request) {
  for (const header of ['X-Flutter-Authorization', 'Authorization']) {
    const value = request.headers.get(header);
    if (value && value.startsWith('Bearer ')) {
      return value;
    }
  }
  return null;
}

function buildBackendUrl(env, route, method, params) {
  const base = `${env.FRAPPE_BASE_URL}/api/method/${route.target}`;
  if (method !== 'GET') return base;
  const qs = new URLSearchParams();
  for (const key of Object.keys(params)) {
    if (params[key] === undefined || params[key] === null) continue;
    qs.set(key, String(params[key]));
  }
  const suffix = qs.toString();
  return suffix ? `${base}?${suffix}` : base;
}

async function callBackend(url, method, appToken, jsonBody) {
  const headers = new Headers();
  headers.set('Accept', 'application/json');
  if (appToken) {
    headers.set('X-Flutter-Authorization', appToken);
  }

  const init = { method: method === 'GET' ? 'GET' : 'POST', headers };

  if (method !== 'GET') {
    const bodyText = JSON.stringify(jsonBody ?? {});
    headers.set('Content-Type', 'application/json');
    headers.set('Content-Length', String(new TextEncoder().encode(bodyText).length));
    init.body = bodyText;
  }

  return fetch(url, init);
}

export async function routeRequest(request, env) {
  const url = new URL(request.url);
  const route = matchRoute(request.method, url.pathname);

  if (!route) {
    return new Response(JSON.stringify({ success: false, error: 'not_found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const body = await readBody(request);
  const params = { ...queryParams(url), ...body };

  let refreshedToken = null;
  const appToken = extractAppToken(request);

  if (route.auth === true) {
    const authResult = await validateAccessToken(request, env, params.phone);
    if (!authResult.valid) {
      return unauthorizedResponse(authResult.error);
    }
    if (tokenNeedsRefresh(authResult.payload)) {
      refreshedToken = await issueAccessToken(authResult.payload.phone, env);
    }
    params.phone = authResult.payload.phone;
  } else if (route.auth === 'reset') {
    const authResult = await validateResetToken(request, env, params.phone);
    if (!authResult.valid) {
      return unauthorizedResponse(authResult.error);
    }
    params.phone = authResult.payload.phone;
  }

  const method = request.method === 'GET' ? 'GET' : 'POST';
  const backendUrl = buildBackendUrl(env, route, method, params);
  const forwardToken = route.auth ? appToken : null;

  let backendResponse;
  try {
    backendResponse = await callBackend(backendUrl, method, forwardToken, params);
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: 'backend_unreachable', detail: err.message }),
      { status: 502, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const responseText = await backendResponse.text();
  let parsed;
  try {
    parsed = JSON.parse(responseText);
  } catch {
    parsed = null;
  }

  const unwrapped =
    parsed && Object.prototype.hasOwnProperty.call(parsed, 'message') ? parsed.message : parsed;
  const finalBody =
    unwrapped && typeof unwrapped === 'object'
      ? unwrapped
      : { success: backendResponse.ok, raw: responseText };

  if (refreshedToken) {
    finalBody.token = refreshedToken;
  }

  return new Response(JSON.stringify(finalBody), {
    status: backendResponse.status,
    headers: { 'Content-Type': 'application/json' },
  });
}
