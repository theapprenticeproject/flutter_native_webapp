/**
 * storage/packTaps.ts — Contract §9.3.1: t is milliseconds since the visit's own
 * occurred_at (relative, not wall-clock), kept small on purpose. maxTaps caps packed
 * row size independently of the client-sent tap_count, which always carries the true
 * total even when only the first maxTaps entries got packed — tap_count can legitimately
 * exceed taps.length once it reaches here; that's expected.
 */

export interface RawTap {
  t: number;
  x: number;
  y: number;
}

const BYTES_PER_TAP = 6;

function clampU16(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.min(Math.max(Math.round(n), 0), 65535);
}

export function packTaps(taps: RawTap[], maxTaps = 200): Uint8Array {
  const capped = taps.slice(0, Math.max(0, maxTaps));
  const buf = new Uint8Array(capped.length * BYTES_PER_TAP);
  const view = new DataView(buf.buffer);

  capped.forEach((tap, i) => {
    const offset = i * BYTES_PER_TAP;
    view.setUint16(offset, clampU16(tap.x), false);
    view.setUint16(offset + 2, clampU16(tap.y), false);
    view.setUint16(offset + 4, clampU16(tap.t), false);
  });

  return buf;
}

export function packedTapsToBase64(packed: Uint8Array): string {
  let binary = "";
  for (const b of packed) binary += String.fromCharCode(b);
  return btoa(binary);
}

export function packTapsToBase64(taps: RawTap[], maxTaps = 200): string {
  return packedTapsToBase64(packTaps(taps, maxTaps));
}