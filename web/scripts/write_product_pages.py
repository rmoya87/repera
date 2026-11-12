#!/usr/bin/env python3
"""Write hand-maintained product HTML pages using shared chrome from build_site."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_site import (  # noqa: E402
    APP_STORE,
    cta_band,
    footer_html,
    head_html,
    header_html,
    load_json,
    scene_panel_hero,
)


def pace_map_html() -> str:
    """Mapa de ejemplo (Casa de Campo, Madrid) con recorrido coloreado por ritmo.

    Imagen generada por scripts/make_map_example.py a partir de teselas OSM.
    """
    return """<div class="pace-map pace-map--hero" role="img" aria-label="Mapa de ejemplo de la Casa de Campo, Madrid, con recorrido coloreado por ritmo">
  <div class="pace-hud" aria-hidden="true">
    <span><strong>9,90</strong> km</span>
    <span><strong>4:52</strong> /km</span>
    <span class="pace-hud-zone">Z3</span>
    <span><strong>+186</strong> m</span>
  </div>
  <img src="/assets/map-madrid-casa-de-campo-640.webp"
       srcset="/assets/map-madrid-casa-de-campo-640.webp 640w, /assets/map-madrid-casa-de-campo-1280.webp 1280w"
       sizes="(max-width: 640px) 100vw, 640px"
       width="640" height="360" loading="lazy" decoding="async" alt="">
  <div class="pace-legend">
    <span><i style="background:#30d158"></i> Suave</span>
    <span><i style="background:#a0e548"></i> Firme</span>
    <span><i style="background:#ffd60a"></i> Medio</span>
    <span><i style="background:#ff453a"></i> Rápido</span>
  </div>
  <p class="pace-map-tag">Mapa de ejemplo (Casa de Campo, Madrid); no es una salida real. Datos del mapa: © OpenStreetMap contributors</p>
