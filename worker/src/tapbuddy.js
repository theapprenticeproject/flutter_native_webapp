import { validateAccessToken, unauthorizedResponse } from './auth.js';
import { callGroq } from './groq.js';

const SYSTEM_PROMPT = `You are Tapbuddy, a friendly and encouraging learning companion for school students using the Tap LMS app.
Keep answers short, simple, precise, and supportive, ideally 2-4 sentences. Use plain language suited to grades 1-12.
Always reply in the student's preferred language when one is given. Guide the student toward the answer rather than just giving it outright when it looks like homework.
Never discuss topics unrelated to learning, studies, or the app. If asked something inappropriate or off-topic, gently redirect back to learning.`;

const MAX_HISTORY_MESSAGES = 12;
const MAX_MESSAGE_CHARS = 2000;
const TAPBUDDY_MODEL = 'llama-3.1-8b-instant';

function sanitizeHistory(history) {
  if (!Array.isArray(history)) return [];
  return history
    .slice(-MAX_HISTORY_MESSAGES)
    .filter((m) => m && typeof m.role === 'string' && typeof m.content === 'string')
    .map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: String(m.content).slice(0, MAX_MESSAGE_CHARS),
    }));
}

function contextLinesFromLearnerContext(context) {
  if (!context || typeof context !== 'object') return [];

  const lines = [];
  const {
    course_name: courseName,
    unit_name: unitName,
    unit_description: unitDescription,
    xp,
    streak,
    has_reached_weekly_cap: hasReachedWeeklyCap,
    has_active_class_session: hasActiveClassSession,
  } = context;

  if (courseName) lines.push(`The student is enrolled in: ${courseName}.`);

  if (hasActiveClassSession && unitName) {
    lines.push(`They are currently in a class session working on the unit "${unitName}".`);
    if (unitDescription) lines.push(`This unit is about: ${unitDescription}.`);
  } else {
    lines.push('They are not currently inside an active class session.');
  }

  if (typeof xp === 'number') lines.push(`They currently have ${xp} XP.`);
  if (typeof streak === 'number') lines.push(`Their current streak is ${streak} day(s).`);
  if (hasReachedWeeklyCap) {
    lines.push(
      'They have already reached their weekly activity limit, so no new units are available right now.'
    );
  }

  return lines;
}

export async function handleTapbuddyChat(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const phone = body.phone;
  const message = body.message;
  const learnerId = body.learner_id;
  const history = sanitizeHistory(body.history);
  const grade = body.grade;
  const language = body.language;
  const context = body.context;

  const authResult = await validateAccessToken(request, env, phone);
  if (!authResult.valid) {
    return unauthorizedResponse(authResult.error);
  }

  if (!message || typeof message !== 'string') {
    return new Response(JSON.stringify({ success: false, error: 'message_is_required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const contextLines = [];
  if (grade) contextLines.push(`Student grade: ${grade}.`);
  if (language) contextLines.push(`Reply only in this language: ${language}.`);
  contextLines.push(...contextLinesFromLearnerContext(context));

  const systemContent = contextLines.length
    ? `${SYSTEM_PROMPT}\n${contextLines.join(' ')}`
    : SYSTEM_PROMPT;

  const messages = [
    { role: 'system', content: systemContent },
    ...history,
    { role: 'user', content: message.slice(0, MAX_MESSAGE_CHARS) },
  ];

  try {
    const result = await callGroq(env, {
      model: TAPBUDDY_MODEL,
      messages,
      temperature: 0.6,
      maxTokens: 500,
    });

    return new Response(
      JSON.stringify({
        success: true,
        learner_id: learnerId || null,
        reply: result.content,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: 'tapbuddy_failed', detail: err.message }),
      { status: 502, headers: { 'Content-Type': 'application/json' } }
    );
  }
}