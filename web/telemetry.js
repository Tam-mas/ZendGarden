// Anonymous, in-memory session totals. No tab focus, visibility or input tracking.
export function createTelemetry({ fetch: send = window.fetch.bind(window), now = Date.now,
  every = setInterval, cancel = clearInterval, device = navigator.maxTouchPoints > 0 ? 'touch' : 'desktop',
  on = window.addEventListener.bind(window), randomID = () => crypto.randomUUID() } = {}) {
  let version = 0, started = null, token = null, advancing = 0, timer, busy = false, stopped = false;
  let elapsed = 0;
  let id;
  const running = () => {
    // Wall time includes background throttling and sleep; never observe tab state.
    elapsed = Math.max(elapsed, (now() - started) / 1000, advancing);
    return Math.floor(elapsed);
  };
  async function report(ended = false) {
    if (started === null || stopped || busy) return;
    busy = true;
    try {
      if (!token) {
        const response = await send('/api/session', { method: 'POST', credentials: 'omit',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'start', id, version, device, running: running() }) });
        if (!response.ok) return;
        token = (await response.json()).token;
      }
      await send('/api/session', { method: 'POST', credentials: 'omit', keepalive: ended,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'report', token, running: running(), advancing: Math.floor(advancing), ended }) });
    } catch { /* Analytics must never interrupt loading, play or saving. */ }
    finally { busy = false; }
  }
  return {
    setVersion(value) { if (Number.isInteger(value) && value > 0) version = value; },
    advance(seconds) { if (started !== null && !stopped && Number.isFinite(seconds) && seconds > 0) advancing += seconds; },
    start() {
      if (started !== null || !version) return;
      started = now();
      id = randomID();
      void report();
      timer = every(() => void report(), 120000);
      // pagehide is navigation/closure, never used to infer attention or focus.
      on('pagehide', () => void report(true));
      on('pageshow', event => { if (event.persisted) void report(); });
    },
    async stop() { cancel(timer); await report(true); stopped = true; },
    report,
  };
}