</div>"""


def page(path: str, active: str, title: str, desc: str, main: str, json_ld=None) -> None:
    site = load_json("site.json")
    base = site["siteUrl"].rstrip("/")
    canonical = f"{base}/" if path == "/" else f"{base}{path}"
    html = (
        head_html(
            title=title,
            description=desc,
            canonical=canonical,
            og_image=site["ogImage"],
            json_ld=json_ld,
        )
        + header_html(active)
        + f"\n  <main id=\"contenido\">\n{main}\n  </main>\n"
        + footer_html()
        + "\n</body>\n</html>\n"
    )
    out = ROOT / ("index.html" if path == "/" else f"{path.strip('/')}.html")
    out.write_text(html, encoding="utf-8")
    print("wrote", out.relative_to(ROOT))


def main() -> None:
    site = load_json("site.json")
    base = site["siteUrl"].rstrip("/")

    home_ld = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "Organization",
                "@id": f"{base}/#org",
                "name": "Repera",
                "url": f"{base}/",
                "logo": f"{base}/assets/icon.png",
            },
            {
                "@type": "WebSite",
                "@id": f"{base}/#website",
                "url": f"{base}/",
                "name": "Repera",
                "publisher": {"@id": f"{base}/#org"},
                "inLanguage": "es-ES",
            },
            {
                "@type": "SoftwareApplication",
                "name": "Repera",
                "operatingSystem": "iOS, watchOS",
                "applicationCategory": "HealthApplication",
                "url": APP_STORE,
                "downloadUrl": APP_STORE,
                "image": f"{base}/assets/og-default.png",
                "description": "Diario de entrenamiento local-first para iPhone y Apple Watch.",
                "offers": [
                    {"@type": "Offer", "name": "Repera Gratis", "price": "0", "priceCurrency": "EUR"},
                    {
                        "@type": "Offer",
                        "name": "Repera Pro mensual",
                        "price": "5.99",
                        "priceCurrency": "EUR",
                        "description": "Precio orientativo España. El importe final lo muestra App Store.",
                    },
                    {
                        "@type": "Offer",
                        "name": "Repera Pro anual",
                        "price": "39.99",
                        "priceCurrency": "EUR",
                        "description": "Precio orientativo España. El importe final lo muestra App Store.",
                    },
                ],
            },
        ],
    }

    page(
        "/",
        "home",
        "Repera: tu diario de entreno para iPhone y Watch",
        "Registra fuerza, carrera, ciclismo y más en un solo diario de entrenamiento para iPhone y Apple Watch, con zonas de pulso, rutas y progreso.",
        f"""    <section class="hero">
      <div class="wrap hero-grid">
        <div class="hero-copy" data-reveal>
          <p class="eyebrow">Tu diario de entreno</p>
          <h1>Lo das todo. <em>Que quede.</em></h1>
          <p class="lede">De la primera serie al último kilómetro. Tu entrenamiento tiene un lugar.</p>
          <div class="btn-row" id="descargar">
            <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="hero">Descargar en App Store</a>
            <a class="btn btn-ghost" href="/precios">Ver planes</a>
          </div>
        </div>
        <div class="hero-visual hero-visual--combo" data-reveal>
          <div class="hero-combo">
            <figure class="phone-shot">
              <img src="/assets/screens/cap-emom.jpg" alt="Captura real: anotar un EMOM con kg, reps y RPE en Repera" width="589" height="1128" fetchpriority="high" decoding="async">
            </figure>
            <img class="combo-mascot" src="/assets/mascot-hero.png" srcset="/assets/mascot-hero-320.webp 320w, /assets/mascot-hero-512.webp 512w" sizes="(min-width: 768px) 160px, 120px" alt="" width="1024" height="1024" decoding="async">
          </div>
        </div>
      </div>
    </section>

    <section class="section feat-block feat-block--registro" id="producto">
      <div class="wrap editorial-split">
        <div data-reveal>
          <p class="eyebrow">01 / Registro</p>
          <h2>Menos memoria. <em class="accent-em">Más entreno.</em></h2>
          <p class="lede">Series con kg, reps y RPE. EMOM, AMRAP o el formato que toque. Escanea la pizarra o importa desde Strong/Hevy.</p>
          <ul class="journey-chips"><li>kg · reps</li><li>RPE</li><li>EMOM</li><li>Pizarra</li></ul>
          <p style="margin-top:1rem"><a href="/funcionalidades">Ver funcionalidades →</a></p>
        </div>
        <div class="shot-row" data-reveal>
          <figure class="phone-shot">
            <img src="/assets/screens/cap-emom.jpg" alt="Captura real: anotar un EMOM con kg, reps y RPE" width="589" height="1128" loading="lazy">
          </figure>
          <figure class="phone-shot">
            <img src="/assets/screens/cap-amrap.jpg" alt="Captura real: resultado de un AMRAP" width="589" height="1128" loading="lazy">
          </figure>
        </div>
      </div>
    </section>

    <section class="section section--alt feat-block feat-block--progreso">
      <div class="wrap editorial-split">
        <div class="shot-row" data-reveal>
          <figure class="phone-shot">
            <img src="/assets/screens/cap-progreso-entreno.jpg" alt="Captura real: progreso de entreno con racha y semana" width="589" height="1200" loading="lazy">
          </figure>
          <figure class="phone-shot">
            <img src="/assets/screens/cap-evolucion.jpg" alt="Captura real: evolución por ejercicio" width="589" height="1128" loading="lazy">
          </figure>
        </div>
        <div data-reveal>
          <p class="eyebrow">02 / Progreso</p>
          <h2>Saber si avanzas, sin hacer cuentas.</h2>
          <p class="lede">Racha, zonas de pulso, equilibrio muscular y evolución por ejercicio. Completo con Repera Pro.</p>
          <div class="mini-stats" aria-hidden="true">
            <span><strong>Racha</strong>días</span>
            <span><strong>Zonas</strong>FC</span>
            <span><strong>Evolución</strong>kg</span>
          </div>
        </div>
      </div>
    </section>

    <section class="privacy-band" id="privacidad-local" aria-labelledby="privacy-title">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Tus datos, tu teléfono</p>
        <h2 id="privacy-title">Calorías, GPS, pesos y series viven en tu dispositivo.</h2>
        <p class="lede">Repera es local-first: el diario se guarda en el iPhone. iCloud solo si tú lo activas. Apple Salud solo con tu permiso. No hay perfil público ni red social. Si conectas tu IA, compartes con ese asistente los datos que autorices.</p>
        <div class="privacy-grid">
          <article class="privacy-card"><strong>Local en el teléfono</strong><p>Pesos, repeticiones, rutas GPS, kcal y marcas quedan en tu dispositivo.</p></article>
          <article class="privacy-card"><strong>Sin red social</strong><p>No hay feed, ranking ni perfil público. Si conectas un asistente de IA, solo esa conexión recibe la copia de tu historial que autorices.</p></article>
          <article class="privacy-card"><strong>Tú autorizas</strong><p>Salud, iCloud y Conecta tu IA son opcionales. Exporta, revoca o borra desde Ajustes.</p></article>
        </div>
        <div class="lock-mark">Solo tú tienes la llave</div>
      </div>
    </section>

    <section class="section" id="planes">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">Precios</p>
          <h2>Gratis para entrenar. <em class="accent-em">Pro para evolucionar.</em></h2>
        </div>
        <div class="plan-compare plan-compare--rich">
          <article class="plan-card" data-reveal>
            <h3>Repera Gratis</h3>
            <p class="amount">0 €</p>
            <p class="muted">Registro completo sin fricción.</p>
            <ul>
              <li>Entrenamientos, series, pesos, RIR/RPE y WOD ilimitados</li>
              <li>Catálogo, timers, Watch, Salud e iCloud</li>
              <li>Historial general y exportación</li>
              <li>Hasta 3 rutinas y 5 ejercicios personalizados</li>
              <li>4 escaneos de pizarra al mes</li>
              <li>Progreso de esta semana + última sesión por ejercicio</li>
            </ul>
          </article>
          <article class="plan-card plan-card--pro" data-reveal>
            <span class="plan-badge">Recomendado</span>
            <h3>Repera Pro</h3>
            <p class="amount">39,99 € <small>/ año</small></p>
            <p class="muted">O 5,99 €/mes · precio final en App Store</p>
            <ul>
              <li>Todo lo de Gratis</li>
              <li>Rutinas, ejercicios y escaneos ilimitados</li>
              <li>Historial y evolución completa por ejercicio</li>
              <li>Estadísticas, periodos largos y mapa muscular</li>
              <li>Marcas y comparativas históricas de WOD</li>
              <li>Progresión avanzada al empezar la sesión</li>
            </ul>
          </article>
        </div>
        <div class="btn-row" style="margin-top:1.5rem" data-reveal>
          <a class="btn btn-ghost" href="/precios">Más detalle y FAQ</a>
        </div>
      </div>
    </section>

