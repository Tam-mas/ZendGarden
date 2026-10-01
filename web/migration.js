import { SOURCE_ORIGIN, HOME_ORIGIN, MAX_SAVE_BYTES, base64, unbase64, sha256, validateSave } from './save-format.js';
import { readOriginal, readCurrent, pendingCopy, completedMove, stageCopy,
  acceptCopy, refreshPending, withGardenLock, holdGardenSession } from './migration-storage.js';

const API = `${HOME_ORIGIN}/api/garden-transfer`;
const TOKEN = /^[A-Za-z0-9_-]{43}$/;

export async function requestTransfer(action, body) {
  const response = await fetch(`${API}/${action}`, {
    method: 'POST', mode: 'cors', credentials: 'omit', cache: 'no-store',
    headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw new Error(response.status === 404 || response.status === 410
    ? 'This moving link has rested a little too long. Please visit the old address to try again.'
    : 'The move could not finish just now. Your original garden is still safe at the old address.');
  return response.json();
}

export async function sealCopy(bytes) {
  validateSave(bytes);
  const secret = crypto.getRandomValues(new Uint8Array(32));
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await crypto.subtle.importKey('raw', secret, 'AES-GCM', false, ['encrypt']);
  const envelope = new TextEncoder().encode(JSON.stringify({ source: SOURCE_ORIGIN,
    save: base64(bytes), sha256: await sha256(bytes) }));
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, envelope));
  return { secret: base64(secret), body: { iv: base64(iv), ciphertext: base64(ciphertext) } };
}

export async function unsealCopy(body, secret) {
  if (!body || typeof body.iv !== 'string' || typeof body.ciphertext !== 'string') throw new Error('The garden copy arrived incomplete. Please try the move again.');
  const rawKey = unbase64(secret);
  const iv = unbase64(body.iv);
  if (rawKey.length !== 32 || iv.length !== 12 || body.ciphertext.length > MAX_SAVE_BYTES * 2) throw new Error('This moving link is incomplete.');
  const key = await crypto.subtle.importKey('raw', rawKey, 'AES-GCM', false, ['decrypt']);
  let envelope;
  try {
    const decoded = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, unbase64(body.ciphertext));
    envelope = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(decoded));
  } catch { throw new Error('We could not check this garden copy. Your original has not been changed.'); }
  const bytes = unbase64(envelope.save);
  if (envelope.source !== SOURCE_ORIGIN || await sha256(bytes) !== envelope.sha256) throw new Error('The garden copy did not pass its checks.');
  validateSave(bytes);
  return bytes;
}

function card(title, message) {
  let overlay = document.getElementById('migration');
  if (!overlay) {
    overlay = document.createElement('section');
    overlay.id = 'migration';
    document.body.append(overlay);
  }
  overlay.replaceChildren();
  overlay.setAttribute('aria-labelledby', 'move-title');
  const panel = document.createElement('div');
  panel.className = 'migration-card';
  const sprig = document.createElement('p');
  sprig.className = 'move-sprig'; sprig.textContent = '❧'; sprig.setAttribute('aria-hidden', 'true');
  const heading = document.createElement('h1');
  heading.id = 'move-title'; heading.textContent = title;
  const text = document.createElement('p');
  text.className = 'move-message'; text.textContent = message;
  const status = document.createElement('p');
  status.id = 'move-status'; status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite');
  const actions = document.createElement('div'); actions.className = 'move-actions';
  panel.append(sprig, heading, text, status, actions); overlay.append(panel);
  return { overlay, status, actions };
}
function button(ui, label, action, secondary = false) {
  const item = document.createElement('button');
  item.type = 'button'; item.textContent = label;
  if (secondary) item.className = 'move-secondary';
  item.addEventListener('click', action); ui.actions.append(item);
  return item;
}
function link(ui, label, url) {
  const item = document.createElement('a'); item.textContent = label; item.href = url;
  ui.actions.append(item); return item;
}
function download(ui, bytes, label, filename) {
  button(ui, label, () => {
    const url = URL.createObjectURL(new Blob([bytes], { type: 'application/json' }));
    const a = document.createElement('a'); a.href = url; a.download = filename; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }, true);
}
export function playerMessage(error) {
  if (error.name === 'QuotaExceededError') return 'This browser needs a little more room to keep your garden copy. Your original is still safe at the old address.';
  if (['AbortError', 'TimeoutError', 'TypeError', 'SecurityError', 'UnknownError', 'InvalidStateError'].includes(error.name))
    return 'The move could not finish just now. Your saved copies have been kept. Please try again, or keep gardening at the old address.';
  return error.message || 'The move could not finish just now. Your saved copies have been kept.';
}
function failure(error, bytes) {
  const ui = card('Your garden can wait a moment', playerMessage(error));
  button(ui, 'Try again', () => location.reload());
  link(ui, 'Keep gardening at the old address', `${SOURCE_ORIGIN}/?stay=1`);
  if (bytes) download(ui, bytes, 'Save a backup copy', 'zend-garden-original.json');
}
function clearMovingLink() {
  history.replaceState(null, '', `${location.pathname}${location.search}`);
}
async function acknowledge(token) {
  // The local receipt is already durable. A failed cleanup cannot undo the move.
  try { await requestTransfer('ack', { token }); } catch { /* Relay also expires. */ }
}

