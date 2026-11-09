# Web Repera (`repera.app`)

## Fichas y navegación del centro (27/10/2026)

Consola global: Atletas -> Ejercicios, Datos, Acceso, Reservas; ejercicios en dos columnas con calendario, carga de sesión y elementos del catálogo; récords e1RM limitados al historial disponible, mapa orientativo y puntuación transparente de actividad. Centros -> Datos, Equipo, Clientes, Facturación, con listas pulsables y control de publicación en búsqueda sin requerir que el propietario ya se haya registrado.

Centro delegado: menú fijo con logotipo del centro y Ajustes/Volver/Cerrar sesión abajo, sin gran cabecera blanca. Clientes como lista; ficha breve con entrenamiento compartido por consentimiento, datos básicos y reservas. Alta de cliente crea invitación pendiente; acepta desde el correo de su propia cuenta; envío por endpoint Resend JWT protegido solo si configurado.

Para emails reales habilitar secretos `RESEND_API_KEY`, `REPERA_INVITE_FROM`, `REPERA_PUBLIC_URL` en Supabase Edge; opcionales `REPERA_IOS_URL`, `REPERA_ANDROID_URL`. No se deben inventar enlaces de App Store o Google Play. Se recomienda validar entrega y enlaces con una cuenta ya registrada y otra nueva antes de producción. El proyecto usa recursos con caché `20261027profiles`.


## Centro profesional renovado — 27/10/2026

El menú delegado conserva la interfaz clara, navegación lateral y botones directos de Inicio → Deportistas, Entrenamientos y Clases/Reservas. Inicio recibe solicitudes enviadas desde la app con Aceptar/Rechazar/Actualizar. En Entrenamientos hay un planificador rápido de tres pasos con selección de plantilla, deportistas vinculados y modo día/semana/rango; enseña el número calculado de entrenamientos, bloquea solicitudes incompletas y admite máximo 120 sesiones en una operación atómica idempotente. Mantiene el editor completo por bloques para una persona.

El panel global de Atletas enlaza desde cualquier punto de la fila; la ficha muestra calendario, días activos, sesiones, fotografías del catálogo nativo y series, sin variables técnicas. El estado operativo de centros es independiente del registro pendiente del propietario.

Backend protegido por funciones de Supabase y RLS. Migraciones 20261027181000–20261027182000 aplicadas. Para comprobar localmente, `git pull --ff-only origin main`, reiniciar `Repera-Business.command` y recargar la consola. Pendientes navegador E2E, dos usuarios Auth distintos y despliegue IONOS.


## Repera Business Admin: panel renovado (27/10/2026)

Favicon idéntico a AppIcon de iOS en web/assets/repera-app-icon.png. Sidebar sin cabecera duplicada ni Auditoría, plegable y persistente; fichas de centros/atletas completas contra RPCs de Supabase. Estado operativo editable en centro y acceso delegado con un clic, auditado y sin credenciales de terceros. Cinco filtros de Pagos en línea única.

La configuración añade prueba gratuita variable y describe las integraciones todavía pendientes. Requiere actualizar main y reiniciar Repera-Business.command; E2E visual y despliegue IONOS pendientes.


## Vista de centros pendientes — 27/10/2026

«Centros» incluye registros pendientes con acceso a ficha, bloqueo/reactivación y vista de administrador delegado de 30 minutos, incluso antes de que el futuro propietario confirme su correo. Los espacios se crean en Supabase de forma privada y se asignan al titular cuando este acredita su email, sin crear duplicados. Esta vista delegada no intercambia identidad ni credenciales del cliente.

Barra superior global eliminada. Cuatro indicadores por fila en Pagos, versión adaptable a móvil. Imágenes de gimnasio, entrenador y perfil mostradas de forma circular. Para ver los cambios locales, actualiza `origin/main`, vuelve a abrir `Repera-Business.command` y recarga los recursos actualizados con versión `20261027pending`.


## Panel de administración global (27/10/2026)

Menú único **Centros** (gimnasios, centros deportivos, entrenadores con columna diferenciadora), **Atletas** (cuentas incluso sin centro), **Pagos**, **Planes** (catálogo simplificado), **Soporte**, **Auditoría** y **Configuración** (contactos persistidos). La identidad del administrador se muestra en el pie del menú: pulsar avatar/nombre abre nombre/foto, correo y contraseña. Los desplegables de filtros y formularios tienen un estilo consistente en `platform-admin-polish.css`.

