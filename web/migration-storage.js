import { SAVE_FILE, USER_DIR, SOURCE_ORIGIN, validateSave, sameBytes, sha256 } from './save-format.js';

const USER_DB = '/userfs';
const FILE_STORE = 'FILE_DATA';
const ARCHIVE_DB = 'zend-garden-migration-v1';
const ARCHIVE_STORE = 'copies';
const SESSION_LOCK = 'zend-garden-session';

function openDB(name, create = false) {
  return new Promise((resolve, reject) => {
    // No version is requested when reading: never upgrade an existing database.
    const request = create ? indexedDB.open(name, name === USER_DB ? 21 : 1) : indexedDB.open(name);
    let absent = false;
    let ended = false;
    const timer = setTimeout(() => {
      ended = true;
      reject(new Error('Please close other garden tabs, then try again.'));
    }, 10000);
    request.onupgradeneeded = () => {
      if (!create || ended) {
        absent = true;
        request.transaction.abort();
      } else if (name === USER_DB) {
        const store = request.result.createObjectStore(FILE_STORE);
        store.createIndex('timestamp', 'timestamp', { unique: false });
      } else request.result.createObjectStore(ARCHIVE_STORE);
    };
    request.onerror = () => {
      clearTimeout(timer);
      if (!ended) absent ? resolve(null) : reject(request.error);
    };
    request.onsuccess = () => {
      clearTimeout(timer);
      const db = request.result;
      if (ended) { db.close(); return; }
      db.onversionchange = () => db.close();
      resolve(db);
    };
  });
}

function transaction(db, storeName, mode, work) {
  return new Promise((resolve, reject) => {
    let result;
    let failure;
    const tx = db.transaction(storeName, mode);
    tx.oncomplete = () => resolve(result);
    tx.onabort = () => reject(failure || tx.error || new Error('The copy could not be saved. Please try again.'));
    tx.onerror = () => {}; // onabort delivers the error once.
    const guard = handler => event => {
      try { handler(event); }
      catch (error) { failure = error; tx.abort(); }
    };
    try { work(tx.objectStore(storeName), value => { result = value; }, error => { failure = error; tx.abort(); }, guard); }
    catch (error) { failure = error; tx.abort(); }
  });
}

async function readEntry(db, path = SAVE_FILE) {
  if (!db.objectStoreNames.contains(FILE_STORE)) throw new Error('We could not find the garden storage. Your original has not been changed.');
  const entry = await transaction(db, FILE_STORE, 'readonly', (store, done) => {
    store.get(path).onsuccess = event => done(event.target.result);
  });
  if (!entry) return null;
  if ((entry.mode & 0o170000) !== 0o100000 || !entry.contents) throw new Error('The garden file could not be read safely.');
  return new Uint8Array(entry.contents);
}

// The source page calls only this reader. It never starts Godot or writes a file.
export async function readOriginal() {
  const db = await openDB(USER_DB);
  if (!db) return null;
  try {
    const canonical = await readEntry(db);
    if (canonical) return canonical;
    // Accommodate older project-name folders, but never guess between two saves.
    const keys = await transaction(db, FILE_STORE, 'readonly', (store, done) => {
      store.getAllKeys().onsuccess = event => done(event.target.result.filter(key =>
        typeof key === 'string' && key.endsWith('/garden_v1.json')));
    });
    if (keys.length > 1) throw new Error('We found more than one garden. Please keep playing here while we help you choose.');
    return keys.length ? await readEntry(db, keys[0]) : null;
  } finally { db.close(); }
}

export async function readCurrent() {
  const db = await openDB(USER_DB);
  if (!db) return null;
  try {
    if (db.version !== 21) throw new Error('This browser’s garden storage needs a closer look before moving.');
    return await readEntry(db);
  } finally { db.close(); }
}

async function archive(work, mode = 'readonly') {
  const db = await openDB(ARCHIVE_DB, true);
  try { return await transaction(db, ARCHIVE_STORE, mode, work); }
  finally { db.close(); }
}
export const pendingCopy = () => archive((store, done) => {
  store.get('pending').onsuccess = event => done(event.target.result || null);
});
export const completedMove = () => archive((store, done) => {
  store.get(`completed:${SOURCE_ORIGIN}`).onsuccess = event => done(event.target.result || null);
});

