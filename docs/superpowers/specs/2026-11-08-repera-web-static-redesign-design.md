# Diseño — Rediseño estático de repera.app (look maqueta)

Última actualización: 2026-11-08.

## Resumen

Portar el look y el storytelling de la maqueta pública (`repera-maqueta`) a `web/` como **sitio HTML estático**, con generador ligero para casos de uso, SEO completo (meta, sitemap, JSON-LD) y CTA oficial de App Store. **No** se publica biblioteca de ejercicios. Outdoor y Recuperación se rediseñan (no se copian tal cual la maqueta). `/console/` y `/ai/` no cambian de comportamiento.

**Enfoque acordado:** B — generador estático (Python) + CSS/JS compartidos + `pack-ionos.sh`.

**App Store (oficial):**  
`https://apps.apple.com/es/app/repera-tu-diario-de-entreno/id6824523509`

## Objetivos

1. Sustituir el look actual de la landing por el sistema oscuro de la maqueta (negro + verde `#30D158`).
2. Publicar home + funcionalidades + casos de uso + outdoor + recuperación + IA + precios/soporte, con privacy/terms/faq.
3. SEO crawlable sin JS: HTML real por URL, sitemap, metadatos, datos estructurados.
4. CTA primario = descargar en App Store (eliminar todo copy «pendiente de aprobación»).
5. Slots de capturas estables para que el autor sustituya pantallazos sin rediseñar.

## Fuera de alcance

- Rutas `/ejercicios` y fichas públicas de ejercicios.
- SPA React / hash routing de la maqueta.
- Cambios de producto en `web/console/` o `web/ai/` (solo enlaces desde el sitio si ya existen).
- Publicar tipografías comerciales sin licencia clara (GT America, Season Mix, Aime, KMR Melange).
- Despliegue automático a IONOS (sigue siendo pack + subida humana).
- Definir el email de soporte concreto si aún no existe: la página `/soporte` debe dejar un placeholder marcado hasta confirmación humana; no inventar dirección.

## Arquitectura

```
web/
  content/
    site.json          # URLs App Store, precios orientativos, OG default, contacto
    casos.json         # lista de actividades (slug, nombre, grupo, resumen, bullets)
  templates/           # plantillas del generador: partials head/header/footer/cta + caso.html
  scripts/
    build_site.py      # genera casos/{slug}.html + sitemap.xml; valida site.json/casos.json
  css/site.css         # design system oscuro
  js/site.js           # nav, cookies (reutilizar/adaptar)
  assets/
    screens/           # capturas webp (placeholders + finales)
    og-default.webp    # 1200×630
    icon / mascot
  index.html, funcionalidades.html, casos.html, outdoor.html, ...
  casos/{slug}.html    # generados
  privacy.html, terms.html, faq.html
  robots.txt, sitemap.xml
  .htaccess            # pretty URLs ampliadas
  pack-ionos.sh        # incluye nuevas rutas y assets/screens
```

- **Runtime público:** solo estáticos. Sin React.
- **Páginas de producto** (`index`, funcionalidades, outdoor, recuperacion, ia, precios, soporte, faq, privacy, terms): HTML mantenido en repo, compartiendo `css/site.css`, `js/site.js` y snippets documentados (o includes del generador solo si se unifica en una segunda iteración). **v1:** HTML a mano + CSS/JS compartidos.
- **Build local:** `python3 web/scripts/build_site.py` genera **solo** `casos/{slug}.html` + `sitemap.xml` (y puede regenerar el índice `casos.html` desde JSON). Invocable desde `pack-ionos.sh`.
- **IONOS:** Apache + `.htaccess` (mismo modelo que hoy).

## Mapa de URLs

| Ruta canónica | Archivo | Notas |
|---------------|---------|--------|
| `/` | `index.html` | Home |
| `/funcionalidades` | `funcionalidades.html` | Sin sección ejercicios indexable |
| `/casos` | `casos.html` | Índice por grupos |
| `/casos/{slug}` | `casos/{slug}.html` | Generado desde `casos.json` |
| `/outdoor` | `outdoor.html` | Rediseño |
| `/recuperacion` | `recuperacion.html` | Rediseño |
| `/ia` | `ia.html` | Conecta tu IA |
| `/precios` | `precios.html` | Planes + comparativa |
| `/soporte` | `soporte.html` | Contacto + enlaces |
| `/faq` | `faq.html` | Existente, skin oscuro |
| `/privacy` | `privacy.html` | Existente, skin + App Store si aplica |
| `/terms` | `terms.html` | Existente, skin |
| `/console/` | (sin cambio funcional) | Enlace «Acceso profesional» en footer/nav |
| `/ai/` | (sin cambio funcional) | Enlazable desde `/ia` si procede |

**No crear:** `/ejercicios`.

### Pretty URLs (`.htaccess`)

Extender el patrón actual:

- `funcionalidades`, `casos`, `outdoor`, `recuperacion`, `ia`, `precios`, `soporte`
- `casos/([a-z0-9-]+)` → `casos/$1.html`
- 301 desde `*.html` a URL limpia donde ya exista el patrón para privacy/terms/faq

## Sistema visual

- Fondo `#000000`, superficies `#0e0e10` / `#1c1c1e`, texto primario blanco, secundario `#b7bbb9` / `#939a96`, acento `#30d158`.
- Tipografía v1: stack del sistema (`-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, sans-serif). No embeber fuentes de la maqueta sin licencia.
- Componentes: skip-link, header con nav + menú móvil, botones pill (primario verde / ghost), secciones con divisores, frames de teléfono para capturas, tiles de casos, banda CTA final.
- Motion: reveals opcionales respetando `prefers-reduced-motion: reduce`.
- Capturas: `web/assets/screens/{area}-{nn}.webp` con `width`/`height`/`alt`/`loading`; hero LCP con `fetchpriority="high"`.

## Contenido por página

### Home `/`

- Eyebrow: «Tu diario de entreno».
- H1: «Lo das todo.» + énfasis «Que quede.»
- Lede: primera serie → último kilómetro; un solo diario.
- CTA primario: Descargar en App Store (URL oficial). Secundario: Ver planes o Explorar funcionalidades.
- Eliminar cualquier «App Store pendiente» / «aún no se puede descargar».
- Bloques: pilares · registro/progreso/Watch con slots de captura · teaser casos · precios resumidos · CTA final.
- JSON-LD: `Organization` + `WebSite` + `SoftwareApplication` (con ofertas y enlace App Store).

### `/funcionalidades`

- Anclas: Registro, Progreso, Temporizador, Outdoor, Recuperación, Conecta tu IA, Watch (y similares existentes en producto).
- **No** bloquear ni indexar biblioteca de ejercicios; mención breve opcional «catálogo dentro de la app».
- Cada sección: H2 + copy + slot captura + link a página dedicada si existe (`/outdoor`, `/recuperacion`, `/ia`).

### `/casos` y `/casos/{slug}`

- Grupos alineados con el selector de la app (maqueta): A pie, Ciclismo, Fuerza y fitness, Deportes de raqueta, Deportes acuáticos, Deportes de invierno, Deportes de equipo, Combate, Cardio y gimnasio, Otros deportes.
- Datos en `content/casos.json`: `slug`, `name`, `group`, `summary`, `registers[]` (qué registra), `related` opcional (`outdoor`, otros slugs).
- Cada ficha: H1 = nombre actividad; párrafo de intención SEO; lista qué registra; CTA App Store; enlaces related.
- **Regla thin content:** no publicar slug sin `summary` + al menos 3 bullets reales; o marcar `index: false` hasta completar.
- BreadcrumbList en JSON-LD.

### `/outdoor` (mejorado vs maqueta)

- Posicionamiento: salidas en el **mismo diario** que el gym (no «Strava lite»).
- H1 propio orientado a beneficio + keywords naturales (GPS, ritmo, zonas de pulso, ruta) sin stuffing.
- Journey Antes / Durante / Después.
- Grid de capacidades según lo **publicado en App Store** (mapa/ruta, ritmo/desnivel, zonas, avisos por km, GPX si aplica). Sin disclaimers de «código de main» si la feature ya está en tienda; si algo no está publicado, disclaimer puntual y honesto.
- 2–3 slots de captura (`outdoor-01`…).
- Internlinking a casos outdoor + App Store.
- Opcional: FAQ corta con `FAQPage` si aporta.

### `/recuperacion` (mejorado vs maqueta)

- Framing: sueño y VFC de Apple Salud como **contexto** junto al diario; el usuario decide; no órdenes clínicas.
- Disclaimer médico corto y visible (una frase).
- Layout usable sin captura; listo para shots.
- Enlace a `/privacy` (permisos Salud).
- Evitar claims diagnósticos en copy y en schema.

### `/ia`

- Conecta tu propio asistente (MCP); leer historial; propuestas al Diario con revisión humana.
- Honestidad sobre permisos; sin afirmar coach integrado.
- CTA a App Store / Ajustes en app.

### `/precios`

- Gratis vs Pro + importes orientativos alineados con la web/ASC actuales (p. ej. 5,99 €/mes, 39,99 €/año) y disclaimer «precio final en tienda».
- Comparativa fila a fila; enlace a `/faq` y gestión de suscripción Apple.
- CTA App Store.
- `FAQPage` si se incrustan preguntas; o enlazar FAQ existente.

### `/soporte`

- Canal de contacto: solo el confirmado en `site.json`; si falta, texto «próximamente» sin email inventado.
- Enlaces: FAQ, privacy, terms, App Store, gestionar suscripción.

### Legales / FAQ

- Conservar sustancia legal de `privacy.html` / `terms.html` / `faq.html`.
- Aplicar skin oscuro y actualizar placeholders de App Store a la URL oficial.
- Mantener cookies/preferencias del sitio actual (adaptadas al CSS nuevo).

## SEO

### Metadatos

Cada página genera:

- `title`, `meta name="description"` únicos
- `link rel="canonical"` absoluto `https://repera.app{path}`
- Open Graph: title, description, url, type=website, locale=es_ES, image, image:alt
- Twitter: `summary_large_image`
- `theme-color` `#000000`
- `robots` index,follow (salvo `index: false` o console)

Fuente: `site.json` + campos por página/caso. El generador (y/o partial `head`) los escribe en HTML estático.

### Sitemap y robots

- `build_site.py` regenera `sitemap.xml` con todas las URLs indexables + `lastmod`.
- Prioridades orientativas: home 1.0 · producto 0.8 · casos 0.7 · soporte/faq 0.6 · legales 0.5.
- `robots.txt` declara `Sitemap: https://repera.app/sitemap.xml`.
- No incluir `/ejercicios`, ni consolas/auth internas.

### JSON-LD

- Home: grafo `Organization` + `WebSite` + `SoftwareApplication` (offers Gratis/Pro; `url` / enlace de descarga App Store).
- Páginas internas: `BreadcrumbList` cuando hay jerarquía (casos).
- FAQ: `FAQPage` en `/faq` y/o `/precios` si hay Q&A en página.
- Outdoor/Recuperación: `WebPage`; sin markup médico engañoso.

### Copy SEO

- Un H1 por página; H2/H3 coherentes.
- Internlinking entre home ↔ funcionalidades ↔ casos ↔ outdoor/recuperacion/ia ↔ precios ↔ App Store.
- Keywords naturales en español; sin relleno.
- `alt` descriptivos en capturas y marca (logo no vacío decorativo sin nombre accesible en el link de marca).

## App Store y promoción

- Constante única `appStoreUrl` en `site.json` usada por todos los CTA y por JSON-LD.
- CTA primario en home y bandas finales = Descargar / Abrir en App Store.
- Android: «Próximamente» sin enlace falso.
- Footer: Acceso profesional → `/console/`.

## Accesibilidad

- Skip link «Saltar al contenido».
- Landmarks: header, nav, main, footer.
- Menú móvil: `aria-expanded` / `aria-controls`.
- Contraste AA+ sobre negro (validar grises secundarios).
- `prefers-reduced-motion`.
- FAQ en `<details>` o equivalente accesible.

## Build y empaquetado

1. Editar `content/casos.json` / `site.json` / plantillas.
2. `python3 web/scripts/build_site.py`
3. `./pack-ionos.sh` debe incluir: nuevas HTML, `casos/`, `css/`, `js/`, `assets/screens/`, `og-default`, robots, sitemap, `.htaccess`, console, ai (como hoy).

## Documentación

Actualizar tras implementar:

- `web/README.md` (rutas, build, pack, App Store URL)
- `docs/FEATURES.md` (sección sitio web)
- Fecha «Última actualización» en docs tocados
- No inventar features no presentes en la app publicada

## Criterios de aceptación

1. `https://repera.app/` (local) muestra look oscuro, H1 acordado y CTA a la URL oficial de App Store.
2. No queda copy de «App Store pendiente de aprobación» en páginas del alcance.
3. `/casos` lista grupos; al menos un `/casos/{slug}` de ejemplo generado con meta + breadcrumb JSON-LD.
4. `/outdoor` y `/recuperacion` siguen el framing rediseñado (diario unificado / contexto no clínico).
5. No existe ruta pública de ejercicios en nav, footer ni sitemap.
6. `sitemap.xml` lista todas las URLs indexables del alcance; `robots.txt` apunta al sitemap.
7. Privacy y terms siguen resolviendo por pretty URL y enlazan desde footer.
8. `/console/` y `/ai/` siguen funcionando tras el pack.
9. Lighthouse/SEO básico: title/description/canonical presentes en home y una ficha de caso (comprobado en HTML fuente, no solo DOM JS).
10. Documentación `web/README.md` describe build + pack.

## Riesgos y decisiones abiertas (no bloquean el spec)

- **Email de soporte:** confirmar antes de publicar `/soporte` con `mailto:`.
- **Paridad feature App Store:** Outdoor/Recuperación/IA deben reflejar lo realmente publicado; el autor validará copy contra la build de tienda.
- **Capturas:** placeholders hasta entrega del autor; nombres de archivo fijos en spec de assets.
- **Volumen de casos:** importar lista desde maqueta/app; completar bullets SEO en oleadas si hace falta, respetando regla thin content.

## Referencias

- Maqueta: `/Users/ramon/Downloads/repera-maqueta`
- Sitio actual: `web/`
- Revisión 360 (hallazgos): canvas agente `repera-maqueta-review-360.canvas.tsx`
- `AGENTS.md` (docs, iOS 26+, no inventar features)