{cta_band("Tu próximo entreno empieza con el anterior.", "Descarga Repera en App Store y apunta la sesión de hoy.")}""",
        json_ld=home_ld,
    )

    page(
        "/funcionalidades",
        "funcionalidades",
        "Funcionalidades | Repera",
        "Diario de series, temporizadores, progreso, rutas y recuperación: lo que hace Repera para registrar y entender tu entrenamiento.",
        f"""{scene_panel_hero(
        "Funcionalidades",
        "Todo lo que hace Repera, <em>pieza a pieza.</em>",
        "Registro, progreso, Watch, outdoor, recuperación e IA — con el catálogo de ejercicios dentro de la app.",
        [
            ("Registro", "Series, RIR/RPE, EMOM, AMRAP y pizarra."),
            ("Progreso", "Racha, zonas y evolución por ejercicio."),
            ("Watch y outdoor", "Series en la muñeca y GPS en el mismo diario."),
        ],
        image="/assets/mascot-hero.png",
        image_alt="Mascota de Repera con mancuernas",
        tone="green",
        art="right",
    )}

    <section class="section feat-block feat-block--registro" id="registro">
      <div class="wrap editorial-split">
        <div data-reveal>
          <p class="eyebrow">01 / Registro</p>
          <h2>Anotar, más rápido que levantar.</h2>
          <p>Series con kg, repeticiones y RIR/RPE. Formato libre, EMOM, AMRAP. Escáner de pizarra e import CSV desde Strong o Hevy.</p>
          <ul class="journey-chips"><li>kg · reps</li><li>RIR/RPE</li><li>EMOM</li><li>AMRAP</li><li>Pizarra</li></ul>
        </div>
        <figure class="phone-shot" data-reveal>
          <img src="/assets/screens/cap-emom.jpg" alt="Captura real de registro EMOM" width="589" height="1128" loading="lazy">
        </figure>
      </div>
    </section>

    <section class="section section--alt feat-block feat-block--progreso" id="progreso">
      <div class="wrap editorial-split">
        <figure class="phone-shot" data-reveal>
          <img src="/assets/screens/cap-progreso-zonas.jpg" alt="Captura real: zonas cardiacas y progreso" width="589" height="1182" loading="lazy">
        </figure>
        <div data-reveal>
          <p class="eyebrow">02 / Progreso</p>
          <h2>Tu semana y tu historial, de un vistazo.</h2>
          <p>Racha, zonas de pulso, equilibrio muscular y evolución por ejercicio. Análisis largo con Pro.</p>
          <div class="mini-stats" aria-hidden="true">
            <span><strong>Racha</strong>días</span>
            <span><strong>Zonas</strong>FC</span>
            <span><strong>Evolución</strong>kg</span>
          </div>
        </div>
      </div>
    </section>

    <section class="section feat-block feat-block--timer" id="temporizador">
      <div class="wrap editorial-split">
        <div data-reveal>
          <p class="eyebrow">03 / Temporizador</p>
          <h2>El reloj que manda en el box.</h2>
          <p>Intervalos, rondas, trabajo y descanso. Reloj LED legible desde el otro lado de la sala.</p>
          <div class="timer-glow" aria-hidden="true"><span>12:00</span></div>
        </div>
        <figure class="phone-shot" data-reveal>
          <img src="/assets/screens/cap-timer-reloj.jpg" alt="Captura real: reloj LED del temporizador" width="589" height="1200" loading="lazy">
        </figure>
      </div>
    </section>

    <section class="section section--alt feat-block feat-block--watch" id="watch">
      <div class="wrap editorial-split">
        <div class="mascot-naked" data-reveal>
          <img src="/assets/mascot-watch.png" srcset="/assets/mascot-watch-320.webp 320w, /assets/mascot-watch-512.webp 512w" sizes="(min-width: 768px) 280px, 60vw" alt="Mascota de Repera con Apple Watch" width="512" height="512" loading="lazy">
        </div>
        <div data-reveal>
          <p class="eyebrow">04 / Apple Watch</p>
          <h2>Series sin sacar el teléfono.</h2>
          <p>Confirma el ejercicio, cuenta reps y apunta series desde el reloj. Se sincroniza con el iPhone.</p>
        </div>
      </div>
    </section>

    <section class="section" id="outdoor">
      <div class="wrap editorial-split">
        <div data-reveal>
          <p class="eyebrow">05 / Outdoor</p>
          <h2>GPS en el mismo diario.</h2>
          <p class="lede">Ruta coloreada por ritmo, zonas de pulso y avisos por kilómetro. <a href="/outdoor">Más sobre Outdoor →</a></p>
        </div>
        <div data-reveal>
{pace_map_html()}
        </div>
      </div>
    </section>

    <section class="section section--alt" id="recuperacion">
      <div class="wrap">
        <div class="night-scene night-scene--split" data-reveal>
          <div class="night-copy">
            <p class="eyebrow">06 / Recuperación</p>
            <h2>Sueño y VFC, junto a tu diario.</h2>
            <p class="lede">Noches, regularidad y variabilidad cardiaca de Apple Salud, visibles en la app y solo con tu permiso. Contexto, no órdenes clínicas.</p>
            <div class="recup-metrics">
              <div class="recup-metric"><strong>Sueño</strong><p>Duración y regularidad de tus últimas noches al lado de los entrenos.</p></div>
              <div class="recup-metric"><strong>VFC</strong><p>Variabilidad de la frecuencia cardiaca cuando Salud la tiene.</p></div>
              <div class="recup-metric"><strong>Permiso explícito</strong><p>Repera lee Apple Salud solo si tú lo autorizas. <a href="/recuperacion">Más →</a></p></div>
            </div>
          </div>
          <div class="recup-hero-art">
            <img class="mascot-sleep" src="/assets/mascot-sleep.png" srcset="/assets/mascot-sleep-320.webp 320w, /assets/mascot-sleep-640.webp 640w" sizes="(min-width: 860px) 320px, 70vw" alt="Mascota de Repera durmiendo" width="640" height="640" loading="lazy">
            <div class="moon-ring" aria-hidden="true"></div>
          </div>
        </div>
      </div>
    </section>

    <section class="section" id="ia">
      <div class="wrap" data-reveal>
        <p class="eyebrow">07 / Conecta tu IA</p>
        <h2>Tu asistente, con tu historial.</h2>
        <p class="lede">Claude, ChatGPT o Grok — el que tú elijas, con tus permisos. <a href="/ia">Entiende la conexión →</a></p>
        <div class="ai-constellation" style="margin-top:1.5rem" aria-hidden="true">
          <span class="ai-logo ai-logo--float"><img src="/assets/screens/claude.png" alt=""></span>
          <span class="ai-link"></span>
          <span class="ai-logo ai-logo--float" style="animation-delay:.35s"><img src="/assets/screens/chatgpt.png" alt=""></span>
          <span class="ai-link"></span>
          <span class="ai-logo ai-logo--float" style="animation-delay:.7s"><img src="/assets/screens/grok.png" alt=""></span>
        </div>
        <div class="ai-providers">
          <article class="ai-card ai-card--claude">
            <span class="ai-logo"><img src="/assets/screens/claude.png" alt="Claude" width="48" height="48"></span>
            <h3>Claude</h3>
            <p class="muted">Se conecta desde los ajustes de Claude.</p>
            <ul>
              <li>Consultar historial y series</li>
              <li>Planes que se importan al abrir o sincronizar</li>
              <li>Cambios en tu historial: los apruebas en la app</li>
            </ul>
          </article>
          <article class="ai-card ai-card--gpt">
            <span class="ai-logo"><img src="/assets/screens/chatgpt.png" alt="ChatGPT" width="48" height="48"></span>
            <h3>ChatGPT</h3>
            <p class="muted">Conexión desde ChatGPT web, según tu cuenta.</p>
            <ul>
              <li>Preguntas sobre tu progreso</li>
              <li>Sesiones o planes fechados</li>
              <li>Planes: importación automática</li>
            </ul>
          </article>
          <article class="ai-card ai-card--grok">
            <span class="ai-logo"><img src="/assets/screens/grok.png" alt="Grok" width="48" height="48"></span>
            <h3>Grok</h3>
            <p class="muted">Si tu cuenta permite conectar servicios externos.</p>
            <ul>
              <li>Mismo diario y permisos</li>
              <li>Sin pegar secretos en el chat</li>
              <li>Revoca en Conecta tu IA</li>
            </ul>
          </article>
        </div>
      </div>
    </section>

