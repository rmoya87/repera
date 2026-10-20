#!/bin/bash
# Repera Business - double-click local launcher for macOS.
# Serves ONLY web/ on loopback. Opens the real Supabase login; --demo opts into offline data.
set -euo pipefail

if [[ $# -gt 1 || ( $# -eq 1 && "${1:-}" != "--demo" ) ]]; then
  echo "Uso: ./Repera-Business.command [--demo]"
  exit 2
fi
MODE="connected"
if [[ "${1:-}" == "--demo" ]]; then MODE="demo"; fi

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

if [[ "$MODE" == "demo" ]]; then
  echo "Repera Business · DEMOSTRACIÓN LOCAL"
  echo "Sin conexión a Supabase; los datos son ficticios."
  echo "No introduzcas datos personales reales en la demostración."
else
  echo "Repera Business · PANEL CONECTADO"
  echo "Requiere iniciar sesión en Supabase Repera."
  echo "Los cambios autorizados pueden modificar datos reales de tu organización."
  echo "Cobros y facturación real no están habilitados. Para datos ficticios usa --demo."
fi
echo

exec python3 - "$ROOT/web" "$MODE" <<'PY'
import http.server
import sys
import threading
import webbrowser

web_root = sys.argv[1]
mode = sys.argv[2]

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
path = "/console/?demo=1" if mode == "demo" else "/console/"
url = f"http://127.0.0.1:{server.server_port}{path}"
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