Las imágenes de alta se convierten a JPEG, limitadas al bucket comercial mediante permisos por carpeta `pending/{uuid}` y asociadas por RPC a la prealta. El propietario recibe esa imagen al confirmar y reclamar el centro. No se simula ningún cobro. Los datos no provienen de fixtures locales.

Para actualizar la versión local: `git pull --ff-only origin main` y volver a abrir `Repera-Business.command`; los recursos usan versión de caché `20261027u`.


## Inicio local exclusivamente conectado (2026-10-27)

`Repera-Business.command` abre `/console/` y utiliza exclusivamente Supabase Auth y PostgREST de Repera. Se ha retirado la opción de demostración y el enlace del encabezado; los parámetros de URL ya no permiten acceder a datos precargados. El administrador global se determina antes de consultar las membresías de negocio, evitando un bloqueo de la consola por reglas RLS de tenants.

Se aplica en la base de datos `20261027140000_fix_platform_membership_rls.sql` para corregir el error de permisos observado al iniciar sesión. Tras actualizar `main`, cerrar el servidor anterior y abrir de nuevo la consola; el navegador recibe archivos versionados. Los ficheros demo heredados quedan desconectados del arranque; los tests unitarios pueden seguir utilizando fixtures sin afectar a producción.


## Administración global de Repera Business (2026-10-27)

La consola conectada `web/console/` dispone de interfaz separada para administradores de plataforma verificados. Inicio, gimnasios, entrenadores, fichas, altas pendientes, planes, pagos B2B, soporte y auditoría están implementados en `src/ui/platform-admin.js`; UI responsive en `src/platform-admin.css`. Las acciones se validan mediante RPC en Supabase y los permisos de negocio delegados caducan a los 30 minutos.

Las altas administrativas quedan pendientes hasta el primer inicio de sesión del propietario con email confirmado. Ni las altas ni la selección de planes envían mensajes, cobran tarjetas ni activan suscripciones. El apartado Pagos muestra **solo** operaciones verificados en `platform_billing_payments` (actualmente sin webhook de Stripe), separadas de las intenciones de compra. La gestión B2C y la facturación legal requieren integración posterior.

Para desarrollo local: `cd web/console && npm test` y `python3 -m http.server 8080`; el modo de demostración ha sido retirado de la consola.


Sitio HTML estático: producto, casos de uso, outdoor, recuperación, IA, precios, FAQ, privacidad y términos.
Cumple enlaces requeridos por App Store / paywall.

Última actualización: 2026-11-08

**App Store (oficial):** https://apps.apple.com/es/app/repera-tu-diario-de-entreno/id6824523509

## Páginas

| URL canónica | Archivo |
|--------------|---------|
| `https://repera.app/` | `index.html` |
| `https://repera.app/funcionalidades` | `funcionalidades.html` |
| `https://repera.app/casos` | `casos.html` |
| `https://repera.app/casos/{slug}` | `casos/{slug}.html` (generado) |
| `https://repera.app/outdoor` | `outdoor.html` |
| `https://repera.app/recuperacion` | `recuperacion.html` |
| `https://repera.app/ia` | `ia.html` |
| `https://repera.app/precios` | `precios.html` |
| `https://repera.app/soporte` | `soporte.html` |
| `https://repera.app/privacy` | `privacy.html` |
| `https://repera.app/privacy-en` | `privacy-en.html` |
| `https://repera.app/terms` | `terms.html` |
| `https://repera.app/faq` | `faq.html` |

No hay `/ejercicios` público. La app iOS enlaza privacidad y términos desde `CommercialConfig`.

## Build de contenido

```bash
cd web
python3 scripts/build_site.py          # casos/*.html + sitemap.xml + robots.txt
python3 scripts/write_product_pages.py  # home y páginas de producto (chrome compartido)
```

Datos: `content/site.json`, `content/casos.json`. Capturas: `assets/screens/` (sustituir placeholders).

## Vista local

**Recomendado (macOS):** doble clic en [`Repera-Web.command`](../Repera-Web.command) en la raíz del repo. Abre el navegador con un servidor local; las rutas `/css`, `/casos`, etc. funcionan (abrir `index.html` a pelo con `file://` **no** sirve por los paths absolutos).