{cta_band("Empieza a registrar hoy", "Repera está en App Store para iPhone y Apple Watch.")}""",
    )


    page(
        "/outdoor",
        "outdoor",
        "Entrenamiento outdoor con GPS | Repera",
        "Ruta en el mapa, ritmo, zonas de pulso y avisos hablados por kilómetro para correr, ir en bici o caminar con Repera.",
        f"""    <section class="hero hero--sm outdoor-hero">
      <div class="wrap outdoor-hero-grid" data-reveal>
        <div>
          <p class="eyebrow">Outdoor</p>
          <h1>Donde acaba el asfalto, <em>no acaba tu diario.</em></h1>
          <p class="lede">GPS, ritmo y zonas de pulso en el mismo sitio que tus series del gym. El lunes de fuerza y el domingo de monte cuentan juntos.</p>
          <div class="btn-row">
            <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer">Descargar en App Store</a>
            <a class="btn btn-ghost" href="/casos">Casos de carrera y ciclismo</a>
          </div>
        </div>
        <div>
{pace_map_html()}
        </div>
      </div>
    </section>

    <section class="section outdoor-journey">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">Así es una salida</p>
          <h2>De la puerta de casa al análisis</h2>
        </div>
        <div class="journey-track" data-reveal>
          <article class="journey-card journey-card--before">
            <span class="journey-kicker">01 · Antes</span>
            <h3>Condiciones y cuenta atrás</h3>
            <p>Clima del punto de salida. Si sopla fuerte, igual la ruta va por el interior. Tres segundos y sales.</p>
            <ul class="journey-chips"><li>Clima</li><li>GPX</li><li>Cuenta atrás</li></ul>
          </article>
          <article class="journey-card journey-card--live">
            <span class="journey-kicker">02 · Durante</span>
            <h3>Sin mirar el móvil</h3>
            <p>El GPS dibuja la ruta. Ritmo, desnivel y zona de pulso. Avisos hablados por km, también con pantalla bloqueada.</p>
            <div class="live-pulse" aria-hidden="true"><i></i><i></i><i></i></div>
          </article>
          <article class="journey-card journey-card--after">
            <span class="journey-kicker">03 · Después</span>
            <h3>Queda en el diario</h3>
            <p>Distancia, tiempo, ritmo y mapa junto al resto de tu semana. Sin exportar a otra app.</p>
            <div class="after-spark" aria-hidden="true"></div>
          </article>
        </div>
      </div>
    </section>

    <section class="section section--alt outdoor-caps">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">Qué incluye</p>
          <h2>Pensado para la salida de hoy</h2>
        </div>
        <div class="cap-mosaic" data-reveal>
          <article class="cap-panel cap-panel--map">
            <h3>Ruta en el mapa</h3>
            <p>Sigue el recorrido en directo y revísalo al terminar. Los cortes de señal no se rellenan con rectas inventadas.</p>
          </article>
          <article class="cap-panel">
            <span class="cap-icon" aria-hidden="true">↗</span>
            <h3>Ritmo y desnivel</h3>
            <p>Los datos que importan mientras te mueves.</p>
          </article>
          <article class="cap-panel">
            <span class="cap-icon" aria-hidden="true">♥</span>
            <h3>Zonas de pulso</h3>
            <p>Intensidad a la vista, con permiso de Salud.</p>
          </article>
          <article class="cap-panel">
            <span class="cap-icon" aria-hidden="true">♪</span>
            <h3>Avisos por km</h3>
            <p>Tiempo del tramo en voz alta.</p>
          </article>
          <article class="cap-panel">
            <span class="cap-icon" aria-hidden="true">⌖</span>
            <h3>Guía GPX</h3>
            <p>Giros anunciados si sigues una ruta guardada.</p>
          </article>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap editorial-split">
        <div data-reveal>
          <h2>En la app de hoy</h2>
          <p class="lede">Cada salida guarda fecha, hora, duración y su lugar. Sustituye o amplía esta captura cuando tengas un mapa en directo.</p>
        </div>
        <figure class="phone-shot" data-reveal>
          <img src="/assets/screens/cap-actividad.jpg" alt="Captura real: editar entreno con lugar en el mapa" width="589" height="1200" loading="lazy">
        </figure>
      </div>
    </section>

