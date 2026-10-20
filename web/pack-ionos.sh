#!/usr/bin/env bash
# Empaqueta solo lo necesario para subir a IONOS (htdocs).
# Uso: ./pack-ionos.sh
# Salida: web/reperaapp-ionos.zip (gitignored)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${ROOT}/repera-ionos.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "${STAGE}/css" "${STAGE}/js" "${STAGE}/assets" "${STAGE}/console"

cp "${ROOT}/.htaccess" "${STAGE}/"
cp "${ROOT}/index.html" "${ROOT}/privacy.html" "${ROOT}/terms.html" "${ROOT}/faq.html" "${STAGE}/"
cp "${ROOT}/robots.txt" "${ROOT}/sitemap.xml" "${STAGE}/"
cp "${ROOT}/css/site.css" "${STAGE}/css/"
cp "${ROOT}/js/site.js" "${STAGE}/js/"
# Acceso profesional autenticado con Supabase; ningún dato real se empaqueta.
cp "${ROOT}/console/index.html" "${STAGE}/console/"
cp -R "${ROOT}/console/src" "${STAGE}/console/src"
cp -R "${ROOT}/assets/exercises" "${STAGE}/assets/exercises"
cp "${ROOT}/assets/"*.png "${STAGE}/assets/" 2>/dev/null || true
cp "${ROOT}/assets/"*.jpg "${STAGE}/assets/" 2>/dev/null || true
cp "${ROOT}/assets/"*.jpeg "${STAGE}/assets/" 2>/dev/null || true
cp "${ROOT}/assets/"*.webp "${STAGE}/assets/" 2>/dev/null || true

# Instrucciones mínimas dentro del zip (IONOS File Manager)
cat > "${STAGE}/LEEME-SUBIR.txt" <<'EOF'
Repera — subir a IONOS
======================

1. Abre el File Manager / FTP del dominio (repera.app).
2. Entra en la raíz del sitio (htdocs o document root).
3. Extrae AQUÍ el contenido de este zip (no dejes una carpeta intermedia).
   Debe quedar: index.html y .htaccess en la misma carpeta.
4. Activa archivos ocultos y comprueba que existe .htaccess.
5. En el panel IONOS: SSL (Let's Encrypt) + Forzar HTTPS.
6. Prueba:
   https://repera.app/
   https://repera.app/privacy
   https://repera.app/terms
   https://repera.app/faq
   https://repera.app/console/ (login profesional; requiere redirects Auth de Supabase)

No subas README.md del repo ni _redirects / _headers (son para Netlify).
EOF

rm -f "$OUT"
(
  cd "$STAGE"
  # -X omite atributos extra; incluye dotfiles (.htaccess)
  zip -r -X "$OUT" . \
    -x "*.DS_Store" \
    -x "**/.DS_Store"
)

echo "OK → $OUT"
unzip -l "$OUT"
echo
echo "Siguiente: sube/extrae repera-ionos.zip en htdocs de IONOS."
