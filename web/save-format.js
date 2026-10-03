// This is a guard for the fields the game restores, not a save conversion.
export const MAX_SAVE_BYTES = 4 * 1024 * 1024;
export const SOURCE_ORIGIN = 'https://zend.tammas.com';
export const HOME_ORIGIN = 'https://zend.garden';
export const USER_DIR = '/userfs/godot/app_userdata/Zend Garden';
export const SAVE_FILE = `${USER_DIR}/garden_v1.json`;

const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const number = value => typeof value === 'number' && Number.isFinite(value);
const pair = value => Array.isArray(value) && value.length === 2 && value.every(number);
export function validateSave(bytes) {
  if (!(bytes instanceof Uint8Array) || !bytes.length || bytes.length > MAX_SAVE_BYTES) {
    throw new Error('This garden copy is incomplete or too large to move safely.');
  }
  let data;
  try { data = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { throw new Error('We could not read this garden copy. Your original is still at the old address.'); }
  const fail = () => { throw new Error('This garden copy needs a closer look before it can be moved safely.'); };
  if (!object(data) || ![1, 2].includes(data.version) || !Array.isArray(data.plants)) fail();
  for (const plant of data.plants) {
    if (!object(plant) || !Number.isInteger(plant.id) || plant.id < 0 || !pair(plant.pos)
      || !Number.isInteger(plant.plot) || plant.plot < 0
      || !['age', 'water', 'stress'].every(key => number(plant[key]))) fail();
  }
  for (const key of ['objects', 'orders', 'clean_paths', 'unlocked_plants', 'names']) {
    if (key in data && !Array.isArray(data[key])) fail();
  }
  for (const item of data.objects || []) {
    if (!object(item) || typeof item.kind !== 'string' || !pair(item.pos)
      || !number(item.price) || typeof item.fish !== 'boolean') fail();
  }
  for (const key of ['settings', 'terrain', 'watered_ground', 'wild_collection', 'wild_pruning',
    'inventory', 'upgrades', 'automation', 'expansions', 'path_widths', 'climate']) {
    if (key in data && !object(data[key])) fail();
  }
  for (const key of ['coins', 'day', 'clock', 'unlocked_plots', 'fulfilled', 'planted_total', 'rake_petals']) {
    if (key in data && !number(data[key])) fail();
  }
  if ('player' in data && !pair(data.player)) fail();
  if ('names' in data && (data.names.length !== 2 || data.names.some(name => typeof name !== 'string'))) fail();
  if (data.climate && 'values' in data.climate && (!Array.isArray(data.climate.values)
    || data.climate.values.length !== 3 || !data.climate.values.every(number))) fail();
  for (const order of data.orders || []) {
    if (!object(order) || typeof order.person !== 'string'
      || !['plant', 'count', 'reward'].every(key => number(order[key]))) fail();
  }
  for (const key of ['terrain', 'inventory', 'upgrades', 'expansions', 'path_widths']) {
    if (data[key] && Object.values(data[key]).some(value => !number(value))) fail();
  }
  // GardenTools.water_ground saves patch records, not scalar terrain offsets.
  // Check their shape without converting bytes or dropping expired patches.
  for (const patch of Object.values(data.watered_ground || {})) {
    if (!object(patch) || !['x', 'z', 'radius', 'until'].every(key => number(patch[key]))) fail();
  }
  if ((data.clean_paths || []).some(key => typeof key !== 'string' || !/^-?\d+(?:\.\d+)?:-?\d+(?:\.\d+)?$/.test(key))) fail();
  if ((data.unlocked_plants || []).some(id => !Number.isInteger(id) || id < 0)) fail();
  if (Object.keys(data.automation || {}).some(key => !/^\d+(water|prune)$/.test(key))) fail();
  return data;
}

export async function sha256(bytes) {
  return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)),
    n => n.toString(16).padStart(2, '0')).join('');
}
export function sameBytes(a, b) {
  return a?.length === b?.length && (!a || a.every((value, index) => value === b[index]));
}
export function base64(bytes) {
  let text = '';
  for (let i = 0; i < bytes.length; i += 8192) text += String.fromCharCode(...bytes.subarray(i, i + 8192));
  return btoa(text).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}
export function unbase64(text) {
  if (typeof text !== 'string' || !/^[A-Za-z0-9_-]+$/.test(text)) throw new Error('This moving link is incomplete.');
  return Uint8Array.from(atob(text.replaceAll('-', '+').replaceAll('_', '/')), ch => ch.charCodeAt(0));
}
