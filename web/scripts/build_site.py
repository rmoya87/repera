#!/usr/bin/env python3
"""Generate casos HTML pages and sitemap.xml for repera.app static site."""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
OUT_CASOS = ROOT / "casos"
TODAY = date.today().isoformat()
APP_STORE = "https://apps.apple.com/es/app/repera-tu-diario-de-entreno/id6824523509"

MODE_CAPS = {
    "gps": ("cap-actividad.jpg", "Lugar y detalles de la sesión en el diario"),
    "fuerza": ("cap-emom.jpg", "Registro de series con kg, reps y RPE"),
    "wod": ("cap-amrap.jpg", "Resultado de WOD / AMRAP"),
    "indoor": ("cap-progreso-entreno.jpg", "Progreso de la semana"),
}

# SF Symbol–aligned short labels for chips (visual cue; mascot is primary art)
SPORT_ICON = {
    "carrera": "run",
    "carrera-montana": "run",
    "caminata": "walk",
    "senderismo": "hike",
    "ciclismo-carretera": "bike",
    "ciclismo-montana": "bike",
    "gravel": "bike",
    "entrenamiento": "strength",
    "crossfit": "cross",
    "hiit": "timer",
    "hyrox": "cross",
    "fuerza-funcional": "strength",
    "core": "core",
    "tenis": "racket",
    "padel": "racket",
    "badminton": "racket",
    "pickleball": "racket",
    "squash": "racket",
    "natacion": "swim",
    "surf": "surf",
    "windsurf": "sail",
    "kitesurf": "surf",
    "kayak": "row",
    "remo": "row",
    "piragua": "row",
    "vela": "sail",
    "esqui-alpino": "ski",
    "snowboard": "snow",
    "esqui-fondo": "ski",
    "patinaje-hielo": "skate",
    "futbol": "ball",
    "baloncesto": "ball",
    "voleibol": "ball",
    "futbol-americano": "ball",
    "beisbol": "ball",
    "hockey": "ball",
    "lacrosse": "ball",
    "rugby": "ball",
    "boxeo": "fight",
    "kickboxing": "fight",
    "artes-marciales": "fight",
    "lucha": "fight",
    "escalada": "climb",
    "baile": "dance",
    "pilates": "flex",
    "yoga": "flex",
    "movilidad": "flex",
    "skateboard": "skate",
    "golf": "golf",
    "otra-actividad": "other",
}


def load_json(name: str):
    return json.loads((CONTENT / name).read_text(encoding="utf-8"))