```bash
# Alternativa manual
cd web
python3 -m http.server 8080
# Abrir http://localhost:8080
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
| [`.htaccess`](.htaccess) | `README.md`, `pack-ionos.sh`, `content/`, `scripts/` |
| HTML de producto + `casos/` | `_redirects`, `_headers` (Netlify) |
| `css/`, `js/`, `assets/` (incl. `screens/`) | `.DS_Store` |
| `robots.txt`, `sitemap.xml` | |
| `console/`, `ai/` | |
| `LEEME-SUBIR.txt` (pasos en el zip) | |

### 2. Subir a IONOS

1. File Manager o FTP → raíz del dominio (`htdocs` / document root de `repera.app`).
2. Sube `repera-ionos.zip` y **extrae ahí** (sin carpeta intermedia): deben quedar `index.html` y `.htaccess` al mismo nivel.
3. Activa **archivos ocultos** y confirma que existe `.htaccess`.
4. Panel IONOS: **SSL** (Let's Encrypt) + **Forzar HTTPS**.
5. Borra el `.zip` del servidor si lo dejaste subido.
6. Comprueba:
   - `https://repera.app/`
   - `https://repera.app/funcionalidades`, `/casos`, `/outdoor`, `/recuperacion`
   - `https://repera.app/privacy`, `/terms`, `/faq`
   - CTA App Store en home

### Qué hace [`.htaccess`](.htaccess)

- Pretty URLs de producto, casos, legales
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
- [x] App Store URL oficial en CTAs (`id6824523509`)
- [ ] URL de soporte en App Store Connect → `https://repera.app/soporte` (email cuando se confirme)
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
- Analítica: opt-in GA4 (`G-954CPW717S`, proyecto Firebase `repera-mv`, misma propiedad que la app). Consent Mode denegado por defecto; gtag solo tras aceptar en el banner (`js/site.js`)
- Reabrir: enlace «Cookies» / «Preferencias de cookies» en footer
- Política: `privacy.html#cookies` (en producción: `/privacy#cookies`)

## Diseño

Tokens alineados a la app: fondo negro, acento `#30d158`, superficies `#1c1c1e`.
Sin frameworks. CSS en `css/site.css`, interacción en `js/site.js`.

Secciones home: hero, pilares, cómo funciona, para quién, funciones, Watch, confianza, planes, precios, CTA.

FX de casos: `mascot_fx` / `mascot_fx_markup` en `scripts/build_site.py` (ancla `%` al objeto del webp + capa `mascot-fx-layer--front|back`). Estilos en `css/site.css` (`.fx-focus`, `.fx-lead`, nieve, viento, etc.). Regenerar con `python3 web/scripts/build_site.py`.

FAQ / Privacidad (ES+EN) / Términos / Soporte: mismos `header_html` + `footer_html` que el resto. Contenido en `content/faq.json`, `content/privacy_body.html`, `content/privacy_body_en.html`, `content/terms_body.html`; se escriben con `python3 web/scripts/write_product_pages.py`. Verificación de afirmaciones IA/MCP: `docs/PRIVACY_POLICY_VERIFICATION_2026_11_08.md`.

## Pendiente editorial

- ID real de App Store / enlace de Google Play.
- Revisión legal profesional de `privacy.html` y `terms.html` antes de producción.
- Capturas oficiales de producto (hoy: mascota PNG transparente `mascot-hero.png` / `mascot-watch.png`; favicon = AppIcon).
- Proveedor de analítica (solo tras consentimiento) si se desea medición.


## Consentimiento de asistentes · 2026-10-24

Última actualización: 2026-10-24. `pack-ionos.sh` incluye `ai/` para `https://repera.app/ai/`. Usa login Apple/Google con la cuenta de Repera y consentimiento explícito, sin claves manuales. Requiere desplegar el backend y configurar OAuth antes de habilitar los botones; no está publicado automáticamente. Procedimiento: [OAUTH_CONNECTIONS.md](../docs/OAUTH_CONNECTIONS.md).

### Ajustes finales de invitaciones y centros

Los enlaces de email abren `/console/?invitation=<uuid>` y permiten crear una **cuenta de deportista** (correo y contraseña), verificarla y aceptar la invitación sin crear empresa. Los atletas vinculados no acceden al área fiscal, facturación ni consultas administrativas de centros; para entrenadores y recepción la consola pide fichas con campos básicos, sin descargar teléfono ni notas internas. El enlace de verificación conserva el identificador de invitación.

Búsqueda móvil: desde la migración `20261027160015_discoverable_center_excludes_suspended.sql`, un centro suspendido queda oculto aunque conserve `is_discoverable=true`; la consulta privilegiada reside en esquema privado y la RPC pública es `SECURITY INVOKER`. Verificar entrega de emails reales una vez configurado Resend.
