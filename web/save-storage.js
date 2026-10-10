import { SAVE_FILE, validateSave, sha256 } from './save-format.js';

// Read the existing Godot filesystem without creating or upgrading it.
export async function readCurrent() {
  const db = await new Promise((resolve, reject) => {
    const request = indexedDB.open('/userfs');
    let absent = false, ended = false;
    const timer = setTimeout(() => {
      ended = true;
      reject(new Error('Please close other garden tabs, then try again.'));
    }, 10000);
    request.onupgradeneeded = () => { absent = true; request.transaction.abort(); };
    request.onerror = () => {
      clearTimeout(timer);
      if (!ended) absent ? resolve(null) : reject(request.error);
    };
    request.onsuccess = () => {
      clearTimeout(timer);
      if (ended) { request.result.close(); return; }
      resolve(request.result);
    };
  });
  if (!db) return null;
  db.onversionchange = () => db.close();
  try {
    if (db.version !== 21 || !db.objectStoreNames.contains('FILE_DATA')) {
      throw new Error('This browser’s garden storage could not be opened safely.');
    }
    const entry = await new Promise((resolve, reject) => {
      const tx = db.transaction('FILE_DATA', 'readonly');
      let result;
      tx.objectStore('FILE_DATA').get(SAVE_FILE).onsuccess = event => { result = event.target.result; };
      tx.oncomplete = () => resolve(result);
      tx.onabort = () => reject(tx.error || new Error('Your saved garden could not be read.'));
      tx.onerror = () => {};
    });
    if (!entry) return null;
    if ((entry.mode & 0o170000) !== 0o100000 || !entry.contents) throw new Error('The garden file could not be read safely.');
    return new Uint8Array(entry.contents);
  } finally { db.close(); }
}

// Keep the ordinary multi-tab save lock for the entire game session.
export async function holdGardenSession() {
  if (!navigator.locks) return () => {};
  return new Promise((resolve, reject) => {
    navigator.locks.request('zend-garden-session', { ifAvailable: true }, async lock => {
      if (!lock) { reject(new Error('Your garden is open in another tab. Please close it first.')); return; }
      let release;
      const held = new Promise(done => { release = done; });
      resolve(release);
      await held;
    }).catch(reject);
  });
}

export async function beforeGameStart() {
  const release = await holdGardenSession();
  try {
    const current = await readCurrent();
    if (current) validateSave(current);
    return { release, expected: current ? await sha256(current) : 'empty' };
  } catch (error) { release(); throw error; }
}

export function playerMessage(error) {
  if (error.name === 'QuotaExceededError') return 'This browser needs a little more room to keep your garden. Please free some space and try again.';
  return error.message || 'The garden could not load. Please reload to try again.';
}