def esc(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def icon_svg(kind: str, size: int = 20) -> str:
    """Minimal inline icons inspired by app sport symbols (not Apple trademarked artwork)."""
    paths = {
        "run": '<circle cx="12" cy="5" r="2"/><path d="M8 21l2-6 2 2 3 4M10 15l-2 2H5l3-7 4-1 2 3"/>',
        "walk": '<circle cx="12" cy="5" r="2"/><path d="M9 21l2-7 2 2 2 5M11 14l-3 1-1-5 4-2 2 3"/>',
        "hike": '<circle cx="12" cy="5" r="2"/><path d="M8 21l3-8 2 2 3 6M11 13l-4 7M14 13l3 3"/>',
        "bike": '<circle cx="6" cy="16" r="3"/><circle cx="18" cy="16" r="3"/><path d="M6 16l4-8h4l4 8M10 8l2 4"/>',
        "strength": '<path d="M6 10h12v4H6zM4 11v2M20 11v2M8 8v8M16 8v8"/>',
        "cross": '<path d="M12 3v18M6 9h12M8 15h8"/>',
        "timer": '<circle cx="12" cy="13" r="7"/><path d="M12 13V9M9 3h6"/>',
        "racket": '<circle cx="10" cy="10" r="5"/><path d="M14 14l6 6"/>',
        "swim": '<path d="M3 16c2-2 4-2 6 0s4 2 6 0 4-2 6 0M4 10c1.5-3 4-5 8-5s6.5 2 8 5"/>',
        "surf": '<path d="M4 16c4-6 12-6 16 0M8 16l4-8 4 8"/>',
        "sail": '<path d="M12 3v16M12 4c4 2 6 6 6 10H12M6 20h12"/>',
        "row": '<path d="M4 14h16M6 14l2-4h8l2 4M8 18h8"/>',
        "ski": '<path d="M6 20l10-14M10 20l8-10M8 8l2 2"/>',
        "snow": '<path d="M12 3v18M5 7l14 10M19 7L5 17"/>',
        "skate": '<circle cx="8" cy="18" r="2"/><circle cx="16" cy="18" r="2"/><path d="M5 14h14l-2-6H7z"/>',
        "ball": '<circle cx="12" cy="12" r="8"/><path d="M12 4v16M4 12h16"/>',
        "fight": '<path d="M8 10h3l2 2h5v3H8zM7 8l-2 2v5l2 2"/>',
        "climb": '<path d="M8 20l2-6 3 2 3-8M12 4l2 3"/>',
        "dance": '<circle cx="12" cy="5" r="2"/><path d="M9 21l3-8 3 8M9 12h6"/>',
        "flex": '<circle cx="12" cy="5" r="2"/><path d="M8 20c0-4 2-6 4-6s4 2 4 6M8 12h8"/>',
        "golf": '<circle cx="12" cy="5" r="2"/><path d="M10 21l2-10 6 3M12 11v10"/>',
        "core": '<circle cx="12" cy="12" r="7"/><path d="M12 8v8M9 12h6"/>',
        "route": '<path d="M4 18c3-8 6-8 8-2s5 6 8 0"/><circle cx="4" cy="18" r="1.5"/><circle cx="20" cy="16" r="1.5"/>',
        "heart": '<path d="M12 20s-7-4.5-7-10a4 4 0 017-2 4 4 0 017 2c0 5.5-7 10-7 10z"/>',
        "speak": '<path d="M4 10v4h3l4 3V7L7 10H4zM16 9a4 4 0 010 6M18.5 7a7 7 0 010 10"/>',
        "nav": '<path d="M12 3l7 18-7-3-7 3 7-18z"/>',
        "map": '<path d="M9 4l6 2 5-2v16l-5 2-6-2-5 2V6l5-2zM9 4v16M15 6v16"/>',
        "trophy": '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 01-10 0V4zM7 5H4a3 3 0 003 5M17 5h3a3 3 0 01-3 5"/>',
        "list": '<path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/>',
        "chart": '<path d="M4 19h16M7 16V9M12 16V5M17 16v-6"/>',
        "scan": '<path d="M4 8V4h4M16 4h4v4M20 16v4h-4M8 20H4v-4M8 12h8"/>',
        "import": '<path d="M12 3v12M8 11l4 4 4-4M5 19h14"/>',
        "watch": '<rect x="7" y="3" width="10" height="18" rx="3"/><path d="M12 8v4l2 1"/>',
        "wod": '<path d="M5 19h14M7 19l2-10h6l2 10M10 9V5h4v4"/>',
        "energy": '<path d="M13 2L4 14h7l-1 8 10-14h-7l1-6z"/>',
        "streak": '<path d="M12 3c2 4 6 5 6 10a6 6 0 11-12 0c0-3 2-5 4-7"/>',
        "muscle": '<path d="M5 14c0-3 2-5 4-5 1 0 2 .5 3 1.5S14 9 15 9c2 0 4 2 4 5v5H5v-5z"/>',
        "book": '<path d="M4 5a3 3 0 013-2h11v16H7a3 3 0 00-3 3V5z"/>',
        "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 118 0v3"/>',
        "other": '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/>',
    }
    d = paths.get(kind, paths["other"])
    return (
        f'<svg class="sport-icon" viewBox="0 0 24 24" width="{size}" height="{size}" '
        f'aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" '
        f'stroke-linecap="round" stroke-linejoin="round">{d}</svg>'
    )


def icon_for_text(text: str) -> str:
    t = text.lower()
    rules = [
        (("gps", "ruta", "distancia", "mapa", "recorrido"), "route"),
        (("pulso", "zona", "fc", "cardi"), "heart"),
        (("aviso", "voz", "hablad"), "speak"),
        (("gpx", "giro", "guía", "guia"), "nav"),
        (("clima", "condicion", "marea"), "map"),
        (("récord", "record", "marca", "mejor"), "trophy"),
        (("rutina", "programa", "plan"), "list"),
        (("serie", "kg", "rir", "rpe", "peso", "rep"), "strength"),
        (("evolu", "gráfica", "grafica", "progreso"), "chart"),
        (("pizarra", "escane"), "scan"),
        (("csv", "import"), "import"),
        (("watch", "reloj"), "watch"),
        (("emom", "amrap", "wod", "interval"), "timer"),
        (("caloría", "caloria", "energ"), "energy"),
        (("racha", "semana"), "streak"),
        (("múscul", "muscul", "equilibrio"), "muscle"),
        (("catálogo", "catalogo", "ejercicio"), "book"),
        (("local", "permiso", "privac", "nadie"), "lock"),
        (("sueño", "sueno", "vfc", "hrv"), "heart"),
    ]
    for keys, icon in rules:
        if any(k in t for k in keys):
            return icon
    return "other"


def casos_mega_html(data: dict) -> str:
    groups = data["groups_order"]
    by_group: dict[str, list] = {g: [] for g in groups}
    for c in data["casos"]:
        if c.get("index", True):
            by_group.setdefault(c["group"], []).append(c)
    cols = []
    for g in groups:
        items = by_group.get(g) or []
        if not items:
            continue
        links = "\n".join(
            f'              <a href="/casos/{esc(c["slug"])}">{icon_svg(SPORT_ICON.get(c["slug"], "other"))}'
            f'<span>{esc(c["name"])}</span></a>'
            for c in items
        )
        cols.append(
            f'            <div class="sub-col">\n'
            f'              <p>{esc(g)}</p>\n{links}\n            </div>'
        )
    return "\n".join(cols)


def nav_html(active: str, data: dict | None = None) -> str:
    items = [
        ("/", "Inicio", "home"),
        ("/funcionalidades", "Funcionalidades", "funcionalidades"),
        ("/casos", "Casos de uso", "casos"),
        ("/outdoor", "Outdoor", "outdoor"),
        ("/recuperacion", "Recuperación", "recuperacion"),
        ("/ia", "Conecta tu IA", "ia"),
        ("/precios", "Precios", "precios"),
    ]
    links = []
    for href, label, key in items:
        cur = ' aria-current="page"' if active == key else ""
        if key == "casos" and data is not None:
            links.append(
                f'''<li class="has-sub">
            <div class="nav-sub-trigger">
              <a href="{href}"{cur}>{esc(label)}</a>
              <button type="button" class="sub-toggle" data-sub-toggle aria-expanded="false" aria-controls="casos-sub" aria-label="Menú de actividades">▾</button>
            </div>
            <div class="nav-sub" id="casos-sub" data-sub-panel hidden>
              <div class="sub-head">
                <p class="eyebrow">Casos de uso por actividad</p>
                <a class="sub-all" href="/casos">Ver la página general →</a>
              </div>
              <div class="sub-in">
{casos_mega_html(data)}
              </div>
            </div>
          </li>'''
            )
        else:
            links.append(f'<li><a href="{href}"{cur}>{esc(label)}</a></li>')
    return "\n          ".join(links)


def mobile_casos_html(data: dict) -> str:
    groups = data["groups_order"]
    by_group: dict[str, list] = {g: [] for g in groups}
    for c in data["casos"]:
        if c.get("index", True):
            by_group.setdefault(c["group"], []).append(c)
    blocks = [
        '<a href="/casos" class="msub-all">Página general de casos de uso</a>'
    ]
    for g in groups:
        items = by_group.get(g) or []
        if not items:
            continue
        links = "".join(
            f'<a href="/casos/{esc(c["slug"])}">{esc(c["name"])}</a>' for c in items
        )
        blocks.append(f'<div class="msub-g"><p>{esc(g)}</p>{links}</div>')
    return "\n          ".join(blocks)


def header_html(active: str = "", data: dict | None = None) -> str:
    if data is None:
        data = load_json("casos.json")
    return f"""  <a class="skip-link" href="#contenido">Saltar al contenido</a>
  <header class="site-header">
    <div class="wrap nav">
      <a class="brand" href="/" aria-label="Repera inicio">
        <img src="/assets/icon.png" width="28" height="28" alt="">
        repera
      </a>
      <nav aria-label="Principal">
        <ul class="nav-links">
          {nav_html(active, data)}
          <li><a class="btn btn-primary btn-nav" href="{APP_STORE}" rel="noopener noreferrer">App Store</a></li>
        </ul>
      </nav>
      <button class="nav-toggle" type="button" data-nav-toggle aria-expanded="false" aria-controls="menu-movil" aria-label="Abrir menú">☰</button>
    </div>
    <div class="wrap nav-drawer" id="menu-movil" data-nav-drawer>
      <ul>
        <li><a href="/"{" aria-current=\"page\"" if active=="home" else ""}>Inicio</a></li>
        <li><a href="/funcionalidades">Funcionalidades</a></li>
        <li class="drawer-casos">
          <div class="mrow">
            <a href="/casos">Casos de uso</a>
            <button type="button" class="msub-t" data-msub-toggle aria-expanded="false" aria-label="Actividades de casos de uso">+</button>
          </div>
          <div class="msub" data-msub hidden>
            {mobile_casos_html(data)}
          </div>
        </li>
        <li><a href="/outdoor">Outdoor</a></li>
        <li><a href="/recuperacion">Recuperación</a></li>
        <li><a href="/ia">Conecta tu IA</a></li>
        <li><a href="/precios">Precios</a></li>
        <li><a href="/soporte">Soporte</a></li>
        <li><a href="/faq">FAQ</a></li>
        <li><a href="{APP_STORE}" rel="noopener noreferrer">Descargar en App Store</a></li>
      </ul>
    </div>
  </header>"""


def footer_html() -> str:
    return f"""  <footer class="site-footer">
    <div class="wrap footer-grid">
      <div>
        <a class="brand" href="/">
          <img src="/assets/icon.png" width="28" height="28" alt="">
          repera
        </a>
        <p class="muted footer-tag">Diario de entrenamiento local-first para iPhone y Apple Watch. Android en camino.</p>
      </div>
      <div>
        <h3>Producto</h3>
        <ul>
          <li><a href="/funcionalidades">Funcionalidades</a></li>
          <li><a href="/casos">Casos de uso</a></li>
          <li><a href="/outdoor">Outdoor</a></li>
          <li><a href="/recuperacion">Recuperación</a></li>
          <li><a href="/ia">Conecta tu IA</a></li>
          <li><a href="/precios">Precios</a></li>
          <li><a href="/console/">Acceso profesional</a></li>
        </ul>
      </div>
      <div>
        <h3>Legal y cuenta</h3>
        <ul>
          <li><a href="/privacy">Privacidad</a></li>
          <li><a href="/terms">Términos de uso</a></li>
          <li><a href="/faq">FAQ</a></li>
          <li><a href="/soporte">Soporte</a></li>
          <li><a href="#" data-cookie-open>Preferencias de cookies</a></li>
          <li><a href="https://apps.apple.com/account/subscriptions" rel="noopener noreferrer">Gestionar suscripción (Apple)</a></li>
        </ul>
      </div>
    </div>
    <div class="wrap footer-copy">
      <p>© <span id="y"></span> Repera. Apple, App Store y Apple Watch son marcas de Apple Inc.</p>
    </div>
  </footer>
  <div class="cookie-banner" data-cookie-banner role="dialog" aria-labelledby="cookie-title" aria-live="polite" hidden>
    <div class="cookie-inner">
      <p id="cookie-title"><strong>Cookies y privacidad.</strong> Usamos almacenamiento local esencial para recordar tu elección. La analítica opcional solo se activa si la aceptas. <a href="/privacy#cookies">Más información</a>.</p>
      <div class="cookie-actions">
        <button type="button" class="btn btn-ghost" data-cookie-reject>Solo esenciales</button>
        <button type="button" class="btn btn-ghost" data-cookie-customize>Configurar</button>
        <button type="button" class="btn btn-primary" data-cookie-accept>Aceptar</button>
      </div>
    </div>
  </div>
  <div class="cookie-panel" data-cookie-panel role="dialog" aria-labelledby="cookie-panel-title" hidden>
    <h2 id="cookie-panel-title">Preferencias</h2>
    <p class="muted" style="margin:0;font-size:0.9rem">Elige qué categorías permitir. Las esenciales no se pueden desactivar.</p>
    <fieldset>
      <div class="cookie-option">
        <label for="cookie-necessary">Esenciales</label>
        <input id="cookie-necessary" type="checkbox" checked disabled>
        <p>Necesarias para el sitio y para guardar esta preferencia.</p>
      </div>
      <div class="cookie-option">
        <label for="cookie-analytics">Analítica</label>
        <input id="cookie-analytics" name="analytics" type="checkbox">
        <p>Ayuda a mejorar el sitio. Desactivada por defecto.</p>
      </div>
    </fieldset>
    <div class="cookie-actions">
      <button type="button" class="btn btn-ghost" data-cookie-close>Cerrar</button>
      <button type="button" class="btn btn-primary" data-cookie-save>Guardar</button>
    </div>
  </div>
  <script src="/js/site.js" defer></script>"""


def head_html(*, title: str, description: str, canonical: str, og_image: str, json_ld=None) -> str:
    ld = ""
    if json_ld is not None:
        ld = (
            '\n  <script type="application/ld+json">\n'
            + json.dumps(json_ld, ensure_ascii=False, indent=2)
            + "\n  </script>"
        )
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>{esc(title)}</title>
  <meta name="description" content="{esc(description)}">
  <meta name="robots" content="index, follow">
  <meta name="theme-color" content="#000000">
  <meta name="color-scheme" content="dark">
  <link rel="canonical" href="{esc(canonical)}">
  <link rel="icon" href="/assets/favicon-32.png?v=20261108" type="image/png" sizes="32x32">
  <link rel="icon" href="/assets/icon.png?v=20261108" type="image/png" sizes="180x180">
  <link rel="apple-touch-icon" href="/assets/icon.png?v=20261108">
  <meta property="og:locale" content="es_ES">
  <meta property="og:site_name" content="Repera">
  <meta property="og:title" content="{esc(title)}">
  <meta property="og:description" content="{esc(description)}">
  <meta property="og:url" content="{esc(canonical)}">
  <meta property="og:type" content="website">
  <meta property="og:image" content="{esc(og_image)}">
  <meta property="og:image:alt" content="Repera — diario de entrenamiento">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{esc(title)}">
  <meta name="twitter:description" content="{esc(description)}">
  <meta name="twitter:image" content="{esc(og_image)}">
  <link rel="stylesheet" href="/css/site.css">{ld}
</head>
<body>
"""


def cta_band(title: str, lede: str, *, light: bool = False) -> str:
    klass = "cta-band cta-band--light" if light else "cta-band"
    return f"""    <section class="{klass}" aria-labelledby="cta-title">
      <div class="wrap" data-reveal>
        <h2 id="cta-title">{esc(title)}</h2>
        <p class="lede">{esc(lede)}</p>
        <div class="btn-row">
          <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer">Descargar en App Store</a>
          <span class="btn btn-disabled" aria-disabled="true">Google Play · Próximamente</span>
        </div>
      </div>
    </section>"""


def mascot_theme(caso: dict) -> str:
    """Color / hero wash theme by sport group."""
    group = (caso.get("group") or "").lower()
    mode = (caso.get("mode") or "indoor").lower()
    mapping = {
        "a pie": "run",
        "ciclismo": "bike",
        "fuerza y fitness": "strength",
        "deportes de raqueta": "racket",
        "deportes acuáticos": "water",
        "deportes acuaticos": "water",
        "deportes de invierno": "winter",
        "deportes de equipo": "team",
        "combate": "fight",
        "cardio y gimnasio": "cardio",
        "otros deportes": "other",
    }
    if group in mapping:
        return mapping[group]
    by_mode = {"gps": "run", "fuerza": "strength", "wod": "wod", "indoor": "other"}
    return by_mode.get(mode, "other")


def mascot_fx(caso: dict) -> tuple[str, str, str, str]:
    """(fx, x%, y%, layer) — layer is 'front' or 'back'. Anchors match the mascot art."""
    slug = (caso.get("slug") or "").lower()
    by_slug = {
        # A pie
        "carrera": ("speed", "18", "62", "back"),
        "carrera-montana": ("trail", "22", "70", "back"),
        "caminata": ("path", "50", "82", "back"),
        "senderismo": ("trail", "28", "74", "back"),
        # Ciclismo
        "ciclismo-carretera": ("stripes", "50", "55", "back"),
        "ciclismo-montana": ("mtb", "50", "58", "back"),
        "gravel": ("gravel", "50", "60", "back"),
        # Fuerza / WOD
        "entrenamiento": ("plates", "50", "50", "back"),
        "crossfit": ("kettle", "50", "72", "back"),
        "hiit": ("chrono", "80", "42", "front"),
        "hyrox": ("sled", "46", "70", "back"),
        # Raqueta — anclado a la pelota/pluma real
        "tenis": ("ball-hit", "8", "42", "front"),
        "padel": ("ball-hit", "90", "55", "front"),
        "badminton": ("ball-hit", "78", "16", "back"),
        "pickleball": ("ball-hold", "90", "51", "front"),
        "squash": ("ball-hit", "84", "82", "front"),
        # Agua
        "natacion": ("swim-wake", "24", "44", "front"),
        "surf": ("board-wake", "38", "74", "front"),
        "windsurf": ("wind-strong", "58", "32", "front"),
        "kitesurf": ("kite", "80", "12", "front"),
        "kayak": ("hull-wake", "50", "84", "back"),
        "remo": ("oar-stroke", "50", "55", "back"),
        "piragua": ("paddle-splash", "76", "84", "front"),
        "vela": ("sail-wind", "62", "28", "front"),
        # Invierno
        "esqui-alpino": ("snow-front", "50", "68", "front"),
        "snowboard": ("snow-front", "52", "62", "front"),
        "esqui-fondo": ("snow-depth", "50", "78", "front"),
        "patinaje-hielo": ("skate-glide", "50", "90", "back"),
        # Equipo
        "futbol": ("ball-hit", "16", "58", "back"),
        "baloncesto": ("ball-dribble", "26", "67", "back"),
        "voleibol": ("ball-hit", "77", "13", "back"),
        "futbol-americano": ("ball-hit", "20", "60", "back"),
        "beisbol": ("ball-pitch", "86", "52", "front"),
        "hockey": ("puck-stick", "40", "84", "front"),
        "lacrosse": ("cradle", "20", "20", "front"),
        "rugby": ("ball-hit", "18", "58", "back"),
        # Combate
        "boxeo": ("gloves", "50", "54", "front"),
        "kickboxing": ("kick-foot", "15", "51", "back"),
        "artes-marciales": ("strike", "82", "51", "front"),
        "lucha": ("stance", "50", "82", "back"),
        # Cardio / otros
        "fuerza-funcional": ("plates", "50", "52", "back"),
        "core": ("pulse", "50", "55", "back"),
        "golf": ("ball-hit", "76", "87", "front"),
        "escalada": ("holds", "58", "38", "back"),
        "baile": ("beats-strong", "50", "42", "front"),
        "pilates": ("stretch", "74", "38", "back"),
        "skateboard": ("grind", "50", "80", "back"),
        "yoga": ("flow", "50", "48", "back"),
        "movilidad": ("roller", "64", "74", "back"),
        "otra-actividad": ("spark", "50", "50", "back"),
    }
    if slug in by_slug:
        return by_slug[slug]
    return ("spark", "50", "50", "back")


def mascot_fx_markup(fx: str, x: str, y: str) -> str:
    """Decorations only — never a second ball/shuttle. Focus sits on the art object."""
    style = f"--fx-x:{x}%;--fx-y:{y}%;"
    common = f'class="mascot-fx mascot-fx--{fx}" style="{style}" aria-hidden="true"'
    xi, yi = float(x), float(y)

    if fx == "ball-hit":
        # Trail ends ON the real ball/shuttle in the art.
        sx = 18 if xi >= 50 else 82
        sy = 78 if yi < 55 else 28
        d = (
            f"M{sx:.0f} {sy:.0f} C {(sx + xi) / 2:.0f} {(sy + yi) / 2 - 24:.0f}, "
            f"{(sx + xi) / 2:.0f} {(sy + yi) / 2 + 16:.0f}, {xi:.0f} {yi:.0f}"
        )
        return f"""<div {common}>
          <svg class="fx-lead" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path class="fx-lead-path" d="{d}" pathLength="100"/>
          </svg>
          <span class="fx-focus fx-focus--ball"></span>
          <span class="fx-focus fx-focus--soft"></span>
        </div>"""

    if fx == "ball-hold":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--ball"></span>
          <span class="fx-focus fx-focus--soft"></span>
        </div>"""

    if fx == "ball-pitch":
        # Line travels front→back: starts near the ball (viewer side) toward the bat.
        d = (
            f"M{min(xi + 6, 96):.0f} {yi + 2:.0f} "
            f"C {xi - 8:.0f} {yi - 18:.0f}, {xi - 26:.0f} {yi + 10:.0f}, "
            f"{max(xi - 42, 12):.0f} {yi - 2:.0f}"
        )
        return f"""<div {common}>
          <svg class="fx-lead" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path class="fx-lead-path fx-lead-path--rev" d="{d}" pathLength="100"/>
          </svg>
          <span class="fx-focus fx-focus--ball"></span>
        </div>"""

    if fx == "ball-dribble":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--ball fx-focus--bounce"></span>
          <span class="fx-dribble"></span><span class="fx-dribble"></span>
        </div>"""

    if fx == "puck-stick":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--puck"></span>
          <span class="fx-stick-line"></span><span class="fx-stick-line"></span><span class="fx-stick-line"></span>
        </div>"""

    if fx == "cradle":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--ball"></span>
          <span class="fx-cradle"></span>
        </div>"""

    if fx == "kettle":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--iron"></span>
          <span class="fx-focus fx-focus--soft fx-focus--iron"></span>
          <span class="fx-weight-tick"></span><span class="fx-weight-tick"></span>
          <span class="fx-weight-tick"></span><span class="fx-weight-tick"></span>
        </div>"""

    if fx == "sled":
        return f"""<div {common}>
          <span class="fx-push"></span><span class="fx-push"></span><span class="fx-push"></span><span class="fx-push"></span>
          <span class="fx-focus fx-focus--iron"></span>
        </div>"""

    if fx == "chrono":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--chrono"></span>
          <span class="fx-tick"></span><span class="fx-tick"></span><span class="fx-tick"></span>
          <span class="fx-tick"></span><span class="fx-tick"></span><span class="fx-tick"></span>
        </div>"""

    if fx == "gloves":
        # Soft glow on both boxing gloves — no punch rays.
        return f"""<div {common}>
          <span class="fx-glove" style="--gx:30%;--gy:50%;"></span>
          <span class="fx-glove" style="--gx:71%;--gy:59%;"></span>
          <span class="fx-glove fx-glove--soft" style="--gx:30%;--gy:50%;"></span>
          <span class="fx-glove fx-glove--soft" style="--gx:71%;--gy:59%;"></span>
        </div>"""

    if fx == "kick-foot":
        return f"""<div {common}>
          <svg class="fx-lead" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path class="fx-lead-path" d="M52 72 C 38 64, 24 56, 15 51" pathLength="100"/>
          </svg>
          <span class="fx-focus fx-focus--tiny fx-focus--kick"></span>
        </div>"""

    if fx == "strike":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--tiny fx-focus--strike"></span>
          <span class="fx-focus fx-focus--soft fx-focus--strike"></span>
        </div>"""

    if fx == "stance":
        return f"""<div {common}>
          <span class="fx-stance"></span>
          <span class="fx-stance fx-stance--2"></span>
          <span class="fx-dust fx-dust--fight"></span>
          <span class="fx-dust fx-dust--fight"></span>
          <span class="fx-dust fx-dust--fight"></span>
        </div>"""

    if fx == "oar-stroke":
        return f"""<div {common}>
          <svg class="fx-lead" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path class="fx-lead-path" d="M48 52 C 38 50, 30 49, 24 49" pathLength="100"/>
            <path class="fx-lead-path" d="M55 58 C 62 64, 68 70, 74 76" pathLength="100"/>
          </svg>
          <span class="fx-oar-tip" style="--ox:26%;--oy:49%;"></span>
          <span class="fx-oar-tip" style="--ox:74%;--oy:76%;"></span>
        </div>"""

    if fx == "swim-wake":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--water"></span>
          <i class="fx-bubble"></i><i class="fx-bubble"></i><i class="fx-bubble"></i>
          <i class="fx-bubble"></i><i class="fx-bubble"></i><i class="fx-bubble"></i>
          <span class="fx-wake-line"></span><span class="fx-wake-line"></span>
        </div>"""

    if fx == "board-wake":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--water fx-focus--wide"></span>
          <span class="fx-wake-line"></span><span class="fx-wake-line"></span><span class="fx-wake-line"></span>
          <i class="fx-drop"></i><i class="fx-drop"></i><i class="fx-drop"></i><i class="fx-drop"></i>
        </div>"""

    if fx == "hull-wake":
        return f"""<div {common}>
          <span class="fx-wake-band"></span>
          <span class="fx-ring"></span><span class="fx-ring fx-ring--2"></span>
          <span class="fx-focus fx-focus--water fx-focus--tiny"></span>
          <i class="fx-drop"></i><i class="fx-drop"></i>
        </div>"""

    if fx == "paddle-splash":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--water"></span>
          <i class="fx-drop"></i><i class="fx-drop"></i><i class="fx-drop"></i><i class="fx-drop"></i>
          <span class="fx-ring"></span>
        </div>"""

    if fx == "sail-wind":
        return f"""<div {common}>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
        </div>"""

    if fx == "wind-strong":
        return f"""<div {common}>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-wind fx-wind--strong"></span>
          <span class="fx-focus fx-focus--soft"></span>
        </div>"""

    if fx == "kite":
        return f"""<div {common}>
          <svg class="fx-kite-line" viewBox="0 0 100 100" preserveAspectRatio="none"><path d="M35 70 C 50 45, 62 28, 82 16" stroke="#5ac8fa" stroke-width="1.8" stroke-dasharray="3 6" fill="none"/></svg>
          <span class="fx-focus"></span>
          <span class="fx-wind fx-wind--strong"></span><span class="fx-wind fx-wind--strong"></span>
        </div>"""

    if fx == "snow-front":
        return f"""<div {common}>
          <i class="fx-flake fx-flake--big"></i><i class="fx-flake fx-flake--big"></i>
          <i class="fx-flake fx-flake--big"></i><i class="fx-flake fx-flake--big"></i>
          <i class="fx-flake fx-flake--big"></i><i class="fx-flake fx-flake--big"></i>
          <i class="fx-flake fx-flake--big"></i><i class="fx-flake fx-flake--big"></i>
          <span class="fx-snow-spray"></span>
        </div>"""

    if fx == "snow-depth":
        return f"""<div {common}>
          <i class="fx-flake fx-flake--depth"></i><i class="fx-flake fx-flake--depth"></i>
          <i class="fx-flake fx-flake--depth"></i><i class="fx-flake fx-flake--depth"></i>
          <i class="fx-flake fx-flake--depth"></i><i class="fx-flake fx-flake--depth"></i>
          <i class="fx-flake fx-flake--depth"></i><i class="fx-flake fx-flake--depth"></i>
          <span class="fx-ski-line"></span><span class="fx-ski-line fx-ski-line--par"></span>
        </div>"""

    if fx == "skate-glide":
        return f"""<div {common}>
          <span class="fx-glide"></span><span class="fx-glide"></span>
          <span class="fx-glint"></span>
          <span class="fx-focus fx-focus--ice fx-focus--tiny"></span>
        </div>"""

    if fx == "beats-strong":
        return f"""<div {common}>
          <span class="fx-beat fx-beat--loud"></span><span class="fx-beat fx-beat--loud"></span>
          <span class="fx-beat fx-beat--loud"></span><span class="fx-beat fx-beat--loud"></span>
          <span class="fx-beat fx-beat--loud"></span><span class="fx-beat fx-beat--loud"></span>
          <span class="fx-beat fx-beat--loud"></span>
        </div>"""

    if fx == "stretch":
        return f"""<div {common}>
          <svg class="fx-lead" viewBox="0 0 100 100" preserveAspectRatio="none">
            <path class="fx-lead-path" d="M48 62 C 58 48, 68 36, 78 28" pathLength="100"/>
          </svg>
          <span class="fx-focus fx-focus--soft"></span>
        </div>"""

    if fx == "roller":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--iron"></span>
          <span class="fx-roll"></span>
        </div>"""

    if fx == "speed":
        return f"""<div {common}>
          <span class="fx-speed"></span><span class="fx-speed"></span><span class="fx-speed"></span>
          <span class="fx-speed"></span><span class="fx-speed"></span>
        </div>"""
    if fx == "stripes":
        return f"""<div {common}>
          <span class="fx-stripe"></span><span class="fx-stripe"></span><span class="fx-stripe"></span><span class="fx-stripe"></span>
        </div>"""
    if fx == "mtb":
        return f"""<div {common}>
          <span class="fx-stripe fx-stripe--dirt"></span><span class="fx-stripe fx-stripe--dirt"></span>
          <span class="fx-stripe fx-stripe--dirt"></span>
          <span class="fx-dust"></span><span class="fx-dust"></span>
        </div>"""
    if fx == "gravel":
        return f"""<div {common}>
          <span class="fx-stripe"></span><span class="fx-stripe"></span>
          <i class="fx-dot"></i><i class="fx-dot"></i><i class="fx-dot"></i>
        </div>"""
    if fx == "trail":
        return f"""<div {common}>
          <svg class="fx-trail" viewBox="0 0 200 160" fill="none"><path d="M10 130 L55 90 L90 110 L140 50 L190 70" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-dasharray="6 8"/></svg>
        </div>"""
    if fx == "path":
        return f"""<div {common}>
          <svg class="fx-path" viewBox="0 0 200 40" fill="none"><path d="M8 28 C 50 8, 90 32, 130 16 S 180 22, 192 12" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-dasharray="2 7"/></svg>
        </div>"""
    if fx == "plates":
        return f"""<div {common}>
          <span class="fx-plate"></span><span class="fx-plate fx-plate--mid"></span><span class="fx-plate fx-plate--sm"></span>
        </div>"""
    if fx == "pulse":
        return f"""<div {common}>
          <span class="fx-focus"></span><span class="fx-focus fx-focus--soft"></span>
        </div>"""
    if fx == "holds":
        return f"""<div {common}>
          <i class="fx-hold"></i><i class="fx-hold"></i><i class="fx-hold"></i>
          <i class="fx-hold"></i><i class="fx-hold"></i>
        </div>"""
    if fx == "flow":
        return f"""<div {common}>
          <span class="fx-focus fx-focus--soft"></span>
          <span class="fx-ring"></span>
        </div>"""
    if fx == "grind":
        return f"""<div {common}>
          <span class="fx-rail"></span><span class="fx-sparks"></span>
        </div>"""
    return f"""<div {common}>
      <i class="fx-dot"></i><i class="fx-dot"></i><i class="fx-dot"></i>
      <i class="fx-dot"></i><i class="fx-dot"></i>
    </div>"""



def render_caso(site: dict, caso: dict, modes: dict, data: dict) -> str:
    base = site["siteUrl"].rstrip("/")
    slug = caso["slug"]
    mode = modes.get(caso.get("mode") or "indoor", modes["indoor"])
    cap_file, cap_label = MODE_CAPS.get(caso.get("mode") or "indoor", MODE_CAPS["indoor"])
    title = f"{caso['name']}: caso de uso | Repera"
    desc = f"{caso['summary']} Así registra Repera {caso['name'].lower()} en tu diario de entreno."
    canonical = f"{base}/casos/{slug}"
    mascot = f"/assets/mascots/{slug}.webp"
    theme = mascot_theme(caso)
    fx, fx_x, fx_y, fx_layer = mascot_fx(caso)
    fx_html = mascot_fx_markup(fx, fx_x, fx_y)
    step_themes = ("before", "live", "after")
    steps = "".join(
        f"""          <div class="moment moment--{step_themes[i % 3]}">
            <div class="hour">{esc(h)}</div>
            <div class="moment-b">
              <h3>{esc(t)}</h3>
              <p>{esc(d)}</p>
            </div>
          </div>"""
        for i, (h, t, d) in enumerate(mode["steps"])
    )
    # Prefer mode tiles (with icons) but keep sport-specific body in hero.
    record_items = []
    for tile in mode["tiles"]:
        if isinstance(tile, dict):
            record_items.append((tile.get("icon") or icon_for_text(tile.get("title", "")), tile["title"], tile["text"]))
        else:
            record_items.append((icon_for_text(tile[0]), tile[0], tile[1]))
    # Append sport-specific register lines when they add unique detail
    for line in caso.get("registers") or []:
        if len(record_items) >= 6:
            break
        if any(line[:40] in (t + d) for _, t, d in record_items):
            continue
        record_items.append((icon_for_text(line), "En este deporte", line))
    tiles = "".join(
        f"""          <div class="record-row">
            {icon_svg(ic, 22)}
            <div>
              <h3>{esc(t)}</h3>
              <p>{esc(d)}</p>
            </div>
          </div>"""
        for ic, t, d in record_items[:6]
    )
    ld = {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Inicio", "item": f"{base}/"},
            {"@type": "ListItem", "position": 2, "name": "Casos de uso", "item": f"{base}/casos"},
            {"@type": "ListItem", "position": 3, "name": caso["name"], "item": canonical},
        ],
    }
    return (
        head_html(
            title=title,
            description=desc,
            canonical=canonical,
            og_image=f"{base}{mascot}",
            json_ld=ld,
        )
        + header_html("casos", data)
        + f"""
  <main id="contenido">
    <section class="hero hero--sm case-hero case-hero--{theme}">
      <div class="wrap case-hero-g">
        <div data-reveal>
          <p class="eyebrow">{esc(caso["group"])}</p>
          <h1>{esc(caso["name"])}.</h1>
          <p class="lede">{esc(caso["body"])}</p>
          <div class="btn-row">
            <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer">Descargar en App Store</a>
          </div>
        </div>
        <div class="mascot-stage mascot-fx--{fx} mascot-slug--{slug} mascot-fx-layer--{fx_layer}" data-reveal>
          {fx_html}
          <img class="case-mascot" src="{mascot}" width="560" height="560" alt="El muñeco de Repera practicando {esc(caso["name"].lower())}">
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap case-split">
        <div data-reveal>
          <div class="section-head">
            <p class="eyebrow">El caso de uso</p>
            <h2>{esc(mode["title"])}</h2>
          </div>
          <div class="day">{steps}
          </div>
        </div>
        <figure class="shot case-shot" data-reveal>
          <span class="shot-frame">
            <img src="/assets/screens/{cap_file}" alt="{esc(cap_label)}" width="589" height="1200" loading="lazy">
          </span>
          <figcaption class="shot-cap">Pantalla real de la app · {esc(cap_label)}
            <span class="shot-note">Función compartida del diario; no es exclusiva de {esc(caso["name"].lower())}.</span>
          </figcaption>
        </figure>
      </div>
    </section>

    <section class="section section--alt case-records case-records--{theme}">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">Qué registra</p>
          <h2>Lo que queda en tu diario</h2>
        </div>
        <div class="records-stack">{tiles}
        </div>
        <p class="tiny" style="margin-top:1.5rem">{esc(mode["note"])}</p>
      </div>
    </section>

{cta_band("Listo para el próximo entreno", "Descarga Repera y apunta la sesión de hoy en el mismo diario.", light=True)}
  </main>
"""
        + footer_html()
        + "\n</body>\n</html>\n"
    )


