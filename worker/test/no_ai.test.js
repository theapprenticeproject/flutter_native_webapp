import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import worker from '../src/worker.js';

// C1 (M0): the prototype AI (Groq) code is gone. The AI review in the Worker is
// not carried forward. These routes must not exist, and no AI code or setting
// may come back by accident.

const AI_ROUTES = ['/tapbuddy/chat', '/submission-review/review'];
const AI_WORDS = /groq|tapbuddy|submission[-_]review/i;

for (const path of AI_ROUTES) {
  test(`POST ${path} is not a route any more`, async () => {
    const request = new Request(`https://worker.test${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{}',
    });
    const response = await worker.fetch(request, {}, {});
    assert.equal(response.status, 404);
    assert.equal((await response.json()).error, 'not_found');
  });
}

test('no AI file, code or setting is left in the Worker', () => {
  const srcDir = new URL('../src/', import.meta.url);
  const files = readdirSync(srcDir);
  const texts = files.map((f) => [`src/${f}`, readFileSync(new URL(f, srcDir), 'utf8')]);
  texts.push(['wrangler.toml', readFileSync(new URL('../wrangler.toml', import.meta.url), 'utf8')]);

  for (const file of files) {
    assert.doesNotMatch(file, AI_WORDS, `src/${file} should not exist`);
  }
  for (const [name, text] of texts) {
    assert.doesNotMatch(text, AI_WORDS, `${name} still mentions the AI code`);
  }
});
