export const MAX_SECONDS = 90 * 86400;
export const HEADERS = {
  'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY',
  'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
};
export const reply = (body, status = 200) => Response.json(body, { status, headers: HEADERS });
export const sameOrigin = request => request.headers.get('Origin') === new URL(request.url).origin;
export const enabled = (request, env) => new URL(request.url).hostname === 'zend.garden'
  && env.ZEND_ANALYTICS_ENABLED === 'true' && env.GARDEN_STATS && env.SESSION_SECRET;

export async function boundedJSON(request) {
  if (request.headers.get('Content-Type')?.split(';')[0] !== 'application/json') throw new Error('format');
  const reader = request.body?.getReader();
  if (!reader) throw new Error('format');
  const chunks = []; let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > 2048) { await reader.cancel(); throw new Error('size'); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  const value = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('format');
  return value;
}
const encode = bytes => btoa(String.fromCharCode(...bytes)).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
const decode = text => Uint8Array.from(atob(text.replaceAll('-', '+').replaceAll('_', '/')), ch => ch.charCodeAt(0));
async function key(secret) {
  return crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']);
}
export async function signSession(session, secret) {
  const payload = encode(new TextEncoder().encode(JSON.stringify(session)));
  const signature = await crypto.subtle.sign('HMAC', await key(secret), new TextEncoder().encode(payload));
  return payload + '.' + encode(new Uint8Array(signature));
}
export async function verifySession(token, secret, now) {
  if (typeof token !== 'string' || token.length > 512 || !/^[\w-]+\.[\w-]+$/.test(token)) throw new Error('token');
  const [payload, signature] = token.split('.');
  if (!await crypto.subtle.verify('HMAC', await key(secret), decode(signature), new TextEncoder().encode(payload))) throw new Error('token');
  const session = JSON.parse(new TextDecoder().decode(decode(payload)));
  if (!Number.isInteger(session.started) || session.started > now + 60 || session.started < now - MAX_SECONDS) throw new Error('expired');
  return session;
}
export async function authorized(request, secret) {
  if (!secret || secret.length < 32) return false;
  const supplied = request.headers.get('Authorization') || '';
  const digest = text => crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  const [a, b] = await Promise.all([digest(supplied), digest('Bearer ' + secret)]);
  const x = new Uint8Array(a), y = new Uint8Array(b);
  let different = 0;
  for (let i = 0; i < x.length; i++) different |= x[i] ^ y[i];
  return different === 0;
}
export const PURGE_SQL = 'DELETE FROM sessions WHERE started < ?1';
export const UPDATE_SQL = `UPDATE sessions SET
  running = MAX(running, ?1), advancing = MAX(advancing, MIN(?2, ?1)),
  ended = CASE WHEN ?1 >= running THEN ?3 ELSE ended END,
  last_seen = MAX(last_seen, ?4)
  WHERE id = ?5 AND (?1 > running OR ?2 > advancing OR ?3 != ended)`;
