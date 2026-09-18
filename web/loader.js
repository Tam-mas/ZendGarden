/* The pack is split for Pages' per-file limit. HTTP gzip is decoded by fetch. */
const play = document.getElementById('play');
const statusText = document.getElementById('status');
const progress = document.getElementById('progress');

async function checkedFetch(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not download ${url} (${response.status}).`);
  return response;
}

async function loadPack() {
  const manifest = await (await checkedFetch('pack.json')).json();
  const pack = new Uint8Array(manifest.size);
  let offset = 0;
  for (const chunk of manifest.chunks) {
    const bytes = new Uint8Array(await (await checkedFetch(chunk.url)).arrayBuffer());
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
    if (missing.length) throw new Error(`This browser needs: ${missing.join(', ')}. Try a current desktop browser.`);
    const engine = new Engine({ ...window.ZEND_GODOT_CONFIG,
      canvas: document.getElementById('canvas'),
      onExit: () => location.reload(),
    });
    // Use the supported manual loader so a single oversized .pck is unnecessary.
    const [, pack] = await Promise.all([engine.init('index'), loadPack()]);
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