{cta_band("Sal y que quede registrado", "Repera en App Store — iPhone y Apple Watch.")}""",
    )


    page(
        "/recuperacion",
        "recuperacion",
        "Recuperación y sueño | Repera",
        "El sueño y la variabilidad cardiaca de Apple Salud junto a tu actividad, para decidir cuánto entrenar cada día.",
        f"""    <section class="hero hero--sm recup-hero">
      <div class="wrap recup-hero-grid" data-reveal>
        <div>
          <p class="eyebrow">Recuperación</p>
          <h1>Cómo llegas a la sesión de las siete.</h1>
          <p class="lede">Dos personas con el mismo plan no llegan igual. Sueño y VFC de Apple Salud, junto a tus entrenos — contexto, no una receta automática.</p>
          <div class="btn-row">
            <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer">Descargar en App Store</a>
            <a class="btn btn-ghost" href="/privacy">Privacidad y Salud</a>
          </div>
        </div>
        <div class="recup-hero-art">
          <img class="mascot-sleep" src="/assets/mascot-sleep.png" srcset="/assets/mascot-sleep-320.webp 320w, /assets/mascot-sleep-640.webp 640w" sizes="(min-width: 860px) 320px, 70vw" alt="Mascota de Repera durmiendo" width="640" height="640" loading="eager">
          <div class="moon-ring" aria-hidden="true"></div>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">En el código de la app</p>
          <h2>Lo que puedes saber de verdad</h2>
        </div>
        <div class="insight-stack" data-reveal>
          <article class="insight-row">
            <div class="insight-num">01</div>
            <div>
              <h3>Sueño</h3>
              <p>Noches del periodo con duración y regularidad. Si el filtro no tiene datos, muestra historial reciente con nota — sin inventar horas.</p>
            </div>
            <div class="insight-stat"><strong>7h 42</strong><span>ejemplo</span></div>
          </article>
          <article class="insight-row">
            <div class="insight-num">02</div>
            <div>
              <h3>VFC</h3>
              <p>Variabilidad a lo largo del tiempo cuando Apple Salud la tiene. Solo lectura autorizada; si no hay muestras, no hay número inventado.</p>
            </div>
            <div class="insight-stat"><strong>VFC</strong><span>cuando hay</span></div>
          </article>
          <article class="insight-row">
            <div class="insight-num">03</div>
            <div>
              <h3>Ciclo</h3>
              <p>Solo si hay registros reales de menstruación. Orientativo; no predice fertilidad ni sustituye consejo médico.</p>
            </div>
            <div class="insight-stat"><strong>Opt-in</strong><span>explícito</span></div>
          </article>
        </div>
        <p class="disclaimer-medical" data-reveal>Información orientativa sobre tu descanso. No sustituye el consejo médico.</p>
      </div>
    </section>

    <section class="privacy-band recup-privacy">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Privacidad primero</p>
        <h2>Contexto, no órdenes. Datos que no salen.</h2>
        <div class="privacy-grid">
          <article class="privacy-card"><strong>Tú decides</strong><p>Repera pone sueño y VFC al lado de lo entrenado. No te dice automáticamente que bajes carga.</p></article>
          <article class="privacy-card"><strong>Opt-in</strong><p>El análisis de descanso se activa desde Salud / Ajustes, no a la fuerza.</p></article>
          <article class="privacy-card"><strong>Sin backend sensible</strong><p>Horas de sueño y fases no se mandan a Supabase.</p></article>
        </div>
      </div>
    </section>

