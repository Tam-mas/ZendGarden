const OLD_HOST = 'zend.tammas.com';
const PAGES = new Set(['/', '/index.html', '/shell.html']);
const MOVING_PATHS = new Set(['/moving', '/moving.html']);
const MOVING_HEADERS = {
  'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY',
  'Strict-Transport-Security': 'max-age=31536000',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=(), usb=()',
  'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; connect-src 'self' https://zend.garden; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
};
export async function onRequest(context) {
  const url = new URL(context.request.url);
  if (context.env.ZEND_MIGRATION_ENABLED === 'true' && url.hostname === OLD_HOST
    && (PAGES.has(url.pathname) || MOVING_PATHS.has(url.pathname)) && url.searchParams.get('stay') !== '1') {
    // Pages redirects .html requests to extensionless paths. Fetch the canonical
    // asset internally so the player stays on this route with its moving policy.
    url.pathname = '/moving'; url.search = '';
    const page = await context.env.ASSETS.fetch(new Request(url, context.request));
    const headers = new Headers(page.headers);
    for (const [name, value] of Object.entries(MOVING_HEADERS)) headers.set(name, value);
    return new Response(page.body, { status: page.status, headers });
  }
  if (url.hostname === OLD_HOST && MOVING_PATHS.has(url.pathname)) {
    return new Response(null,{status:302,headers:{...MOVING_HEADERS,Location:'https://zend.tammas.com/?stay=1'}});
  }
  const page = await context.next();
  // _headers does not govern responses produced by Functions. Apply the game
  // policy explicitly on page routes; API responses have their own CORS policy.
  if (!PAGES.has(url.pathname)) return page;
  const headers = new Headers(page.headers);
  for (const [name, value] of Object.entries(MOVING_HEADERS)) headers.set(name, value);
  headers.set('Cache-Control', 'public, max-age=0, must-revalidate');
  headers.set('Content-Security-Policy', "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self'; media-src 'self' blob:; worker-src 'self' blob:; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests");
  return new Response(page.body, { status: page.status, headers });
}