def render_casos_index(site: dict, data: dict) -> str:
    base = site["siteUrl"].rstrip("/")
    title = "Casos de uso por actividad | Repera"
    desc = (
        "Cada actividad del selector de la app tiene su página: qué registra Repera "
        "en carrera, ciclismo, fuerza, pádel, natación y más."
    )
    groups = data["groups_order"]
    by_group: dict[str, list] = {g: [] for g in groups}
    for c in data["casos"]:
        if c.get("index", True):
            by_group.setdefault(c["group"], []).append(c)

    sections = []
    for i, g in enumerate(groups):
        items = by_group.get(g) or []
        if not items:
            continue
        gid = g.lower().replace(" ", "-")
        tiles = []
        for c in items:
            tiles.append(
                f"""          <a class="tile tile--row" href="/casos/{esc(c["slug"])}">
            <img class="tile-mascot" src="/assets/mascots/{esc(c["slug"])}.webp" width="88" height="88" alt="" loading="lazy">
            <div class="tile-body">
              <h3>{esc(c["name"])}</h3>
              <p>{esc(c["summary"])}</p>
              <span class="more">Ver caso →</span>
            </div>
          </a>"""
            )
        theme = mascot_theme({"group": g, "mode": "indoor"})
        alt = " section--alt" if i % 2 else ""
        sections.append(
            f"""    <section class="section{alt} casos-group casos-group--{theme}" id="{esc(gid)}">
      <div class="wrap">
        <div class="section-head section-head--glow">
          <p class="eyebrow">{esc(g.upper())}</p>
          <h2>{esc(g)}</h2>
        </div>
        <div class="tile-grid tile-grid--casos">
{chr(10).join(tiles)}
        </div>
      </div>
    </section>"""
        )

    return (
        head_html(
            title=title,
            description=desc,
            canonical=f"{base}/casos",
            og_image=site["ogImage"],
        )
        + header_html("casos", data)
        + f"""
  <main id="contenido">
    <section class="hero hero--sm casos-hero">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Casos de uso</p>
        <h1>Cada actividad, <em>su caso de uso.</em></h1>
        <p class="lede">Los grupos son los del selector de la app. Elige un deporte: verás el muñeco, el flujo Antes/Durante/Después y lo que queda en tu diario.</p>
        <div class="casos-hero-pills" aria-hidden="true">
          <span>GPS</span><span>Fuerza</span><span>WOD</span><span>Indoor</span><span>Watch</span>
        </div>
      </div>
    </section>
{chr(10).join(sections)}
    <section class="section casos-multi">
      <div class="wrap trust-strip" data-reveal>
        <article><h3>Varios deportes</h3><p>El lunes de gym y el domingo de monte cuentan en el mismo diario.</p></article>
        <article><h3>Sin exportar</h3><p>No cambias de app para que la salida y las series se vean juntas.</p></article>
        <article><h3>Misma identidad</h3><p>Los grupos son los del selector de Comenzar en la app.</p></article>
      </div>
      <div class="wrap center" style="margin-top:1.5rem" data-reveal>
        <a class="btn btn-ghost" href="/funcionalidades">Ver todas las funcionalidades</a>
      </div>
    </section>
{cta_band("Un diario para todo lo que entrenas", "Descarga Repera en App Store y registra la actividad que toque hoy.")}
  </main>
"""
        + footer_html()
        + "\n</body>\n</html>\n"
    )