{cta_band("Entrena con contexto", "Descarga Repera y conecta Apple Salud solo con tu permiso.")}""",
    )


    page(
        "/ia",
        "ia",
        "Conecta tu IA con Repera | Repera",
        "Conecta tu propio asistente de IA para consultar tu historial y, con tu permiso, crear planes que se importan a Repera al sincronizar.",
        f"""    <section class="hero hero--sm ia-hero">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Conecta tu IA</p>
        <h1>Tu asistente. Tu historial. Tu siguiente plan.</h1>
        <p class="lede" style="margin-inline:auto;text-align:center;max-width:38rem">No es un coach integrado. Es Claude, ChatGPT o Grok — el que tú elijas — con tu diario. Requiere cuenta Repera; una copia de tu historial vive en servidor solo si conectas la IA.</p>
        <div class="btn-row" style="justify-content:center">
          <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="ia_hero">Descargar en App Store</a>
          <a class="btn btn-ghost" href="#como-conectar" data-track="ai_setup_help_click" data-track-cta="ia_hero">Cómo conectar tu IA</a>
        </div>
        <div class="ai-constellation ai-constellation--xl" style="margin-top:2rem" aria-hidden="true">
          <span class="ai-logo ai-logo--float"><img src="/assets/screens/claude.png" alt=""></span>
          <span class="ai-link"></span>
          <span class="ai-core-chip">MCP</span>
          <span class="ai-link"></span>
          <span class="ai-logo ai-logo--float" style="animation-delay:.35s"><img src="/assets/screens/chatgpt.png" alt=""></span>
          <span class="ai-link"></span>
          <span class="ai-logo ai-logo--float" style="animation-delay:.7s"><img src="/assets/screens/grok.png" alt=""></span>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap" data-reveal>
        <div class="section-head">
          <p class="eyebrow">Tres asistentes</p>
          <h2>Elige el tuyo. Mismo diario.</h2>
        </div>
        <div class="ai-providers ai-providers--glow">
          <article class="ai-card ai-card--claude">
            <span class="ai-logo"><img src="/assets/screens/claude.png" alt="Claude" width="48" height="48"></span>
            <h3>Claude</h3>
            <p class="muted">Se conecta desde los ajustes de Claude (Personalizar → Conectores).</p>
            <ul>
              <li>Consultar historial y series</li>
              <li>Crear planes que se importan al abrir o sincronizar</li>
              <li>Cambios en entrenamientos y ejercicios propios: los apruebas en la app</li>
            </ul>
          </article>
          <article class="ai-card ai-card--gpt">
            <span class="ai-logo"><img src="/assets/screens/chatgpt.png" alt="ChatGPT" width="48" height="48"></span>
            <h3>ChatGPT</h3>
            <p class="muted">Conexión desde ChatGPT web, según tu cuenta.</p>
            <ul>
              <li>Preguntas sobre tu progreso</li>
              <li>Sesiones sueltas o planes fechados</li>
              <li>Planes: se importan al abrir o sincronizar la app</li>
            </ul>
          </article>
          <article class="ai-card ai-card--grok">
            <span class="ai-logo"><img src="/assets/screens/grok.png" alt="Grok" width="48" height="48"></span>
            <h3>Grok</h3>
            <p class="muted">Si tu cuenta permite conectar servicios externos con acceso autorizado.</p>
            <ul>
              <li>Mismo diario, mismos permisos</li>
              <li>Sin pegar secretos en el chat</li>
              <li>Revoca en Ajustes → Conecta tu IA</li>
            </ul>
          </article>
        </div>
      </div>
    </section>

    <section class="section section--alt" id="como-conectar">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">Flujo</p>
          <h2>Del chat a tu diario</h2>
        </div>
        <div class="flow-rail" data-reveal>
          <div class="flow-step">
            <div class="flow-badge">1</div>
            <h3>Autorizas</h3>
            <p>Cuenta Repera y permiso de lectura o escritura, que puedes revocar cuando quieras.</p>
          </div>
          <div class="flow-arrow" aria-hidden="true">→</div>
          <div class="flow-step">
            <div class="flow-badge">2</div>
            <h3>Preguntas</h3>
            <p>La copia de tu historial, series, progreso y material — no Salud ni GPS.</p>
          </div>
          <div class="flow-arrow" aria-hidden="true">→</div>
          <div class="flow-step">
            <div class="flow-badge">3</div>
            <h3>Importación</h3>
            <p>Los planes llegan al Diario al abrir o sincronizar; los cambios de historial piden tu OK.</p>
          </div>
        </div>
      </div>
    </section>

