#!/usr/bin/env python3
"""Preview the Pages output with the same static asset behaviour (localhost only)."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'build/web'


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


if __name__ == '__main__':
    if not (ROOT / 'pack.json').exists():
        raise SystemExit('Build the web game first: python3 tools/build_web.py')
    print('Open http://localhost:8080 (Ctrl+C to stop)', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8080), partial(Handler, directory=str(ROOT))).serve_forever()
