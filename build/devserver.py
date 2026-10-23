"""Local bridge between Roblox Studio and this folder, for the bundle build.

Studio's HttpService can talk to localhost, so the Studio side of the build
(build/bundle.luau, run from the command bar) fetches files from here and posts the
finished bundle back:

    GET  /<path>          serves a file from the project folder (build/bundle.luau etc.)
    POST /save?name=X     writes the request body to the project folder as X

Only binds to 127.0.0.1, only writes inside the project folder, and only .lua/.luau/.txt
files. Run it from the project folder:  python build/devserver.py
"""

import http.server
import os
import sys
import urllib.parse

PORT = int(os.environ.get("BUNDLE_PORT", "8768"))
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALLOWED = (".lua", ".luau", ".txt")


def inside_root(relative):
    path = os.path.abspath(os.path.join(ROOT, relative))
    if os.path.commonpath([path, ROOT]) != ROOT:
        return None
    return path


class Handler(http.server.BaseHTTPRequestHandler):
    def _reply(self, code, body=b"", kind="text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        relative = urllib.parse.unquote(urllib.parse.urlparse(self.path).path.lstrip("/"))
        path = inside_root(relative)
        if not path or not path.endswith(ALLOWED) or not os.path.isfile(path):
            self._reply(404, b"not found")
            return
        with open(path, "rb") as f:
            self._reply(200, f.read())

    def do_POST(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        name = (query.get("name") or [""])[0]
        path = inside_root(name)
        if not path or not name.endswith(ALLOWED):
            self._reply(400, b"bad name")
            return
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(body)
        print(f"saved {name} ({len(body):,} bytes)", flush=True)
        self._reply(200, f"saved {name} ({len(body)} bytes)".encode())

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"bundle devserver on http://127.0.0.1:{PORT}  (root: {ROOT})", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
