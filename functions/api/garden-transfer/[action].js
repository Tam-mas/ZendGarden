const OLD = 'https://zend.tammas.com';
const HOME = 'https://zend.garden';
const TTL_MS = 15 * 60 * 1000;
const MAX_BODY = 8 * 1024 * 1024;
const TOKEN = /^[A-Za-z0-9_-]{43}$/;
const PRIVATE_HEADERS = {
  'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff', 'Vary': 'Origin',
};
function response(body, status, origin) {
  return Response.json(body, { status, headers: { ...PRIVATE_HEADERS,
    ...(origin ? { 'Access-Control-Allow-Origin': origin } : {}) } });
}
async function boundedJSON(request) {
  if (!request.headers.get('Content-Type')?.startsWith('application/json')) throw new Error('format');
  const reader = request.body?.getReader();
  if (!reader) throw new Error('format');
  const parts = []; let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > MAX_BODY) { await reader.cancel(); throw new Error('size'); }
    parts.push(value);
  }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const part of parts) { bytes.set(part, offset); offset += part.length; }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}
async function storageKey(token) {
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
  return 'moves/' + Array.from(new Uint8Array(hash), n => n.toString(16).padStart(2, '0')).join('');
}
function randomToken() {
  return btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(32))))
    .replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

export async function onRequest({ request, env, params }) {
  const origin = request.headers.get('Origin');
  const allowed = [OLD, HOME].includes(origin);
  const action = params.action;
  if (request.method === 'OPTIONS') {
    if (!allowed) return response({ error: 'origin' }, 403);
    return new Response(null, { status: 204, headers: { ...PRIVATE_HEADERS,
      'Access-Control-Allow-Origin': origin, 'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type', 'Access-Control-Max-Age': '600' } });
  }
  if (action === 'status' && request.method === 'GET') {
    return response({ enabled: env.ZEND_MIGRATION_ENABLED === 'true' && !!env.GARDEN_TRANSFERS }, 200, allowed ? origin : null);
  }
  if (!allowed || (action === 'create' ? origin !== OLD : origin !== HOME)) return response({ error: 'origin' }, 403);
  if (request.method !== 'POST') return response({ error: 'method' }, 405, origin);
  if (!['create', 'read', 'ack'].includes(action)) return response({ error: 'route' }, 404, origin);
  if (env.ZEND_MIGRATION_ENABLED !== 'true' || !env.GARDEN_TRANSFERS) return response({ error: 'paused' }, 503, origin);
  let body;
  try { body = await boundedJSON(request); }
  catch (error) { return response({ error: 'invalid-copy' }, error.message === 'size' ? 413 : 400, origin); }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return response({ error: 'invalid-copy' }, 400, origin);
  try {
    if (action === 'create') {
      if (typeof body.iv !== 'string' || !/^[A-Za-z0-9_-]{16}$/.test(body.iv)
        || typeof body.ciphertext !== 'string' || body.ciphertext.length < 24
        || body.ciphertext.length > MAX_BODY - 1024 || !/^[A-Za-z0-9_-]+$/.test(body.ciphertext)) {
        return response({ error: 'invalid-copy' }, 400, origin);
      }
      const token = randomToken();
      const expires = Date.now() + TTL_MS;
      // Store only encrypted bytes. The decryption key never reaches this service.
      await env.GARDEN_TRANSFERS.put(await storageKey(token), JSON.stringify({ iv: body.iv, ciphertext: body.ciphertext, expires }),
        { httpMetadata: { contentType: 'application/json' } });
      return response({ token, expires }, 201, origin);
    }
    if (!TOKEN.test(body.token)) return response({ error: 'invalid-link' }, 400, origin);
    const key = await storageKey(body.token);
    if (action === 'ack') {
      await env.GARDEN_TRANSFERS.delete(key);
      return response({ acknowledged: true }, 200, origin);
    }
    const object = await env.GARDEN_TRANSFERS.get(key);
    if (!object) return response({ error: 'expired' }, 404, origin);
    const copy = await object.json();
    if (Date.now() >= copy.expires) {
      await env.GARDEN_TRANSFERS.delete(key);
      return response({ error: 'expired' }, 410, origin);
    }
    // Reading does not consume the link; a tab closure or failed write can retry.
    return response({ iv: copy.iv, ciphertext: copy.ciphertext }, 200, origin);
  } catch {
    // Do not log bodies, tokens, keys, save contents, or storage exceptions.
    return response({ error: 'unavailable' }, 503, origin);
  }
}