{cta_band("Primero el diario, luego el asistente", "Empieza en App Store y conecta la IA cuando quieras.")}""",
    )

    precios_ld = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {
                "@type": "Question",
                "name": "¿Qué incluye la versión gratuita?",
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": "Registro ilimitado de entrenos, catálogo, timers, Watch, Salud e iCloud, con límites en rutinas, ejercicios propios y escaneos de pizarra.",
                },
            },
            {
                "@type": "Question",
                "name": "¿Cómo cancelo Repera Pro?",
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": "Desde la cuenta de Apple, en Suscripciones. Cancelar Pro no borra tus entrenos.",
                },
            },
        ],
    }

    page(
        "/precios",
        "precios",
        "Precios y planes | Repera",
        "Plan gratuito y Repera Pro: precios orientativos, comparativa y preguntas frecuentes sobre la suscripción.",
        f"""{scene_panel_hero(
        "Precios",
        "Precios claros, <em>sin sorpresas.</em>",
        "Entrena gratis desde el primer día. Pro quita límites y abre el análisis largo. El importe final es el de App Store.",
        [
            ("Gratis", "Registro completo sin fricción."),
            ("Pro", "Historial largo, cuotas ilimitadas y más."),
            ("App Store", "Cobro y cancelación con tu cuenta de Apple."),
        ],
        image="/assets/mascot-watch.png",
        image_alt="Mascota de Repera con Apple Watch",
        tone="amber",
        art="right",
    )}

    <section class="section">
      <div class="wrap plan-compare plan-compare--rich plan-compare--stage">
        <article class="plan-card" data-reveal>
          <p class="plan-tier">Gratis</p>
          <h3>Repera Gratis</h3>
          <p class="amount">0 €</p>
          <p class="muted">Registro completo sin fricción.</p>
          <a class="btn btn-ghost" href="{APP_STORE}" rel="noopener noreferrer" data-track="plan_cta_click" data-track-plan="gratis" data-track-platform="ios" data-track-cta="plan_card">Empezar gratis</a>
          <ul>
            <li>Entrenamientos, series, pesos, RIR/RPE y WOD ilimitados</li>
            <li>Catálogo, timers, Watch, Salud e iCloud</li>
            <li>Historial general y exportación</li>
            <li>Hasta 3 rutinas y 5 ejercicios personalizados</li>
            <li>4 escaneos de pizarra al mes</li>
            <li>Progreso de esta semana + última sesión por ejercicio</li>
          </ul>
        </article>
        <article class="plan-card plan-card--pro" data-reveal>
          <span class="plan-badge">Mejor valor</span>
          <p class="plan-tier">Pro</p>
          <h3>Repera Pro</h3>
          <p class="amount">39,99 € <small>/ año</small></p>
          <p class="muted">O 5,99 €/mes · cancela cuando quieras</p>
          <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer" data-track="plan_cta_click" data-track-plan="pro" data-track-platform="ios" data-track-cta="plan_card">Probar en App Store</a>
          <ul>
            <li>Todo lo de Gratis</li>
            <li>Rutinas, ejercicios y escaneos ilimitados</li>
            <li>Historial y evolución completa por ejercicio</li>
            <li>Estadísticas, periodos largos y mapa muscular</li>
            <li>Marcas y comparativas históricas de WOD</li>
            <li>Progresión avanzada al empezar la sesión</li>
          </ul>
        </article>
      </div>
      <div class="wrap" style="margin-top:1.25rem">
        <p class="tiny" data-reveal>Importes orientativos para España. El precio final es el de App Store en tu país y moneda. La suscripción se renueva automáticamente salvo cancelación al menos 24 h antes. Gestiona en la cuenta de Apple. Más en la <a href="/faq">FAQ</a> y los <a href="/terms">Términos</a>.</p>
      </div>
    </section>

    <section class="section section--alt">
      <div class="wrap">
        <div class="section-head" data-reveal>
          <p class="eyebrow">De un vistazo</p>
          <h2>Qué cambia con Pro</h2>
        </div>
        <div class="compare-table" data-reveal>
          <div class="compare-row compare-head"><span>Función</span><span>Gratis</span><span>Pro</span></div>
          <div class="compare-row"><span>Registro de entrenos</span><span>Ilimitado</span><span>Ilimitado</span></div>
          <div class="compare-row"><span>Rutinas</span><span>Hasta 3</span><span>Ilimitadas</span></div>
          <div class="compare-row"><span>Ejercicios propios</span><span>Hasta 5</span><span>Ilimitados</span></div>
          <div class="compare-row"><span>Escaneos de pizarra</span><span>4 / mes</span><span>Ilimitados</span></div>
          <div class="compare-row"><span>Historial por ejercicio</span><span>Última sesión</span><span>Completo</span></div>
          <div class="compare-row"><span>Periodos y mapa muscular</span><span>—</span><span>Sí</span></div>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap trust-strip" data-reveal>
        <article><h3>Gratis no es demo</h3><p>Registras sin pagar. Pro es para el análisis completo y sin cupos.</p></article>
        <article><h3>Cancela en Apple</h3><p>Desde Suscripciones. Cancelar Pro no borra tus entrenos.</p></article>
        <article><h3>Precio local</h3><p>App Store muestra el importe de tu país y moneda.</p></article>
      </div>
    </section>

    <section class="section section--alt">
      <div class="wrap narrow faq" data-reveal>
        <div class="section-head">
          <p class="eyebrow">Ayuda</p>
          <h2>Preguntas frecuentes</h2>
        </div>
        <details open>
          <summary>¿Qué incluye la versión gratuita?</summary>
          <p>Registro ilimitado de entrenos, catálogo, timers, Watch, Salud e iCloud, con límites en rutinas, ejercicios propios y escaneos de pizarra.</p>
        </details>
        <details>
          <summary>¿Cómo cancelo Repera Pro?</summary>
          <p>Desde la cuenta de Apple, en Suscripciones. Cancelar Pro no borra tus entrenos.</p>
        </details>
        <details>
          <summary>¿Hay versión para Android?</summary>
          <p>Está en preparación. No hay fecha anunciada.</p>
        </details>
        <p class="faq-more"><a href="/faq">Ver todas las preguntas →</a></p>
      </div>
    </section>

{cta_band("Prueba Repera gratis", "Descárgala en App Store y decide más tarde si quieres Pro.")}""",
        json_ld=precios_ld,
    )

    support = site.get("supportEmail")
    if support:
        contact = (
            f'<p class="lede">Escríbenos a <a href="mailto:{support}" data-track="support_click" data-track-cta="soporte_texto">{support}</a> '
            'para cualquier duda con la app, tu cuenta, la suscripción o la conexión con tu IA.</p>'
        )
        buttons = (
            f'          <a class="btn btn-primary" href="mailto:{support}" data-track="support_click" data-track-cta="soporte_mailto">{support}</a>\n'
            '          <a class="btn btn-ghost" href="/faq">Preguntas frecuentes</a>'
        )
        support_desc = (
            f"Ayuda con Repera: escríbenos a {support}, consulta las preguntas frecuentes "
            "o gestiona tu suscripción en App Store."
        )
        extra_section = """    <section class="section">
      <div class="wrap" data-reveal>
        <h2>Qué incluir en tu correo</h2>
        <p class="lede">Cuanto más contexto, antes te ayudamos: la versión de la app, tu dispositivo y, si es un error, qué esperabas y qué pasó. Si escribes por la conexión con tu IA, dinos qué asistente usas.</p>
        <p class="muted">La suscripción Pro (cambios, cancelación, reembolsos) se gestiona con Apple: <a href="https://apps.apple.com/account/subscriptions" rel="noopener noreferrer">apps.apple.com/account/subscriptions</a>.</p>
      </div>
    </section>