export async function moveFromOldAddress() {
  let bytes;
  const ui = card('A new cozy home', 'Your little garden is moving to its new cozy home at zend.garden.');
  ui.status.textContent = 'Gently gathering your garden…';
  try {
    bytes = await readOriginal();
    let destination = HOME_ORIGIN;
    if (bytes) {
      const sealed = await sealCopy(bytes);
      const transfer = await requestTransfer('create', sealed.body);
      if (!TOKEN.test(transfer.token)) throw new Error('The moving link could not be checked. Please try again.');
      // The key stays in the fragment: it is never sent to the relay or in referrers.
      destination += `/#garden-move=${transfer.token}.${sealed.secret}`;
      ui.status.textContent = 'Your garden copy is ready. The original will stay safely here. Taking you there in a moment…';
      download(ui, bytes, 'Save a backup copy', 'zend-garden-original.json');
    } else ui.status.textContent = 'No saved garden was found in this browser here. Taking you to the new home in a moment…';
    button(ui, 'Go to zend.garden', () => location.replace(destination));
    link(ui, 'Stay here for now', `${SOURCE_ORIGIN}/?stay=1`).addEventListener('click', () => clearTimeout(timer));
    // Give the moving message time to be read; no extra click is needed normally.
    const timer = setTimeout(() => location.replace(destination), 6000);
  } catch (error) { failure(error, bytes); }
}

function describe(bytes) {
  try { const data = validateSave(bytes); return `Day ${data.day || 1} · ${data.plants.length} plants`; }
  catch { return 'An existing garden copy'; }
}
async function chooseCopy(pending) {
  if ((!pending.expected && !pending.requiresConsent) || (pending.expected && await sha256(pending.expected) === pending.hash)) {
    await acceptCopy(pending); return;
  }
  const ui = card(pending.expected ? 'Two little gardens' : 'Bring your garden home again', pending.expected
    ? 'There’s already a garden at this address. Choose the one you’d like to continue. Your original copy will be kept safely.'
    : 'We can bring the original copy home again. This returns to the garden saved at the old address.');
  ui.status.textContent = `From the old address: ${describe(pending.bytes)}.${pending.expected ? ` Here already: ${describe(pending.expected)}.` : ''}`;
  await new Promise(resolve => {
    const choose = keep => async () => {
      for (const child of ui.actions.children) if (child.tagName === 'BUTTON') child.disabled = true;
      try { await acceptCopy(pending, keep); resolve(); }
      catch (error) { failure(error, pending.bytes); }
    };
    button(ui, 'Bring my original garden', choose(false));
    // An unreadable current copy can still be downloaded, but cannot start the game.
    try { validateSave(pending.expected); button(ui, 'Keep the garden here', choose(true), true); } catch { /* recovery copy below */ }
    download(ui, pending.bytes, 'Back up the original garden', 'zend-garden-original.json');
    if (pending.expected) download(ui, pending.expected, 'Back up the garden here', 'zend-garden-before-move.json');
  });
}

export async function prepareGarden() {
  // On the recovery route the original game runs without initiating a migration.
  if (location.origin === SOURCE_ORIGIN) return true;
  const fragment = new URLSearchParams(location.hash.slice(1));
  const moving = fragment.get('garden-move');
  let pending;
  try {
    pending = await pendingCopy();
    if (!moving && !pending) return true;
    const ui = card('Welcome to your garden’s new home', 'A little more room to grow, here at zend.garden.');
    ui.status.textContent = 'Checking your garden copy before you enter…';
    if (location.origin !== HOME_ORIGIN) throw new Error('Please open this moving link at zend.garden.');
    if (pending) pending = await refreshPending();
    else {
      const parts = moving.split('.');
      if (parts.length !== 2 || !parts.every(value => TOKEN.test(value))) throw new Error('This moving link is incomplete. Please return to the old address and try again.');
      const [token, secret] = parts;
      const completed = await completedMove();
      if (completed) {
        const current = await readCurrent();
        let readable = false;
        try { if (current) { validateSave(current); readable = true; } } catch { /* offer recovery, preserving this copy */ }
        if (readable) {
          await acknowledge(token); clearMovingLink();
          ui.overlay.remove();
          document.getElementById('status').textContent = 'Your garden is already home here. Your latest progress has been kept.';
          return true;
        }
      }
      const body = await requestTransfer('read', { token });
      const bytes = await unsealCopy(body, secret);
      pending = await withGardenLock(() => stageCopy(bytes, token, !!completed));
    }
    await chooseCopy(pending);
    await acknowledge(pending.token);
    clearMovingLink();
    const arrived = card('Your garden is home', 'Your little garden now lives at zend.garden. Bookmark this address for your next quiet visit.');
    arrived.status.textContent = 'The original copy remains at the old address.';
    download(arrived, pending.bytes, 'Save a backup copy', 'zend-garden-original.json');
    await new Promise(resolve => {
      const enter = button(arrived, 'Continue to the garden', () => { arrived.overlay.remove(); resolve(); });
      enter.focus();
    });
    return 'enter';
  } catch (error) { failure(error, pending?.bytes); return false; }
}

export async function beforeGameStart() {
  const release = await holdGardenSession();
  try {
    const current = await readCurrent();
    if (current) validateSave(current);
    return { release, expected: current ? await sha256(current) : 'empty' };
  } catch (error) { release(); throw error; }
}

if (document.body.dataset.moving === 'true') moveFromOldAddress();