def write_sitemap(site: dict, data: dict) -> None:
    base = site["siteUrl"].rstrip("/")
    urls: list[tuple[str, str, str]] = [
        ("/", "1.0", "weekly"),
        ("/funcionalidades", "0.8", "weekly"),
        ("/casos", "0.8", "weekly"),
        ("/outdoor", "0.8", "weekly"),
        ("/recuperacion", "0.8", "monthly"),
        ("/ia", "0.7", "monthly"),
        ("/precios", "0.8", "monthly"),
        ("/soporte", "0.6", "monthly"),
        ("/faq", "0.6", "monthly"),
        ("/privacy", "0.5", "monthly"),
        ("/terms", "0.5", "monthly"),
    ]
    for c in data["casos"]:
        if c.get("index", True):
            urls.append((f"/casos/{c['slug']}", "0.7", "monthly"))

    body = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ]
    for path, prio, freq in urls:
        loc = base + (path if path != "/" else "/")
        body += [
            "  <url>",
            f"    <loc>{loc}</loc>",
            f"    <lastmod>{TODAY}</lastmod>",
            f"    <changefreq>{freq}</changefreq>",
            f"    <priority>{prio}</priority>",
            "  </url>",
        ]
    body += ["</urlset>", ""]
    (ROOT / "sitemap.xml").write_text("\n".join(body), encoding="utf-8")


