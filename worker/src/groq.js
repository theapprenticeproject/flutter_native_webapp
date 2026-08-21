const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_TRANSCRIPTION_URL = 'https://api.groq.com/openai/v1/audio/transcriptions';

function buildGroqError(resp, parsed, text, fallback) {
  const apiMessage = parsed?.error?.message || text || fallback;
  const err = new Error(`${fallback}_${resp.status}: ${apiMessage}`);
  err.status = resp.status;
  err.groqError = parsed?.error || null;
  return err;
}

export async function callGroq(
  env,
  { model, messages, temperature, maxTokens, responseFormat, reasoningEffort }
) {
  if (!env.GROQ_API_KEY) {
    const err = new Error('groq_api_key_not_configured');
    err.status = 500;
    throw err;
  }

  const body = {
    model: model || env.GROQ_MODEL || 'llama-3.3-70b-versatile',
    messages,
    temperature: temperature ?? 0.5,
    max_tokens: maxTokens ?? 800,
  };
  if (responseFormat) {
    body.response_format = responseFormat;
  }
  if (reasoningEffort) {
    body.reasoning_effort = reasoningEffort;
  }

  const resp = await fetch(GROQ_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  const text = await resp.text();
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = null;
  }

  if (!resp.ok) {
    throw buildGroqError(resp, parsed, text, 'groq_request_failed');
  }

  const choice = parsed?.choices?.[0];
  const content = choice?.message?.content ?? '';
  return { content, raw: parsed };
}

export async function callGroqVision(
  env,
  { model, messages, temperature, maxTokens, responseFormat, reasoningEffort }
) {
  if (!env.GROQ_API_KEY) {
    const err = new Error('groq_api_key_not_configured');
    err.status = 500;
    throw err;
  }

  const body = {
    model: model || 'llama-4-scout-17b-16e-instruct',
    messages,
    temperature: temperature ?? 0.5,
    max_tokens: maxTokens ?? 800,
  };
  if (responseFormat) {
    body.response_format = responseFormat;
  }
  if (reasoningEffort) {
    body.reasoning_effort = reasoningEffort;
  }

  const resp = await fetch(GROQ_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  const text = await resp.text();
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = null;
  }

  if (!resp.ok) {
    throw buildGroqError(resp, parsed, text, 'groq_vision_request_failed');
  }

  const choice = parsed?.choices?.[0];
  const content = choice?.message?.content ?? '';
  return { content, raw: parsed };
}

export async function callGroqAudioTranscription(env, { audioUrl, language }) {
  if (!env.GROQ_API_KEY) {
    const err = new Error('groq_api_key_not_configured');
    err.status = 500;
    throw err;
  }

  const audioResp = await fetch(audioUrl);
  if (!audioResp.ok) {
    const err = new Error(`audio_fetch_failed_${audioResp.status}`);
    err.status = audioResp.status;
    throw err;
  }
  const audioBlob = await audioResp.blob();

  const formData = new FormData();
  formData.append('file', audioBlob, 'submission_audio');
  formData.append('model', 'whisper-large-v3');
  formData.append('response_format', 'json');
  if (language) {
    formData.append('language', language);
  }

  const resp = await fetch(GROQ_TRANSCRIPTION_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
    },
    body: formData,
  });

  const text = await resp.text();
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = null;
  }

  if (!resp.ok) {
    throw buildGroqError(resp, parsed, text, 'groq_audio_request_failed');
  }

  return { text: parsed?.text ?? '', raw: parsed };
}