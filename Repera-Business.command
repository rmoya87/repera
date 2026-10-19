#!/bin/bash
# Repera Business - double-click local launcher for macOS.
# Serves ONLY the web/ directory on loopback. The initial page uses isolated demo data.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$ROOT/web/console/index.html" ]]; then
  echo "ERROR: No se encuentra web/console/index.html."
  echo "Este lanzador debe estar en la raíz del repositorio Repera."
  read -r -p "Pulsa Intro para cerrar..." _ || true
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Es necesario Python 3 (instala las Xcode Command Line Tools o Python 3)."
  read -r -p "Pulsa Intro para cerrar..." _ || true
  exit 1
fi

echo "Repera Business · DEMOSTRACIÓN LOCAL"
echo "No requiere conexión a Supabase ni realiza cobros o reservas reales."
echo "No introduzcas datos personales reales en la demostración."
echo

exec python3 - "$ROOT/web" <<'PY'
import http.server
import sys
import threading
import webbrowser

web_root = sys.argv[1]

class ReperaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=web_root, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

class LoopbackServer(http.server.ThreadingHTTPServer):
    daemon_threads = True

server = LoopbackServer(("127.0.0.1", 0), ReperaHandler)
url = f"http://127.0.0.1:{server.server_port}/console/?demo=1"
print(f"Abriendo: {url}", flush=True)
print("Cierra esta ventana o pulsa Control+C para detener el servidor.", flush=True)
threading.Timer(0.4, lambda: webbrowser.open(url)).start()
try:
    server.serve_forever(poll_interval=0.2)
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
PY
