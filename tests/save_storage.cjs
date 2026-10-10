const assert = require('node:assert/strict');
const { webcrypto } = require('node:crypto');
global.crypto = webcrypto;
(async () => {
  const { validateSave, sha256 } = await import('../web/save-format.js');
  const storage = await import('../web/save-storage.js');
  const encode = value => new TextEncoder().encode(JSON.stringify(value));
  for (const version of [1, 2, 3]) {
    const data = { version, day: 17, plants: [{ id: 0, plot: 0, pos: [1, -2], age: .8, water: 2, stress: 0 }],
      watered_ground: { '2:-4': { x: 1, z: -2, radius: .65, until: 18.3 } },
      settings: { intro_seen: true }, names: ['Miso', 'Clover'],
      breeding: { forms: { 'form-1': { name: 'Misty petals', archived: false } } } };
    const bytes = encode(data); assert.deepEqual(validateSave(bytes), data);
    assert.match(await sha256(bytes), /^[0-9a-f]{64}$/);
  }
  for (const data of [{ version: 4, plants: [] }, { version: 2, plants: null }, { version: 2, plants: [], player: [0] },
    ...[2, null, [], { x: 1, z: 2, radius: .65 }, { x: 1, z: 2, radius: 'wide', until: 18 }]
      .map(patch => ({ version: 2, plants: [], watered_ground: { '2:4': patch } }))]) assert.throws(() => validateSave(encode(data)));
  assert.throws(() => validateSave(new Uint8Array([0xff]))); assert.throws(() => validateSave(new Uint8Array(4 * 1024 * 1024 + 1)));
  let held = false;
  // Node versions may already expose a read-only navigator property.
  Object.defineProperty(global, 'navigator', { configurable: true, value: { locks: { request: async (name, options, work) => {
    assert.equal(name, 'zend-garden-session'); assert.equal(options.ifAvailable, true);
    if (held) return work(null); held = true; try { await work({}); } finally { held = false; }
  } } } });
  const release = await storage.holdGardenSession();
  await assert.rejects(storage.holdGardenSession(), /another tab/);
  release(); await new Promise(setImmediate);
  const again = await storage.holdGardenSession(); again();
  console.log('SAVE_STORAGE_RESULT: PASS — v1/v2/v3 and cultivar data, watered-ground validation, corruption/size limits and whole-session save locks');
})().catch(error => { console.error(error); process.exitCode = 1; });
