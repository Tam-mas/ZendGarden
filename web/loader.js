/* Pages serves compressed assets as bytes; decode gzip explicitly in the browser. */
const play = document.getElementById('play');
const statusText = document.getElementById('status');
const progress = document.getElementById('progress');

async function checkedFetch(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not download ${url} (${response.status}).`);
  return response;
}

async function decodedResponse(response) {
  if (!response.ok) throw new Error(`Could not download a game file (${response.status}).`);
  const bytes = new Uint8Array(await response.arrayBuffer());
  // Some hosts decode HTTP gzip themselves; support both without decoding twice.
  const compressed = bytes[0] === 0x1f && bytes[1] === 0x8b;
  if (compressed && typeof DecompressionStream === 'undefined') {
    throw new Error('Please update your browser to load the garden.');
  }
  const body = compressed
    ? new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))
    : bytes;
  return new Response(body, { headers: { 'Content-Type': 'application/wasm' } });
}

async function initEngine(engine) {
  // Godot's public init API fetches <base>.wasm internally. Adapt only that
  // request while init runs; audio worklets and all other requests pass through.
  const originalFetch = window.fetch;
  const wasmURL = new URL('index.wasm', location.href).href;
  window.fetch = async (input, options) => {
    const url = new URL(input instanceof Request ? input.url : input, location.href).href;
    const response = await originalFetch.call(window, input, options);
    return url === wasmURL ? decodedResponse(response) : response;
  };
  try {
    await engine.init('index');
  } finally {
    window.fetch = originalFetch;
  }
}

async function loadPack() {
  const manifest = await (await checkedFetch('pack.json')).json();
  const pack = new Uint8Array(manifest.size);
  let offset = 0;
  for (const chunk of manifest.chunks) {
    const bytes = new Uint8Array(await (await decodedResponse(await checkedFetch(chunk.url))).arrayBuffer());
    const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)),
      value => value.toString(16).padStart(2, '0')).join('');
    if (bytes.byteLength !== chunk.size || hash !== chunk.sha256) {
      throw new Error('A game download was incomplete. Please reload and try again.');
    }
    pack.set(bytes, offset);
    offset += bytes.byteLength;
    progress.value = offset / manifest.size;
    statusText.textContent = `Preparing your garden… ${Math.round(progress.value * 100)}%`;
  }
  if (offset !== manifest.size) throw new Error('The game download was incomplete.');
  return pack.buffer;
}

play.addEventListener('click', async () => {
  if (play.dataset.retry) { location.reload(); return; }
  play.disabled = true;
  progress.hidden = false;
  statusText.textContent = 'Preparing your garden…';
  try {
    const missing = Engine.getMissingFeatures({ threads: false });
    if (missing.length) throw new Error(`This browser needs: ${missing.join(', ')}. Try a current browser with WebGL 2 support.`);
    const engine = new Engine({ ...window.ZEND_GODOT_CONFIG,
      canvas: document.getElementById('canvas'),
      onExit: () => location.reload(),
    });
    // Use the supported manual loader so a single oversized .pck is unnecessary.
    const [, pack] = await Promise.all([initEngine(engine), loadPack()]);
    statusText.textContent = 'Opening the garden…';
    await engine.preloadFile(pack, 'index.pck');
    await engine.start({ args: ['--main-pack', 'index.pck'] });
    document.getElementById('welcome').hidden = true;
    document.getElementById('canvas').focus();
  } catch (error) {
    console.error(error);
    statusText.textContent = error.message || 'The garden could not load. Please try again.';
    progress.hidden = true;
    play.textContent = 'Try again';
    play.dataset.retry = 'true';
    play.disabled = false;
  }
});