export async function stageCopy(bytes, token, requiresConsent = false) {
  validateSave(bytes);
  const current = await readCurrent();
  const hash = await sha256(bytes);
  const pending = { bytes, hash, token, source: SOURCE_ORIGIN,
    expected: current, requiresConsent, created: Date.now() };
  // Immutable copies live in a different database: Godot filesystem sync cannot remove them.
  await archive((store, done, abort, guard) => {
    store.get('pending').onsuccess = guard(event => {
      if (event.target.result) { abort(new Error('Another garden copy is waiting. Please finish that move first.')); return; }
      const key = `original:${hash}`;
      store.get(key).onsuccess = guard(existing => { if (!existing.target.result) store.add({ bytes, source: SOURCE_ORIGIN }, key); });
      store.put(pending, 'pending');
      done(pending);
    });
  }, 'readwrite');
  // Verify the staged bytes before any active save can be replaced.
  const stored = await pendingCopy();
  if (!stored || await sha256(stored.bytes) !== hash) throw new Error('The garden copy could not be checked. Your original is safe.');
  return stored;
}

async function finishCopy(pending, choice) {
  await archive(store => {
    store.put({ hash: pending.hash, choice, completed: Date.now() }, `completed:${SOURCE_ORIGIN}`);
    store.delete('pending');
  }, 'readwrite');
}

export async function withGardenLock(work) {
  if (!navigator.locks) throw new Error('Please use a current browser to move your garden safely.');
  return navigator.locks.request(SESSION_LOCK, { ifAvailable: true }, lock => {
    if (!lock) throw new Error('Please close the other garden tab, then try again.');
    return work();
  });
}

export async function acceptCopy(pending, keepCurrent = false) {
  return withGardenLock(async () => {
    validateSave(pending.bytes);
    if (await sha256(pending.bytes) !== pending.hash) throw new Error('The waiting garden copy is incomplete.');
    const actual = await readCurrent();
    if (keepCurrent) {
      if (!actual) throw new Error('There is no garden here to keep.');
      validateSave(actual);
      await finishCopy(pending, 'kept-current');
      return 'kept-current';
    }
    // Resume safely if the tab closed after promotion but before the receipt was saved.
    if (sameBytes(actual, pending.bytes)) {
      await finishCopy(pending, 'imported');
      return 'imported';
    }
    if (!sameBytes(actual, pending.expected)) throw new Error('Your garden here changed while we were moving. Please reload to choose again.');
    if (actual) {
      const key = `before:${await sha256(actual)}`;
      await archive((store, done, abort, guard) => {
        store.get(key).onsuccess = guard(event => { if (!event.target.result) store.add({ bytes: actual }, key); });
      }, 'readwrite');
    }
    const db = await openDB(USER_DB, true);
    try {
      if (db.version !== 21) throw new Error('The garden storage could not be opened safely.');
      await transaction(db, FILE_STORE, 'readwrite', (store, done, abort, guard) => {
        store.get(SAVE_FILE).onsuccess = guard(event => {
          const existing = event.target.result;
          const bytes = existing ? new Uint8Array(existing.contents) : null;
          if (!sameBytes(bytes, actual)) { abort(new Error('Another tab changed this garden. Please reload.')); return; }
          const timestamp = new Date();
          for (const path of ['/userfs/godot', '/userfs/godot/app_userdata', USER_DIR]) {
            store.get(path).onsuccess = guard(entry => {
              if (!entry.target.result) store.put({ timestamp, mode: 0o40755 }, path);
            });
          }
          store.put({ timestamp, mode: 0o100666, contents: pending.bytes }, SAVE_FILE);
        });
      });
    } finally { db.close(); }
    const verified = await readCurrent();
    if (!sameBytes(verified, pending.bytes)) throw new Error('We could not confirm the move. Please retry before entering the garden.');
    await finishCopy(pending, 'imported');
    return 'imported';
  });
}

export async function refreshPending() {
  const pending = await pendingCopy();
  if (!pending) return null;
  pending.expected = await readCurrent();
  await archive(store => store.put(pending, 'pending'), 'readwrite');
  return pending;
}

// Hold the same lock throughout play, not just during loading. Release on exit.
export async function holdGardenSession() {
  if (!navigator.locks) return () => {};
  let release;
  return new Promise((resolve, reject) => {
    navigator.locks.request(SESSION_LOCK, { ifAvailable: true }, async lock => {
      if (!lock) { reject(new Error('Your garden is open in another tab. Please close it first.')); return; }
      const held = new Promise(done => { release = done; });
      resolve(release);
      await held;
    }).catch(reject);
  });
}
