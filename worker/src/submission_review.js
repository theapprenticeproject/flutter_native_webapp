import { validateAccessToken, unauthorizedResponse } from './auth.js';
import { callGroq, callGroqVision, callGroqAudioTranscription } from './groq.js';

const SYSTEM_PROMPT = `You are an assessment assistant for a school learning app reviewing a student's submitted answer.
Evaluate the submission against the given question and expected answer criteria.
Respond ONLY with a JSON object with this exact shape and no extra text:
{"score": number between 0 and 100, "verdict": "pass" or "review" or "fail", "feedback": short encouraging feedback string, "sms_text": very short friendly message under 200 characters either appreciating the student or gently pointing to one improvement, "strengths": array of short strings, "improvements": array of short strings}`;

const STRICT_RETRY_SUFFIX = `
Your previous response was cut off before finishing valid JSON. Respond again with ONLY a single complete, valid JSON object matching the shape above. Do not think out loud or explain your reasoning first. Keep "feedback" under 2 sentences, "sms_text" under 200 characters, and each item in "strengths" and "improvements" to a few words, so the full object fits well within the token limit. Do not include any text before or after the JSON.`;

const MAX_TEXT_CHARS = 4000;
const VISION_MODEL = 'qwen/qwen3.6-27b';
const REASONING_EFFORT = 'none';
const DEFAULT_MAX_TOKENS = 900;
const RETRY_MAX_TOKENS = 1400;

function buildUserLines(question, expectedAnswer, rubric) {
  const lines = [];
  if (question) lines.push(`Question: ${String(question).slice(0, MAX_TEXT_CHARS)}`);
  if (expectedAnswer)
    lines.push(`Expected answer criteria: ${String(expectedAnswer).slice(0, MAX_TEXT_CHARS)}`);
  if (rubric) lines.push(`Rubric: ${String(rubric).slice(0, MAX_TEXT_CHARS)}`);
  return lines;
}

function isJsonValidationError(err) {
  if (!err) return false;
  if (err.groqError && err.groqError.code === 'json_validate_failed') return true;
  if (typeof err.message === 'string' && err.message.includes('json_validate_failed')) return true;
  const failedGeneration = err.groqError && err.groqError.failed_generation;
  return typeof failedGeneration === 'string' && failedGeneration.includes('max completion tokens');
}

function parseReview(rawContent) {
  return JSON.parse(rawContent);
}

function formatReviewResponse(learnerId, review) {
  return {
    success: true,
    learner_id: learnerId || null,
    review: {
      score: review.score ?? null,
      verdict: review.verdict ?? null,
      feedback: review.feedback ?? '',
      sms_text: review.sms_text ?? '',
      strengths: Array.isArray(review.strengths) ? review.strengths : [],
      improvements: Array.isArray(review.improvements) ? review.improvements : [],
    },
  };
}

async function callWithJsonRetry(callFn, baseMessages) {
  try {
    return await callFn(baseMessages, DEFAULT_MAX_TOKENS);
  } catch (err) {
    if (!isJsonValidationError(err)) throw err;
    const retryMessages = [...baseMessages];
    retryMessages[0] = {
      ...retryMessages[0],
      content: retryMessages[0].content + STRICT_RETRY_SUFFIX,
    };
    return callFn(retryMessages, RETRY_MAX_TOKENS);
  }
}

async function reviewTextSubmission(env, question, expectedAnswer, rubric, submissionText) {
  const lines = buildUserLines(question, expectedAnswer, rubric);
  lines.push(`Student submission: ${submissionText.slice(0, MAX_TEXT_CHARS)}`);

  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: lines.join('\n') },
  ];

  return callWithJsonRetry(
    (msgs, maxTokens) =>
      callGroq(env, {
        model: env.GROQ_MODEL,
        messages: msgs,
        temperature: 0.2,
        maxTokens,
        responseFormat: { type: 'json_object' },
        reasoningEffort: REASONING_EFFORT,
      }),
    messages
  );
}

