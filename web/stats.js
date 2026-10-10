const $ = id => document.getElementById(id);
let password = '', loading = false;
const number = value => Number(value || 0).toLocaleString(undefined, { maximumFractionDigits: 1 });
const duration = seconds => seconds >= 3600 ? `${number(seconds / 3600)} h` : `${number(seconds / 60)} min`;
function node(tag, text, className) {
  const element = document.createElement(tag);
  if (text !== undefined) element.textContent = text;
  if (className) element.className = className;
  return element;
}
function table(target, headings, rows) {
  const result = node('table'), head = node('tr');
  for (const label of headings) { const cell = node('th', label); cell.scope = 'col'; head.append(cell); }
  const thead = node('thead'); thead.append(head); result.append(thead);
  const body = node('tbody');
  for (const row of rows) { const tr = node('tr'); for (const value of row) tr.append(node('td', value)); body.append(tr); }
  result.append(body); $(target).replaceChildren(result);
}
function bars(target, rows, total) {
  $(target).replaceChildren();
  for (const [label, value] of rows) {
    const row = node('div', undefined, 'bar-row'), bar = node('div', undefined, 'bar'), fill = node('i');
    fill.style.width = `${total ? Math.min(100, value / total * 100) : 0}%`;
    bar.append(fill); row.append(node('span', label), bar, node('span', number(value))); $(target).append(row);
  }
}
function render(data) {
  const t = data.totals; $('cards').replaceChildren();
  for (const [label, value, note] of [
    ['Sessions', number(t.sessions), 'Separate garden visits'],
    ['Game-open time', duration(t.running), 'Includes background and paused time'],
    ['Garden advancing', duration(t.advancing), 'Time the garden clock advances'],
    ['Average session', duration(t.average), 'Game-open time per visit'],
    ['Median session', duration(t.median), 'The middle visit length'],
    ['Longest session', duration(t.longest), `${number(t.recent)} reporting in the last 5 minutes`],
  ]) {
    const card = node('div', undefined, 'card'); card.append(node('div', label), node('strong', value), node('span', note)); $('cards').append(card);
  }
  table('daily', ['Start day (UTC)', 'Sessions', 'Game open', 'Garden advancing'], data.daily.map(row => [row.day, number(row.sessions), duration(row.running), duration(row.advancing)]));
  bars('lengths', [['5+ minutes', t.over5], ['15+ minutes', t.over15], ['30+ minutes', t.over30]], t.sessions);
  bars('devices', data.devices.map(row => [row.name === 'touch' ? 'Touch device' : 'Desktop', row.sessions]), t.sessions);
  table('versions', ['Game update', 'Sessions', 'Game open', 'Garden advancing'], data.versions.map(row => [row.name, number(row.sessions), duration(row.running), duration(row.advancing)]));
}
function lock() {
  password = ''; $('password').value = ''; $('dashboard').hidden = true; $('login').hidden = false;
  for (const id of ['cards', 'daily', 'lengths', 'devices', 'versions']) $(id).replaceChildren();
}
async function load() {
  if (loading) return;
  loading = true; $('refresh').disabled = true; $('status').textContent = 'Loading statistics…';
  try {
    const response = await fetch('/api/stats', { method: 'POST', credentials: 'omit', cache: 'no-store',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + password }, body: JSON.stringify({ days: Number($('days').value) }) });
    if (response.status === 401) { lock(); throw new Error('That password was not recognised.'); }
    if (!response.ok) throw new Error('Statistics are unavailable just now. Please try again shortly.');
    const data = await response.json();
    // A pending request must not reopen a dashboard the owner just locked.
    if (!password) return;
    render(data); $('login').hidden = true; $('dashboard').hidden = false; $('password').value = '';
    $('status').textContent = `Updated ${new Date(data.generated * 1000).toLocaleTimeString()}. ${data.totals.sessions ? 'Includes sessions still open.' : 'No sessions recorded in this period yet.'}`;
  } catch (error) { $('status').textContent = error.message; }
  finally { loading = false; $('refresh').disabled = false; }
}
$('login').addEventListener('submit', event => { event.preventDefault(); password = $('password').value.trim(); void load(); });
$('refresh').addEventListener('click', () => void load());
$('days').addEventListener('change', () => void load());
$('logout').addEventListener('click', () => { lock(); $('status').textContent = 'Dashboard locked.'; $('password').focus(); });