"""
    else:
        contact = '<p class="lede">El canal de correo de soporte se publicará aquí cuando esté confirmado. Mientras tanto usa la FAQ o gestiona la suscripción desde Apple.</p>'
        buttons = (
            '          <a class="btn btn-primary" href="/faq">Preguntas frecuentes</a>\n'
            f'          <a class="btn btn-ghost" href="{APP_STORE}" rel="noopener noreferrer">App Store</a>'
        )
        support_desc = "Ayuda con Repera: contacto, FAQ, privacidad y gestión de la suscripción en App Store."
        extra_section = ""

    page(
        "/soporte",
        "",
        "Soporte y contacto | Repera",
        support_desc,
        f"""    <section class="hero hero--sm">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Ayuda</p>
        <h1>Soporte y contacto</h1>
        {contact}
        <div class="btn-row">
{buttons}
        </div>
      </div>
    </section>
    <section class="section">
      <div class="wrap cols3">
        <a class="tile" href="/privacy"><h3>Privacidad</h3><p>Datos, Salud e iCloud.</p><span class="more">Abrir</span></a>
        <a class="tile" href="/terms"><h3>Términos</h3><p>Uso de la app y suscripción.</p><span class="more">Abrir</span></a>
        <a class="tile" href="https://apps.apple.com/account/subscriptions" rel="noopener noreferrer"><h3>Suscripción</h3><p>Gestionar o cancelar en Apple.</p><span class="more">Abrir</span></a>
      </div>
    </section>
{extra_section}{cta_band("¿Listo para entrenar?", "Descarga Repera en App Store. El soporte de suscripción lo gestiona Apple.")}""",
    )

    # —— FAQ / Privacidad / Términos (mismo chrome que el resto del sitio) ——
    faq_items = json.loads((ROOT / "content" / "faq.json").read_text(encoding="utf-8"))
    faq_details = []
    faq_ld_entities = []
    for item in faq_items:
        open_attr = " open" if item.get("open") else ""
        faq_details.append(
            f"""        <details{open_attr}>
          <summary>{item["q"]}</summary>
          <p>{item["a"]}</p>
        </details>"""
        )
        # Strip tags for JSON-LD plain text
        plain = re.sub(r"<[^>]+>", "", item["a"])
        plain = plain.replace("\xa0", " ").replace("&nbsp;", " ")
        faq_ld_entities.append(
            {
                "@type": "Question",
                "name": item["q"],
                "acceptedAnswer": {"@type": "Answer", "text": plain},
            }
        )
    faq_ld = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": faq_ld_entities,
    }
    page(
        "/faq",
        "",
        "FAQ — Repera Pro y suscripciones",
        "Preguntas frecuentes sobre Repera Gratis, Repera Pro, precios, prueba, cancelación y restauración.",
        f"""    <section class="hero hero--sm">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Ayuda</p>
        <h1>Preguntas frecuentes</h1>
        <p class="lede">Suscripción, límites del plan gratuito y gestión en App Store o Google Play.</p>
        <div class="btn-row">
          <a class="btn btn-ghost" href="/precios">Ver precios</a>
          <a class="btn btn-ghost" href="/soporte">Soporte</a>
        </div>
      </div>
    </section>
    <section class="section">
      <div class="wrap narrow faq" data-reveal>
{chr(10).join(faq_details)}
      </div>
    </section>
{cta_band("Prueba Repera gratis", "Descárgala en App Store. Cancela Pro cuando quieras desde Apple.")}""",
        json_ld=faq_ld,
    )

    privacy_body = (ROOT / "content" / "privacy_body.html").read_text(encoding="utf-8")
    page(
        "/privacy",
        "",
        "Privacidad — Repera",
        "Política de privacidad de Repera: datos locales, cuenta, conexión IA, iCloud, Apple Salud, compras y cookies.",
        f"""    <section class="hero hero--sm">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Legal</p>
        <h1>Política de privacidad</h1>
        <p class="lede">Última actualización: 11 de noviembre de 2026</p>
        <div class="btn-row">
          <a class="btn btn-ghost" href="/privacy-en">English</a>
          <a class="btn btn-ghost" href="/terms">Términos de uso</a>
          <a class="btn btn-ghost" href="/faq">FAQ</a>
        </div>
      </div>
    </section>
    <section class="section section--tight">
      <div class="wrap narrow">
        <article class="prose" data-reveal>
{privacy_body}        </article>
        <p class="legal-nav" data-reveal>
          <a href="/privacy-en">English</a>
          <a href="/terms">Términos de uso</a>
          <a href="/faq">FAQ</a>
          <a href="/soporte">Soporte</a>
        </p>
      </div>
    </section>""",
    )

    privacy_body_en = (ROOT / "content" / "privacy_body_en.html").read_text(encoding="utf-8")
    page(
        "/privacy-en",
        "",
        "Privacy Policy — Repera",
        "Repera privacy policy: local data, account, AI connection, iCloud, Apple Health, purchases and cookies.",
        f"""    <section class="hero hero--sm">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Legal</p>
        <h1>Privacy policy</h1>
        <p class="lede">Last updated: 11 November 2026</p>
        <div class="btn-row">
          <a class="btn btn-ghost" href="/privacy">Español</a>
          <a class="btn btn-ghost" href="/terms">Terms</a>
          <a class="btn btn-ghost" href="/faq">FAQ</a>
        </div>
      </div>
    </section>
    <section class="section section--tight">
      <div class="wrap narrow">
        <article class="prose" data-reveal>
{privacy_body_en}        </article>
        <p class="legal-nav" data-reveal>
          <a href="/privacy">Español</a>
          <a href="/terms">Terms</a>
          <a href="/faq">FAQ</a>
          <a href="/soporte">Support</a>
        </p>
      </div>
    </section>""",
    )

    terms_body = (ROOT / "content" / "terms_body.html").read_text(encoding="utf-8")
    page(
        "/terms",
        "",
        "Términos de uso — Repera",
        "Términos de uso y condiciones de suscripción de Repera Pro (App Store y Google Play).",
        f"""    <section class="hero hero--sm">
      <div class="wrap" data-reveal>
        <p class="eyebrow">Legal</p>
        <h1>Términos de uso</h1>
        <p class="lede">Última actualización: 11 de noviembre de 2026</p>
        <div class="btn-row">
          <a class="btn btn-ghost" href="/privacy">Privacidad</a>
          <a class="btn btn-ghost" href="/faq">FAQ</a>
        </div>
      </div>
    </section>
    <section class="section section--tight">
      <div class="wrap narrow">
        <article class="prose" data-reveal>
{terms_body}        </article>
        <p class="legal-nav" data-reveal>
          <a href="/privacy">Privacidad</a>
          <a href="/faq">FAQ</a>
          <a href="/soporte">Soporte</a>
        </p>
      </div>
    </section>""",
    )

    print("product pages done")


if __name__ == "__main__":
    main()
