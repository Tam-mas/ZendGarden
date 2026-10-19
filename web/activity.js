const $ = id => document.getElementById(id);
const number = value => Number(value || 0).toLocaleString(undefined, { maximumFractionDigits: 1 });
const duration = seconds => seconds >= 3600 ? `${number(seconds / 3600)} h` : `${number(seconds / 60)} min`;
function node(tag, text, className) {
  const element = document.createElement(tag);
  if (text !== undefined) element.textContent = text;
  if (className) element.className = className;
  return element;
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
    ['Garden visits', number(t.sessions), 'Separate times the garden was opened'],
    ['Game-open time', duration(t.running), 'Includes background and paused time'],
    ['Garden advancing', duration(t.advancing), 'Time the garden clock advances'],
    ['Average visit', duration(t.average), 'Game-open time per visit'],
    ['Median visit', duration(t.median), 'The middle visit length'],
    ['Longest visit', duration(t.longest), 'The longest recorded garden visit'],
  ]) {
    const card = node('div', undefined, 'card'); card.append(node('div', label), node('strong', value), node('span', note)); $('cards').append(card);
  }
  bars('lengths', [['5+ minutes', t.over5], ['15+ minutes', t.over15], ['30+ minutes', t.over30]], t.sessions);
  bars('devices', data.devices.map(row => [row.name === 'touch' ? 'Touch device' : 'Desktop', row.sessions]), t.sessions);
}
async function load() {
  try {
    const response = await fetch('/api/activity', { credentials: 'omit', cache: 'default' });
    if (!response.ok) throw new Error('Garden activity is unavailable just now. Please try again later.');
    render(await response.json()); $('activity').hidden = false;
    $('status').textContent = 'These shared figures are updated daily.';
  } catch (error) { $('status').textContent = error.message; }
}
void load();