def main() -> None:
    site = load_json("site.json")
    data = load_json("casos.json")
    modes = load_json("modes.json")
    OUT_CASOS.mkdir(parents=True, exist_ok=True)

    for old in OUT_CASOS.glob("*.html"):
        old.unlink()

    indexed = [c for c in data["casos"] if c.get("index", True)]
    for caso in indexed:
        if len(caso.get("registers") or []) < 3 or not (caso.get("summary") or "").strip():
            raise SystemExit(f"Thin content blocked for slug={caso.get('slug')}")
        mascot = ROOT / "assets" / "mascots" / f"{caso['slug']}.webp"
        if not mascot.is_file():
            raise SystemExit(f"Missing mascot for {caso['slug']}")
        (OUT_CASOS / f"{caso['slug']}.html").write_text(
            render_caso(site, caso, modes, data), encoding="utf-8"
        )

    (ROOT / "casos.html").write_text(render_casos_index(site, data), encoding="utf-8")
    write_sitemap(site, data)
    (ROOT / "robots.txt").write_text(
        f"User-agent: *\nAllow: /\n\nDisallow: /console/\nDisallow: /ai/\n\n"
        f"Sitemap: {site['siteUrl'].rstrip('/')}/sitemap.xml\n",
        encoding="utf-8",
    )
    print(f"OK: {len(indexed)} casos + casos.html + sitemap + robots")


if __name__ == "__main__":
    main()
