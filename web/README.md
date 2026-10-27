# Web Repera (`repera.app`)

## Administración global de Repera Business (2026-10-27)

La consola conectada `web/console/` dispone de interfaz separada para administradores de plataforma verificados. Inicio, gimnasios, entrenadores, fichas, altas pendientes, planes, pagos B2B, soporte y auditoría están implementados en `src/ui/platform-admin.js`; UI responsive en `src/platform-admin.css`. Las acciones se validan mediante RPC en Supabase y los permisos de negocio delegados caducan a los 30 minutos.

Las altas administrativas quedan pendientes hasta el primer inicio de sesión del propietario con email confirmado. Ni las altas ni la selección de planes envían mensajes, cobran tarjetas ni activan suscripciones. El apartado Pagos muestra **solo** operaciones verificados en `platform_billing_payments` (actualmente sin webhook de Stripe), separadas de las intenciones de compra. La gestión B2C y la facturación legal requieren integración posterior.

Para desarrollo local: `cd web/console && npm test` y `python3 -m http.server 8080`; la demo `?demo=1` permanece aislada del backend real.


Sitio HTML estático: producto, precios, FAQ de suscripción, privacidad y términos.
Cumple enlaces requeridos por App Store / paywall y es reutilizable en Google Play.

Última actualización: 2026-10-19

## Páginas

| URL canónica | Archivo |
|--------------|---------|
| `https://repera.app/` | `index.html` |
| `https://repera.app/privacy` | `privacy.html` |
| `https://repera.app/terms` | `terms.html` |
| `https://repera.app/faq` | `faq.html` |

La app iOS enlaza privacidad y términos desde `CommercialConfig` (`repera.app/privacy` y `/terms`).

## Vista local

```bash
cd web
python3 -m http.server 8080
# Abrir http://localhost:8080
# Nota: las URLs sin .html (/privacy) requieren Apache; en local usa privacy.html
```

## Deploy en IONOS (recomendado)

Hosting Apache compartido. Lo más simple: **generar el zip e extraerlo en `htdocs`**.

### 1. Empaquetar (solo lo necesario)

```bash
cd web
./pack-ionos.sh
# → crea web/repera-ionos.zip (no se versiona; regenerable)
```

El zip incluye:

| Incluido | No incluido |
|----------|-------------|
| [`.htaccess`](.htaccess) | `README.md`, `pack-ionos.sh` |
| `index.html`, `privacy.html`, `terms.html`, `faq.html` | `_redirects`, `_headers` (Netlify) |
| `css/`, `js/`, `assets/` | `.DS_Store` |
| `robots.txt`, `sitemap.xml` | |
| `LEEME-SUBIR.txt` (pasos en el zip) | |

### 2. Subir a IONOS

1. File Manager o FTP → raíz del dominio (`htdocs` / document root de `repera.app`).
2. Sube `repera-ionos.zip` y **extrae ahí** (sin carpeta intermedia): deben quedar `index.html` y `.htaccess` al mismo nivel.
3. Activa **archivos ocultos** y confirma que existe `.htaccess`.
4. Panel IONOS: **SSL** (Let's Encrypt) + **Forzar HTTPS**.
5. Borra el `.zip` del servidor si lo dejaste subido.
6. Comprueba:
   - `https://repera.app/`
   - `https://repera.app/privacy`
   - `https://repera.app/terms`
   - `https://repera.app/faq`
   - CSS e imágenes de la home

### Qué hace [`.htaccess`](.htaccess)

- Pretty URLs: `/privacy` → `privacy.html` (igual `/terms`, `/faq`)
- Redirección SEO de `*.html` → URL limpia
- Compresión gzip (HTML/CSS/JS)
- Cabeceras de seguridad
- Caché de estáticos
- Bloqueo de zips / README / archivos Netlify

Si `/privacy` da 404: `.htaccess` no está en la misma carpeta que `index.html`, o el hosting no aplica `mod_rewrite` (en IONOS compartido sí).

### Alternativas

#### GitHub Pages

1. Settings → Pages → Source: carpeta `/web` (o branch `gh-pages` con el contenido de `web/`).
2. Dominio personalizado: `repera.app` + DNS.
3. Pretty URLs: publica con un Action que copie `privacy.html` → `privacy/index.html`, etc. (Pages no usa `.htaccess`).

#### Netlify / Cloudflare Pages

- Root publish: `web`
- Archivo [`_redirects`](_redirects) para `/privacy` → `/privacy.html`, etc.
- [`_headers`](_headers) (Netlify): cabeceras de seguridad básicas.

## Checklist App Store Connect

- [ ] URL de Política de privacidad → `https://repera.app/privacy`
- [ ] EULA / términos (o estándar Apple + enlace a `https://repera.app/terms`)
- [ ] Sustituir placeholder App Store (`id0000000000`) en `index.html` por el ID real
- [ ] Revisar textos legales con asesoría si hace falta (base orientativa UE/ES)

## Google Play (futuro)

- Misma privacidad y términos.
- Activar CTA «Google Play» en `index.html` cuando exista el listado.
- Gestión de suscripciones: enlace ya presente en footer/FAQ.

## SEO

- Canonical, `robots.txt`, `sitemap.xml`
- Open Graph + Twitter Cards en la home; OG básico en legales/FAQ
- JSON-LD: Organization / WebSite / SoftwareApplication (home) y FAQPage (faq)
- Contenido en español (`lang="es"`), títulos y meta description por página

## UX / accesibilidad

- Nav responsive: hamburguesa &lt; 900px; enlaces compactos en tablet/desktop
- Reveal al scroll con `IntersectionObserver`; respeta `prefers-reduced-motion`
- Skip link, focus visible, botones táctiles ≥ ~44px en CTAs del banner

## Cookies (GDPR-ready)

Banner en todas las páginas + panel de preferencias:

- Esenciales: `localStorage` (`repera_cookie_prefs_v1`) para recordar la elección
- Analítica: opt-in; **no se carga ningún script de terceros** hasta que configures un proveedor en `js/site.js` (hook `repera:cookie-prefs`)
- Reabrir: enlace «Cookies» / «Preferencias de cookies» en footer
- Política: `privacy.html#cookies` (en producción: `/privacy#cookies`)

## Diseño

Tokens alineados a la app: fondo negro, acento `#30d158`, superficies `#1c1c1e`.
Sin frameworks. CSS en `css/site.css`, interacción en `js/site.js`.

Secciones home: hero, pilares, cómo funciona, para quién, funciones, Watch, confianza, planes, precios, CTA.

## Pendiente editorial

- ID real de App Store / enlace de Google Play.
- Revisión legal profesional de `privacy.html` y `terms.html` antes de producción.
- Capturas oficiales de producto (hoy: mascota PNG transparente `mascot-hero.png` / `mascot-watch.png`; favicon = AppIcon).
- Proveedor de analítica (solo tras consentimiento) si se desea medición.


## Consentimiento de asistentes · 2026-10-24

Última actualización: 2026-10-24. `pack-ionos.sh` incluye `ai/` para `https://repera.app/ai/`. Usa login Apple/Google con la cuenta de Repera y consentimiento explícito, sin claves manuales. Requiere desplegar el backend y configurar OAuth antes de habilitar los botones; no está publicado automáticamente. Procedimiento: [OAUTH_CONNECTIONS.md](../docs/OAUTH_CONNECTIONS.md).
