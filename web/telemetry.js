// Anonymous, in-memory session totals. No tab focus, visibility or input tracking.
export function createTelemetry({ fetch: send = window.fetch.bind(window), now = Date.now,
  every = setInterval, cancel = clearInterval, device = navigator.maxTouchPoints > 0 ? 'touch' : 'desktop',
  on = window.addEventListener.bind(window), randomID = () => crypto.randomUUID() } = {}) {
  let version = 0, started = null, token = null, advancing = 0, timer, busy = false, stopped = false;
  let elapsed = 0;
  let reportOffset = 0, advancingOffset = 0;
  let gameMinutes = 0, gameMinutesOffset = 0;
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
          body: JSON.stringify({ action: 'start', id, version, device, running: 0 }) });
        if (!response.ok) return;
        const session = await response.json();
        token = session.token;
        // Time before the first server-accepted start cannot be authenticated.
        // A lost response may be retried with the same ID and original server time.
        reportOffset = running() - (session.elapsed || 0);
        advancingOffset = advancing;
        gameMinutesOffset = gameMinutes;
      }
      await send('/api/session', { method: 'POST', credentials: 'omit', keepalive: ended,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'report', token, running: Math.max(0, running() - reportOffset), advancing: Math.floor(advancing - advancingOffset),
          game_minutes: Math.floor(gameMinutes - gameMinutesOffset + 1e-7), ended }) });
    } catch { /* Analytics must never interrupt loading, play or saving. */ }
    finally { busy = false; }
  }
  return {
    setVersion(value) { if (Number.isInteger(value) && value > 0) version = value; },
    advance(seconds) { if (started !== null && !stopped && Number.isFinite(seconds) && seconds > 0) advancing += seconds; },
    progress(minutes) { if (started !== null && !stopped && Number.isFinite(minutes) && minutes > 0) gameMinutes += minutes; },
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
