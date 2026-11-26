#!/usr/bin/env python3
"""Serve build/web for a local test, like Firebase hosting does.

  python3 scripts/serve_web.py [port]      # default 8080, folder build/web

A path with no file (the WhatsApp link https://localhost:8080/<code>) gets
index.html, as the rewrite in firebase.json does. The files that decide which
build runs are sent with Cache-Control: no-cache, as in firebase.json.
"""
import http.server, os, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'web')


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=ROOT, **k)

    def do_GET(self):
        path = self.translate_path(self.path.split('?', 1)[0])
        if not os.path.exists(path):
            self.path = '/index.html'
        super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


if __name__ == '__main__':
    print(f'Serving {os.path.normpath(ROOT)} at http://localhost:{PORT}')
    http.server.ThreadingHTTPServer(('', PORT), Handler).serve_forever()
