#!/bin/bash
# Repera Web — vista local de repera.app (doble clic en macOS).
# Sirve web/ en loopback y abre la home. Las rutas absolutas (/css, /casos, …) funcionan.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$ROOT/web/index.html" ]]; then
  echo "ERROR: No se encuentra web/index.html."
  echo "Este lanzador debe estar en la raíz del repositorio Repera."
  read -r -p "Pulsa Intro para cerrar... " _ || true
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Es necesario Python 3 (instala las Xcode Command Line Tools o Python 3)."
  read -r -p "Pulsa Intro para cerrar... " _ || true
  exit 1
fi

echo "Repera Web · vista local de repera.app"
echo "Cierra esta ventana o pulsa Control+C para detener el servidor."
echo

exec python3 - "$ROOT/web" <<'PY'
import http.server
import os
import sys
import threading
import urllib.parse
import webbrowser
from pathlib import Path

web_root = Path(sys.argv[1]).resolve()

PRETTY = {
    "privacy": "privacy.html",
    "terms": "terms.html",
    "faq": "faq.html",
    "funcionalidades": "funcionalidades.html",
    "casos": "casos.html",
    "outdoor": "outdoor.html",
    "recuperacion": "recuperacion.html",
    "ia": "ia.html",
    "precios": "precios.html",
    "soporte": "soporte.html",
}


class ReperaWebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(web_root), **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = urllib.parse.unquote(parsed.path)
        qs = f"?{parsed.query}" if parsed.query else ""

        if path in ("", "/"):
            return super().do_GET()

        clean = path.strip("/")
        if clean in PRETTY:
            self.path = f"/{PRETTY[clean]}{qs}"
            return super().do_GET()

        if clean.startswith("casos/"):
            slug = clean.split("/", 1)[1].rstrip("/")
            if slug and "/" not in slug and (web_root / "casos" / f"{slug}.html").is_file():
                self.path = f"/casos/{slug}.html{qs}"
                return super().do_GET()

        return super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


class LoopbackServer(http.server.ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


os.chdir(web_root)
server = LoopbackServer(("127.0.0.1", 0), ReperaWebHandler)
url = f"http://127.0.0.1:{server.server_port}/"
print(f"Abriendo: {url}", flush=True)
threading.Timer(0.4, lambda: webbrowser.open(url)).start()
try:
    server.serve_forever(poll_interval=0.2)
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
PY