async function reviewImageSubmission(
  env,
  question,
  expectedAnswer,
  rubric,
  imageUrl,
  submissionText
) {
  const lines = buildUserLines(question, expectedAnswer, rubric);
  lines.push('The student submitted the attached image as their answer.');
  if (submissionText)
    lines.push(`Additional student notes: ${submissionText.slice(0, MAX_TEXT_CHARS)}`);

  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    {
      role: 'user',
      content: [
        { type: 'text', text: lines.join('\n') },
        { type: 'image_url', image_url: { url: imageUrl } },
      ],
    },
  ];

  return callWithJsonRetry(
    (msgs, maxTokens) =>
      callGroqVision(env, {
        model: VISION_MODEL,
        messages: msgs,
        temperature: 0.2,
        maxTokens,
        responseFormat: { type: 'json_object' },
        reasoningEffort: REASONING_EFFORT,
      }),
    messages
  );
}

async function reviewAudioSubmission(env, question, expectedAnswer, rubric, audioUrl) {
  const transcript = await callGroqAudioTranscription(env, { audioUrl });
  const lines = buildUserLines(question, expectedAnswer, rubric);
  lines.push(
    `Student submission (transcribed from audio): ${transcript.text.slice(0, MAX_TEXT_CHARS)}`
  );

  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: lines.join('\n') },
  ];

  const result = await callWithJsonRetry(
    (msgs, maxTokens) =>
      callGroq(env, {
        model: env.GROQ_MODEL,
        messages: msgs,
        temperature: 0.2,
        maxTokens,
        responseFormat: { type: 'json_object' },
        reasoningEffort: REASONING_EFFORT,
      }),
    messages
  );

  return { ...result, transcript: transcript.text };
}

export async function handleSubmissionReview(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const phone = body.phone;
  const learnerId = body.learner_id;
  const question = body.question;
  const expectedAnswer = body.expected_answer;
  const rubric = body.rubric;
  const submissionType = body.submission_type || 'text';
  const submissionText = body.submission_text;
  const imageUrl = body.image_url;
  const audioUrl = body.audio_url;

  const authResult = await validateAccessToken(request, env, phone);
  if (!authResult.valid) {
    return unauthorizedResponse(authResult.error);
  }

  if (submissionType === 'text' && (!submissionText || typeof submissionText !== 'string')) {
    return new Response(JSON.stringify({ success: false, error: 'submission_text_is_required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (submissionType === 'image' && (!imageUrl || typeof imageUrl !== 'string')) {
    return new Response(JSON.stringify({ success: false, error: 'image_url_is_required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (
    submissionType === 'image' &&
    imageUrl &&
    !imageUrl.startsWith('http://') &&
    !imageUrl.startsWith('https://') &&
    !imageUrl.startsWith('data:image/')
  ) {
    return new Response(
      JSON.stringify({ success: false, error: 'image_url_must_be_http_or_data_uri' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  if (submissionType === 'audio' && (!audioUrl || typeof audioUrl !== 'string')) {
    return new Response(JSON.stringify({ success: false, error: 'audio_url_is_required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (!['text', 'image', 'audio'].includes(submissionType)) {
    return new Response(JSON.stringify({ success: false, error: 'invalid_submission_type' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    let result;
    if (submissionType === 'text') {
      result = await reviewTextSubmission(env, question, expectedAnswer, rubric, submissionText);
    } else if (submissionType === 'image') {
      result = await reviewImageSubmission(
        env,
        question,
        expectedAnswer,
        rubric,
        imageUrl,
        submissionText
      );
    } else {
      result = await reviewAudioSubmission(env, question, expectedAnswer, rubric, audioUrl);
    }

    let review;
    try {
      review = parseReview(result.content);
    } catch {
      return new Response(
        JSON.stringify({ success: false, error: 'invalid_model_response', raw: result.content }),
        { status: 502, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const responseBody = formatReviewResponse(learnerId, review);
    if (result.transcript) responseBody.transcript = result.transcript;

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    const status = err.status && err.status >= 400 && err.status < 600 ? err.status : 502;
    return new Response(
      JSON.stringify({
        success: false,
        error: 'submission_review_failed',
        detail: err.message,
        groq_error: err.groqError || null,
      }),
      { status, headers: { 'Content-Type': 'application/json' } }
    );
  }
}