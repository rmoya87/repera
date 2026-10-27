#!/bin/bash
# Repera Business - double-click local launcher for macOS.
# Serves web/ over loopback and always opens the real Supabase console.
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Uso: ./Repera-Business.command"
  echo "La versión conectada a Supabase no dispone de modo demostración."
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$ROOT/web/console/index.html" ]]; then
  echo "ERROR: No se encuentra web/console/index.html."
  echo "Este lanzador debe estar en la raíz del repositorio Repera."
  read -r -p "Pulsa Intro para cerrar... " _ || true
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Es necesario Python 3 (instala las Xcode Command Line Tools o Python 3)."
  read -r -p "Pulsa Intro para cerrar... " _ || true
  exit 1
fi

echo "Repera Business · PANEL CONECTADO A SUPABASE"
echo "Requiere iniciar sesión en Supabase Repera."
echo "Las operaciones autorizadas pueden modificar datos reales."
echo "Los cobros con Stripe todavía no están habilitados."
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
url = f"http://127.0.0.1:{server.server_port}/console/"
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
