// NOTE: no skipAssignment entry — "skip" no longer exists as a concept. Moving past an
// assignment without submitting is /submission/do_later, which is a pure server-side
// no-op and never calls Frappe (see handlers/laterHandlers.ts).
export const FRAPPE_METHODS = {
  redeemMagicLink: "tap_lms.tap_app.api.redeem_magic_link",
  selectProfile: "tap_lms.tap_app.api.select_profile",
  getProfile: "tap_lms.tap_app.api.get_profile",
  submitVideo: "tap_lms.tap_app.api.submit_video",
  submitQuiz: "tap_lms.tap_app.api.submit_quiz",
  progressSync: "tap_lms.tap_app.api.progress_sync",
  lastSubmission: "tap_lms.tap_app.api.last_submission",
  checkAttemptCap: "tap_lms.tap_app.api.check_attempt_cap",
  submitArtwork: "tap_lms.imgana.submission.submit_artwork",
  listSubmissions: "tap_lms.tap_app.api.list_submissions",
  getSubmission: "tap_lms.tap_app.api.get_submission",
  getProfileScope: "tap_lms.tap_app.api.get_profile_scope",
  enrollEvent: "tap_lms.tap_app.api.enroll_event",
  isEnrolled: "tap_lms.tap_app.api.is_enrolled",
} as const;