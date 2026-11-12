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

# SF Symbol names — same mapping as LiveSport.symbol (LiveActivityView.swift)
SPORT_SF = {
    "carrera": "figure.run",
    "carrera-montana": "figure.run",
    "caminata": "figure.walk",
    "senderismo": "figure.hiking",
    "ciclismo-carretera": "figure.outdoor.cycle",
    "ciclismo-montana": "bicycle",
    "gravel": "bicycle",
    "entrenamiento": "figure.strengthtraining.traditional",
    "crossfit": "figure.cross.training",
    "hiit": "timer",
    "hyrox": "figure.run",
    "tenis": "figure.tennis",
    "padel": "figure.tennis",
    "badminton": "figure.badminton",
    "pickleball": "figure.pickleball",
    "squash": "figure.squash",
    "natacion": "figure.pool.swim",
    "surf": "surfboard",
    "windsurf": "figure.sailing",
    "kitesurf": "figure.surfing",
    "kayak": "figure.rower",
    "remo": "figure.outdoor.rowing",
    "piragua": "oar.2.crossed",
    "vela": "sailboat",
    "esqui-alpino": "figure.skiing.downhill",
    "snowboard": "figure.snowboarding",
    "esqui-fondo": "figure.skiing.crosscountry",
    "patinaje-hielo": "figure.ice.skating",
    "futbol": "figure.indoor.soccer",
    "baloncesto": "figure.basketball",
    "voleibol": "figure.volleyball",
    "futbol-americano": "figure.american.football",
    "beisbol": "figure.baseball",
    "hockey": "figure.field.hockey",
    "lacrosse": "figure.lacrosse",
    "rugby": "figure.rugby",
    "boxeo": "figure.boxing",
    "kickboxing": "figure.kickboxing",
    "artes-marciales": "figure.martial.arts",
    "lucha": "figure.wrestling",
    "fuerza-funcional": "dumbbell",
    "core": "figure.core.training",
    "golf": "figure.golf",
    "escalada": "figure.climbing",
    "baile": "figure.dance",
    "pilates": "figure.pilates",
    "skateboard": "figure.skating",
    "yoga": "figure.yoga",
    "movilidad": "figure.flexibility",
    "otra-actividad": "figure.mixed.cardio",
}

# Stroke fallback kinds for record tiles / icon_for_text
SPORT_ICON = {
    "carrera": "run",
    "carrera-montana": "trail",
    "caminata": "walk",
    "senderismo": "hike",
    "ciclismo-carretera": "bike-road",
    "ciclismo-montana": "bike-mtb",
    "gravel": "bike-gravel",
    "entrenamiento": "barbell",
    "crossfit": "kettlebell",
    "hiit": "timer",
    "hyrox": "sled",
    "tenis": "tennis",
    "padel": "padel",
    "badminton": "shuttle",
    "pickleball": "pickleball",
    "squash": "squash",
    "natacion": "swim",
    "surf": "surfboard",
    "windsurf": "windsurf",
    "kitesurf": "kite",
    "kayak": "kayak",
    "remo": "rowing",
    "piragua": "canoe",
    "vela": "sailboat",
    "esqui-alpino": "ski-down",
    "snowboard": "snowboard",
    "esqui-fondo": "ski-xc",
    "patinaje-hielo": "ice-skate",
    "futbol": "soccer",
    "baloncesto": "basketball",
    "voleibol": "volleyball",
    "futbol-americano": "football",
    "beisbol": "baseball",
    "hockey": "hockey",
    "lacrosse": "lacrosse",
    "rugby": "rugby",
    "boxeo": "boxing",
    "kickboxing": "kickboxing",
    "artes-marciales": "martial",
    "lucha": "wrestling",
    "fuerza-funcional": "dumbbell",
    "core": "core",
    "golf": "golf",
    "escalada": "climb",
    "baile": "dance",
    "pilates": "pilates",
    "skateboard": "skateboard",
    "yoga": "yoga",
    "movilidad": "mobility",
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



def sf_symbol_file(name: str) -> str:
    return name.replace(".", "-") + ".png"


def sport_sf_icon(slug: str, size: int = 22) -> str:
    """Apple SF Symbol glyph (exported PNG), tinted via CSS mask."""
    symbol = SPORT_SF.get(slug, "figure.mixed.cardio")
    src = f"/assets/sf-symbols/{sf_symbol_file(symbol)}"
    return (
        f'<span class="sport-icon sport-icon--sf" style="'
        f"-webkit-mask-image:url('{src}');mask-image:url('{src}');"
        f'width:{size}px;height:{size}px" aria-hidden="true"></span>'
    )


def icon_svg(kind: str, size: int = 20) -> str:
    """SF-Symbol-like sport icons (figure silhouettes), shared stroke style."""
    h = '<circle cx="{cx}" cy="{cy}" r="1.85" fill="currentColor" stroke="none"/>'
    paths = {
        # —— A pie (figure.run / walk / hiking) ——
        "run": (
            h.format(cx="14.2", cy="4.2")
            + '<path d="M9.2 21.2 11.5 13.2l3.2 1.6 1.8 6.4"/>'
            + '<path d="M11.5 13.2 7.8 14.5 6.5 9.8l4.6-2.1 2.4 3"/>'
            + '<path d="M14.8 8.2 18 10.5"/>'
        ),
        "trail": (
            h.format(cx="13.5", cy="4.2")
            + '<path d="M8.5 21 11 13.2l3 1.5 2 6.3"/>'
            + '<path d="M11 13.2 7.2 15 6 10l4.2-2 2.3 2.8"/>'
            + '<path d="M3.5 19.5 7 12.5 10 15.5 14 8l6.5 11.5"/>'
        ),
        "walk": (
            h.format(cx="12.2", cy="4.2")
            + '<path d="M9.2 21.2 11.2 14l2.1 2 1.7 5.2"/>'
            + '<path d="M11.2 14 8.2 15 7.2 10.2l3.8-1.7 1.8 2.7"/>'
        ),
        "hike": (
            h.format(cx="11.2", cy="4.2")
            + '<path d="M8 21.2 10.6 13.2l2 2 3.2 6"/>'
            + '<path d="M10.6 13.2 6.8 20"/>'
            + '<path d="M15.5 7.5 18.8 12"/>'
            + '<path d="M14.2 8.5h3"/>'
        ),
        # —— Ciclismo (figure.outdoor.cycle / bicycle) ——
        "bike-road": (
            '<circle cx="6.2" cy="16.2" r="3.3"/>'
            '<circle cx="17.8" cy="16.2" r="3.3"/>'
            + h.format(cx="13.2", cy="5.2")
            + '<path d="M6.2 16.2 10.2 9.2h4.5L17.8 16.2"/>'
            + '<path d="M10.2 9.2 12.5 13.5"/>'
            + '<path d="M12.8 7.2 15.2 5.8"/>'
        ),
        "bike-mtb": (
            '<circle cx="6.2" cy="16.2" r="3.3"/>'
            '<circle cx="17.8" cy="16.2" r="3.3"/>'
            + h.format(cx="12.8", cy="5")
            + '<path d="M6.2 16.2 9.5 10h5.2L17.8 16.2"/>'
            + '<path d="M9.5 10 11.5 6.2"/>'
            + '<path d="M3.2 20.2 7 17"/>'
            + '<path d="M16.2 4.2 18.2 6.5 20 4.5"/>'
        ),
        "bike-gravel": (
            '<circle cx="6.2" cy="16.2" r="3.2"/>'
            '<circle cx="17.8" cy="16.2" r="3.2"/>'
            + h.format(cx="13", cy="5.2")
            + '<path d="M6.2 16.2 10.2 9.5h4.2L17.8 16.2"/>'
            + '<path d="M10.2 9.5 12.4 13.5"/>'
            + '<path d="M4 20.8h2.8M10.8 21.4h2.8M17.2 20.8h2.8"/>'
        ),
        "barbell": (
            h.format(cx="12", cy="5")
            + '<path d="M12 7.2v4.5"/>'
            + '<path d="M7.2 11.5h9.6v3.2H7.2z" fill="currentColor" stroke="none"/>'
            + '<path d="M5 10.2v5.6M19 10.2v5.6"/>'
            + '<path d="M9.5 16.8 8 21.2M14.5 16.8 16 21.2"/>'
        ),
        "kettlebell": (
            h.format(cx="12", cy="4.5")
            + '<path d="M12 6.8v2"/>'
            + '<path d="M9.2 8.8h5.6v1.3a4.7 4.7 0 1 1-5.6 0V8.8z"/>'
            + '<path d="M9.2 19.5h5.6"/>'
        ),
        "timer": (
            '<circle cx="12" cy="13.2" r="6.6"/>'
            '<path d="M12 13.2V9.4M9.2 3.5h5.6"/>'
            '<path d="M16.6 7.2 18 5.8"/>'
        ),
        "sled": (
            h.format(cx="6.5", cy="6.5")
            + '<path d="M6.5 8.6 8.5 13.5l4.5.8"/>'
            + '<path d="M8.2 13.8 6.2 20.5M11.5 14.5 10.2 20.5"/>'
            + '<path d="M12.5 14.2V8.2M16.2 14.2V8.2"/>'
            + '<path d="M11.2 14.2h6.5v5.8H5.5l-.8-2.2h7.5z"/>'
            + '<circle cx="14.5" cy="11" r="1.8"/>'
        ),
        # —— Raqueta (figure.tennis / squash / badminton / pickleball) ——
        "tennis": (
            h.format(cx="10.5", cy="4")
            + '<path d="M9.2 6.2 7.5 12.5 4.8 15.5"/>'
            + '<path d="M9.5 12.2 12.5 11.5 15.2 20.5"/>'
            + '<path d="M7.8 12.8 11.2 16.5"/>'
            + '<ellipse cx="16.5" cy="7.5" rx="3.6" ry="4.2" transform="rotate(-28 16.5 7.5)"/>'
            + '<path d="M18.8 10.8 20.5 14.5"/>'
        ),
        "padel": (
            h.format(cx="9.5", cy="4")
            + '<path d="M8.5 6.2 7 12.2 4.5 16"/>'
            + '<path d="M8.8 12 12 11.2 14.5 20.5"/>'
            + '<rect x="13.2" y="3.2" width="6.2" height="9.2" rx="1.6" transform="rotate(18 16.3 7.8)"/>'
            + '<circle cx="15.2" cy="6.5" r="0.7" fill="currentColor" stroke="none"/>'
            + '<circle cx="17.4" cy="7.2" r="0.7" fill="currentColor" stroke="none"/>'
            + '<circle cx="15.6" cy="9" r="0.7" fill="currentColor" stroke="none"/>'
        ),
        "shuttle": (
            h.format(cx="9", cy="4.2")
            + '<path d="M8 6.5 6.5 13 3.8 17"/>'
            + '<path d="M8.2 12.5 11.5 11.5 13.5 20.5"/>'
            + '<path d="M14.5 4.2 17.2 8.8h-5.4z" fill="currentColor" stroke="none"/>'
            + '<path d="M12.5 8.8 11 16.5h6.5l-1.5-7.7"/>'
        ),
        "pickleball": (
            h.format(cx="9", cy="4")
            + '<path d="M8 6.2 6.5 12.5 4 16.5"/>'
            + '<path d="M8.2 12.2 11.5 11.2 13.8 20.5"/>'
            + '<rect x="13" y="3.5" width="5.8" height="8.8" rx="1.2" transform="rotate(12 15.9 7.9)"/>'
            + '<circle cx="18.5" cy="15.5" r="2.8"/>'
            + '<circle cx="17.5" cy="14.7" r=".45" fill="currentColor" stroke="none"/>'
            + '<circle cx="19.3" cy="15" r=".45" fill="currentColor" stroke="none"/>'
            + '<circle cx="18.4" cy="16.5" r=".45" fill="currentColor" stroke="none"/>'
        ),
        "squash": (
            h.format(cx="9.5", cy="4")
            + '<path d="M8.5 6.2 7 12.5 4.5 16.2"/>'
            + '<path d="M8.8 12.2 12 11.5 14.2 20.5"/>'
            + '<ellipse cx="16.2" cy="7.2" rx="3.2" ry="3.8" transform="rotate(-22 16.2 7.2)"/>'
            + '<path d="M18.2 10.2 19.8 13.5"/>'
            + '<circle cx="19.2" cy="16.8" r="1.8"/>'
            + '<path d="M3.5 5.5v6.5h5"/>'
        ),
        # —— Agua ——
        "swim": (
            h.format(cx="8.2", cy="6.5")
            + '<path d="M9.5 8.5 14.2 11.2 11.5 14"/>'
            + '<path d="M6.5 11 3.5 12.5"/>'
            + '<path d="M3 17c2-1.7 3.7-1.7 5.4 0s3.7 1.7 5.4 0 3.7-1.7 5.4 0"/>'
            + '<path d="M3 20c2-1.7 3.7-1.7 5.4 0s3.7 1.7 5.4 0 3.7-1.7 5.4 0"/>'
        ),
        # figure.surfing / surfboard — rider on board + wave
        "surfboard": (
            h.format(cx="11", cy="5")
            + '<path d="M11 7.2 10.2 12.5 7.5 15"/>'
            + '<path d="M10.5 12.2 14.5 11.2 16.5 15.5"/>'
            + '<path d="M4.5 18c3.2-2.8 7.2-4.2 12.2-3.2 1.6 3.5 2 6.2 1.2 7.5-3.5.2-8.2-.8-11.5-2.8z"/>'
            + '<path d="M3 20.5c2.8-1 5.8-1.2 8.8-.4"/>'
        ),
        # figure.sailing-ish windsurf — board + mast sail + figure
        "windsurf": (
            h.format(cx="10", cy="6.5")
            + '<path d="M10 8.5 9.2 14.5"/>'
            + '<path d="M9.2 14.5 6.5 18.5M9.5 14.5 12 18.5"/>'
            + '<path d="M12.2 4.2v12.5"/>'
            + '<path d="M12.2 5c3.5 1.2 5.5 4.5 5.5 8.2H12.2"/>'
            + '<path d="M4 20.2 12 17.5 20 20.2"/>'
        ),
        # figure.surfing + kite overhead
        "kite": (
            h.format(cx="10", cy="10.5")
            + '<path d="M10 12.5 8.5 17.5 5.5 20"/>'
            + '<path d="M10.2 17.2 13.5 20"/>'
            + '<path d="M10 12.5 14.5 7.5"/>'
            + '<path d="M14.5 3.2 20 7.2 14.5 11.2 9 7.2z"/>'
            + '<path d="M3.5 20.5c2.5-1.2 5-1.2 7.5 0"/>'
        ),
        # figure.rower — seated kayak
        "kayak": (
            h.format(cx="12", cy="7")
            + '<path d="M12 9.2v4.5"/>'
            + '<path d="M8.5 11.5h7"/>'
            + '<path d="M9.5 13.8 7.5 18.5M14.5 13.8 16.5 18.5"/>'
            + '<path d="M2.5 16.2c3.2-2.2 6.5-2.2 9.5 0s6.3 2.2 9.5 0"/>'
            + '<ellipse cx="12" cy="15.2" rx="5.2" ry="2.2"/>'
            + '<path d="M5.5 8.5 12 11.5 18.5 8.5"/>'
        ),
        # figure.outdoor.rowing — longer shell + oars
        "rowing": (
            h.format(cx="11", cy="7.5")
            + '<path d="M11 9.5v4"/>'
            + '<path d="M8.5 12h5.5"/>'
            + '<path d="M9.2 13.5 7.5 18.5M14 13.5 15.5 18.5"/>'
            + '<path d="M3 17.5c4.2-1.5 8.5-1.5 12.8 0"/>'
            + '<path d="M5.5 17.5V13h9.5l1.8 2.8"/>'
            + '<path d="M2.5 10.5h19"/>'
            + '<path d="M4.5 10.5 2.8 7.2M19.5 10.5 21.2 7.2"/>'
        ),
        # canoe + crossed paddle (oar.2.crossed feel)
        "canoe": (
            h.format(cx="12", cy="7")
            + '<path d="M12 9v4.2"/>'
            + '<path d="M9 12.5h6"/>'
            + '<path d="M9.5 13.8 7.8 18.5M14.5 13.8 16.2 18.5"/>'
            + '<path d="M2.5 17c4.5-3.2 14.5-3.2 19 0"/>'
            + '<path d="M5.5 17 8 12.5h8l2.5 4.5"/>'
            + '<path d="M5 6.5 19 14.5M5 14.5 19 6.5"/>'
        ),
        "sailboat": (
            '<path d="M4.5 20h15"/>'
            '<path d="M6.2 20 12 16.5 17.8 20"/>'
            '<path d="M12 4v12.5"/>'
            + '<path d="M12 5c3.8 1.8 6 5.5 6 9.5H12" fill="currentColor" stroke="none"/>'
            + h.format(cx="9.5", cy="12")
        ),
        # —— Invierno (figure.skiing.downhill / snowboarding / crosscountry / ice.skating) ——
        "ski-down": (
            h.format(cx="11.5", cy="4.5")
            + '<path d="M10.5 6.8 9.2 12.2 5.5 15.5"/>'
            + '<path d="M9.8 12 13.5 11 16.5 16"/>'
            + '<path d="M12.8 8.5 16.5 6.2"/>'
            + '<path d="M4 20.5 14.5 8"/>'
            + '<path d="M8.5 20.5 19.5 8.5"/>'
        ),
        "snowboard": (
            h.format(cx="11", cy="4.5")
            + '<path d="M10.2 6.8 9.5 12.5 6.5 16"/>'
            + '<path d="M9.8 12.2 13.2 11.5 15.5 16.5"/>'
            + '<path d="M4.2 18.5c3.5-6.5 12.2-6.5 15.6 0"/>'
            + '<path d="M7.5 18.8h9"/>'
        ),
        "ski-xc": (
            h.format(cx="10.5", cy="4.2")
            + '<path d="M9.8 6.5 9 12.5 6 16.5"/>'
            + '<path d="M9.2 12.2 12.8 11.5 14.5 16.5"/>'
            + '<path d="M13.5 8.2 17.5 5.5"/>'
            + '<path d="M3 19.5h18"/>'
            + '<path d="M3 16.8h18"/>'
        ),
        "ice-skate": (
            h.format(cx="11", cy="4.2")
            + '<path d="M11 6.4v4.2"/>'
            + '<path d="M8.5 10.5h5.5l-.8 3.8H9z" fill="currentColor" stroke="none"/>'
            + '<path d="M8.8 14.5v3.2M14.2 14.5v3.2"/>'
            + '<path d="M6.5 18h11"/>'
            + '<path d="M7.2 18v2M16.5 18v2"/>'
            + '<path d="M9.2 8.5 6.5 11M13 8.5 15.5 11"/>'
        ),
        "soccer": (
            h.format(cx="12", cy="4")
            + '<path d="M12 6.2v5.5"/>'
            + '<path d="M8.5 9.5h7"/>'
            + '<path d="M9 12 6.5 20.5M15 12l2.5 8.5"/>'
            + '<circle cx="12" cy="16.5" r="3.2"/>'
        ),
        "basketball": (
            '<circle cx="12" cy="12" r="8"/>'
            '<path d="M12 4v16M4 12h16"/>'
            '<path d="M6.5 6.5c3 3 8 3 11 0M6.5 17.5c3-3 8-3 11 0"/>'
        ),
        "volleyball": (
            '<circle cx="12" cy="12" r="8"/>'
            '<path d="M4.5 10c4 1 7 4 8.5 8M12 4c1 4 4 7 8 8.5M8 5.5c2 3 3 7 2.5 11"/>'
        ),
        "football": (
            '<ellipse cx="12" cy="12" rx="9" ry="5.8"/>'
            '<path d="M8 12h8M10 10l2 2 2-2M10 14l2-2 2 2"/>'
        ),
        "baseball": (
            '<circle cx="12" cy="12" r="8"/>'
            '<path d="M7 6.5c2.5 2 2.5 9 0 11M17 6.5c-2.5 2-2.5 9 0 11"/>'
        ),
        "hockey": (
            h.format(cx="10", cy="4")
            + '<path d="M10 6.2v5"/>'
            + '<path d="M7.5 9.5h5"/>'
            + '<path d="M8.5 11.5 6 20.5M12 11.5l1.5 4.5 4 1"/>'
            + '<path d="M5 20.5h6"/>'
            + '<circle cx="17.5" cy="18.5" r="2.2" fill="currentColor" stroke="none"/>'
        ),
        "lacrosse": (
            h.format(cx="10", cy="4.2")
            + '<path d="M10 6.5v5"/>'
            + '<path d="M7.5 9.8h5.5"/>'
            + '<path d="M9 11.8 6.5 20.5"/>'
            + '<path d="M12 11.5 14.5 14"/>'
            + '<ellipse cx="15.5" cy="7" rx="3.6" ry="2.8"/>'
            + '<path d="M13.5 6h4M14 8h3.2"/>'
        ),
        "rugby": (
            '<ellipse cx="12" cy="12" rx="8" ry="5.2" transform="rotate(-32 12 12)"/>'
            '<path d="M8.2 10.2 15.8 13.8M9 13.8l6.2-3"/>'
        ),
        "boxing": (
            h.format(cx="12", cy="4")
            + '<path d="M12 6.2v3.5"/>'
            + '<path d="M7.5 9.5h9"/>'
            + '<path d="M8 9.8 5.5 14.5h4.2L8 9.8z" fill="currentColor" stroke="none"/>'
            + '<path d="M16 9.8 18.5 14.5h-4.2L16 9.8z" fill="currentColor" stroke="none"/>'
            + '<path d="M8.5 15.2 7 21M15.5 15.2 17 21"/>'
        ),
        "kickboxing": (
            h.format(cx="13.5", cy="4")
            + '<path d="M12.5 6.2 10.5 12.5 5 18.5"/>'
            + '<path d="M10.8 12.5 16.5 13.5 19.5 19"/>'
            + '<path d="M12.2 8.5h4"/>'
            + '<path d="M14.5 13.2 12 20.5"/>'
        ),
        "martial": (
            h.format(cx="12", cy="4")
            + '<path d="M12 6.2v4"/>'
            + '<path d="M6.8 9.8h10.4"/>'
            + '<path d="M7.8 9.8 4.2 15.5"/>'
            + '<path d="M16.2 9.8 20 8.2"/>'
            + '<path d="M9 14.2 12 21 15 14.2"/>'
        ),
        "wrestling": (
            h.format(cx="8", cy="4.5")
            + h.format(cx="16.2", cy="5.2")
            + '<path d="M6.2 8.8h5.2l2.2 2.2h3.8"/>'
            + '<path d="M7.2 11 5.2 20.5"/>'
            + '<path d="M15.2 12 16.8 20.5"/>'
        ),
        "dumbbell": (
            h.format(cx="12", cy="4.5")
            + '<path d="M12 6.8v3.5"/>'
            + '<path d="M8 10.2h8v3.6H8z" fill="currentColor" stroke="none"/>'
            + '<path d="M5.2 9v6M18.8 9v6"/>'
            + '<path d="M9.5 14.5 8 21M14.5 14.5 16 21"/>'
        ),
        "core": (
            h.format(cx="12", cy="4.5")
            + '<path d="M12 6.8v3"/>'
            + '<circle cx="12" cy="14.5" r="5.2"/>'
            + '<path d="M12 11.2v6.6M9.2 14.5h5.6"/>'
        ),
        "golf": (
            h.format(cx="11", cy="4")
            + '<path d="M11 6.2v8.5"/>'
            + '<path d="M8.5 9.5h5"/>'
            + '<path d="M9.5 14.8 7.5 21M13 14.8 16.5 18.5"/>'
            + '<path d="M16.5 18.5h3.5"/>'
            + '<circle cx="18.5" cy="20.2" r="1.3" fill="currentColor" stroke="none"/>'
        ),
        # figure.climbing — climber on holds/wall
        "climb": (
            '<path d="M5.5 21.5V3.5h13"/>'
            + h.format(cx="11.5", cy="6.5")
            + '<path d="M11.5 8.5 10 13.5 7.5 16"/>'
            + '<path d="M10.2 13.2 14.5 12 16.5 16.5"/>'
            + '<path d="M13.5 9.5 16 8"/>'
            + '<circle cx="8" cy="10.5" r="1.2" fill="currentColor" stroke="none"/>'
            + '<circle cx="16.5" cy="14" r="1.2" fill="currentColor" stroke="none"/>'
            + '<circle cx="9.5" cy="18" r="1.2" fill="currentColor" stroke="none"/>'
        ),
        "dance": (
            h.format(cx="12", cy="4")
            + '<path d="M12 6.2v5"/>'
            + '<path d="M8 9.5h8"/>'
            + '<path d="M9 11.5 6.5 16M15 11.5 17.5 16"/>'
            + '<path d="M9.5 21.2 12 13.5l2.5 7.7"/>'
        ),
        "pilates": (
            h.format(cx="12", cy="4.5")
            + '<path d="M12 6.8v3.5"/>'
            + '<path d="M7.5 10.5h9"/>'
            + '<path d="M8.5 20.5c1-5 2.8-7.2 3.5-7.2s2.5 2.2 3.5 7.2"/>'
        ),
        "skateboard": (
            h.format(cx="12", cy="4.5")
            + '<path d="M12 6.8v5"/>'
            + '<path d="M8.5 9.8h7"/>'
            + '<path d="M9.5 12 7.5 16.5M14.5 12 16.5 16.5"/>'
            + '<path d="M4 17.5h16l-1.5-3.8H5.5z" fill="currentColor" stroke="none"/>'
            + '<circle cx="7.2" cy="19.5" r="1.5"/>'
            + '<circle cx="16.8" cy="19.5" r="1.5"/>'
        ),
        "yoga": (
            h.format(cx="12", cy="4")
            + '<path d="M12 6.2v4"/>'
            + '<path d="M6.5 13.5h11"/>'
            + '<path d="M8.5 21.2 12 10.5l3.5 10.7"/>'
        ),
        "mobility": (
            h.format(cx="12", cy="4")
            + '<path d="M8.5 11.5c0-2 1.8-3.2 3.5-3.2s3.5 1.2 3.5 3.2-1.6 3.8-3.5 5.8"/>'
            + '<path d="M7 20.5h10"/>'
        ),
        # legacy aliases
        "bike": (
            '<circle cx="6.2" cy="16.2" r="3.3"/><circle cx="17.8" cy="16.2" r="3.3"/>'
            + h.format(cx="13.2", cy="5.2")
            + '<path d="M6.2 16.2 10.2 9.2h4.5L17.8 16.2"/>'
        ),
        "strength": (
            '<path d="M7.2 11.5h9.6v3.2H7.2z" fill="currentColor" stroke="none"/>'
            '<path d="M5 10.2v5.6M19 10.2v5.6"/>'
        ),
        "cross": '<path d="M12 3v18M6 9h12M8 15h8"/>',
        "racket": (
            h.format(cx="10.5", cy="4")
            + '<ellipse cx="16.5" cy="7.5" rx="3.6" ry="4.2" transform="rotate(-28 16.5 7.5)"/>'
            + '<path d="M18.8 10.8 20.5 14.5"/>'
        ),
        "surf": (
            h.format(cx="11", cy="5")
            + '<path d="M4.5 18c3.2-2.8 7.2-4.2 12.2-3.2 1.6 3.5 2 6.2 1.2 7.5-3.5.2-8.2-.8-11.5-2.8z"/>'
        ),
        "sail": (
            '<path d="M12 4v12.5"/><path d="M12 5c3.8 1.8 6 5.5 6 9.5H12" fill="currentColor" stroke="none"/><path d="M4.5 20h15"/>'
        ),
        "row": (
            h.format(cx="11", cy="7.5")
            + '<path d="M3 17.5c4.2-1.5 8.5-1.5 12.8 0"/><path d="M2.5 10.5h19"/>'
        ),
        "ski": '<path d="M4 20.5 14.5 8"/><path d="M8.5 20.5 19.5 8.5"/>',
        "snow": '<path d="M12 3v18M5 7l14 10M19 7 5 17"/>',
        "skate": (
            '<path d="M4 17.5h16l-1.5-3.8H5.5z" fill="currentColor" stroke="none"/>'
            '<circle cx="7.2" cy="19.5" r="1.5"/><circle cx="16.8" cy="19.5" r="1.5"/>'
        ),
        "ball": '<circle cx="12" cy="12" r="8"/><path d="M12 4v16M4 12h16"/>',
        "fight": (
            h.format(cx="12", cy="4")
            + '<path d="M8 9.8 5.5 14.5h4.2L8 9.8z" fill="currentColor" stroke="none"/>'
        ),
        "flex": (
            h.format(cx="12", cy="4.5")
            + '<path d="M8 20.5c0-4 2-6 4-6s4 2 4 6M8 12h8"/>'
        ),
        "route": (
            '<path d="M4 18c3-8 6-8 8-2s5 6 8 0"/>'
            '<circle cx="4" cy="18" r="1.5" fill="currentColor" stroke="none"/>'
            '<circle cx="20" cy="16" r="1.5" fill="currentColor" stroke="none"/>'
        ),
        "heart": '<path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2 4 4 0 0 1 7 2c0 5.5-7 10-7 10z" fill="currentColor" stroke="none"/>',
        "speak": '<path d="M4 10v4h3l4 3V7L7 10H4zM16 9a4 4 0 0 1 0 6M18.5 7a7 7 0 0 1 0 10"/>',
        "nav": '<path d="M12 3l7 18-7-3-7 3 7-18z" fill="currentColor" stroke="none"/>',
        "map": '<path d="M9 4l6 2 5-2v16l-5 2-6-2-5 2V6l5-2zM9 4v16M15 6v16"/>',
        "trophy": '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4zM7 5H4a3 3 0 0 0 3 5M17 5h3a3 3 0 0 1-3 5"/>',
        "list": '<path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/>',
        "chart": '<path d="M4 19h16M7 16V9M12 16V5M17 16v-6"/>',
        "scan": '<path d="M4 8V4h4M16 4h4v4M20 16v4h-4M8 20H4v-4M8 12h8"/>',
        "import": '<path d="M12 3v12M8 11l4 4 4-4M5 19h14"/>',
        "watch": '<rect x="7" y="3" width="10" height="18" rx="3"/><path d="M12 8v4l2 1"/>',
        "wod": '<path d="M5 19h14M7 19l2-10h6l2 10M10 9V5h4v4"/>',
        "energy": '<path d="M13 2 4 14h7l-1 8 10-14h-7l1-6z" fill="currentColor" stroke="none"/>',
        "streak": '<path d="M12 3c2 4 6 5 6 10a6 6 0 1 1-12 0c0-3 2-5 4-7" fill="currentColor" stroke="none"/>',
        "muscle": '<path d="M5 14c0-3 2-5 4-5 1 0 2 .5 3 1.5S14 9 15 9c2 0 4 2 4 5v5H5v-5z"/>',
        "book": '<path d="M4 5a3 3 0 0 1 3-2h11v16H7a3 3 0 0 0-3 3V5z"/>',
        "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 1 1 8 0v3"/>',
        "other": '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/>',
    }
    d = paths.get(kind, paths["other"])
    return (
        f'<svg class="sport-icon" viewBox="0 0 24 24" width="{size}" height="{size}" '
        f'aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.9" '
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
            f'              <a href="/casos/{esc(c["slug"])}">{sport_sf_icon(c["slug"])}'
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
            # El panel mega vive como hijo directo de .site-header (mismo cristal).
            links.append(
                f'''<li class="has-sub">
            <div class="nav-sub-trigger">
              <a href="{href}"{cur}>{esc(label)}</a>
              <button type="button" class="sub-toggle" data-sub-toggle aria-expanded="false" aria-controls="casos-sub" aria-label="Menú de actividades">▾</button>
            </div>
          </li>'''
            )
        else:
            links.append(f'<li><a href="{href}"{cur}>{esc(label)}</a></li>')
    return "\n          ".join(links)


def casos_mega_panel_html(data: dict) -> str:
    """Mega menú: hermano del .nav dentro de .site-header → hereda su cristal."""
    return f'''    <div class="nav-sub" id="casos-sub" data-sub-panel hidden>
      <div class="nav-sub-inner wrap">
        <div class="sub-head">
          <p class="eyebrow">Casos de uso por actividad</p>
          <a class="sub-all" href="/casos">Ver la página general →</a>
        </div>
        <div class="sub-in">
{casos_mega_html(data)}
        </div>
      </div>
    </div>'''


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
    home_current = ' aria-current="page"' if active == "home" else ""
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
          <li><a class="btn btn-primary btn-nav" href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="header">App Store</a></li>
        </ul>
      </nav>
      <button class="nav-toggle" type="button" data-nav-toggle aria-expanded="false" aria-controls="menu-movil" aria-label="Abrir menú">☰</button>
    </div>
{casos_mega_panel_html(data)}
    <div class="wrap nav-drawer" id="menu-movil" data-nav-drawer>
      <ul>
        <li><a href="/"{home_current}>Inicio</a></li>
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
        <li><a href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="menu_movil">Descargar en App Store</a></li>
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
    <h2 id="cookie-panel-title" tabindex="-1">Preferencias</h2>
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
  <script src="/js/site.js?v=20261112-fix3" defer></script>"""


def head_html(*, title: str, description: str, canonical: str, og_image: str, json_ld=None) -> str:
    ld = ""
    if json_ld is not None:
        ld = (
            '\n  <script type="application/ld+json">\n'
            + json.dumps(json_ld, ensure_ascii=False, indent=2)
            + "\n  </script>"
        )
    site = load_json("site.json")
    ga4 = (site.get("ga4MeasurementId") or "").strip()
    ga_attr = f' data-ga4="{esc(ga4)}"' if ga4 else ""
    # Consent Mode v2 defaults: denied until the cookie banner grants analytics.
    consent_boot = """
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){ dataLayer.push(arguments); }
    window.gtag = gtag;
    gtag('consent', 'default', {
      analytics_storage: 'denied',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      wait_for_update: 500
    });
  </script>"""
    return f"""<!DOCTYPE html>
<html lang="es"{ga_attr}>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>{esc(title)}</title>
  <meta name="description" content="{esc(description)}">
  <meta name="robots" content="index, follow">
  <meta name="google-site-verification" content="6-UNtlHZF4jvB1rbihIZBUDUNzRJFm97yz1RlW1UKww">
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
    <link rel="stylesheet" href="/css/site.css?v=20261112-fix3">
{consent_boot}{ld}
</head>
<body>
"""


def scene_panel_hero(
    kicker: str,
    title_html: str,
    lede: str,
    metrics: list[tuple[str, str]],
    *,
    image: str = "/assets/mascot-hero.png",
    image_alt: str = "Mascota de Repera",
    tone: str = "green",
    art: str = "right",
) -> str:
    """Hero en caja estilo Recuperación, con acento distinto al violeta nocturno.

    art: right | left | bottom — posición del muñeco dentro de la caja.
    """
    cards = "\n".join(
        f'          <div class="scene-metric"><strong>{esc(label)}</strong><p>{body}</p></div>'
        for label, body in metrics
    )
    art_pos = art if art in {"right", "left", "bottom"} else "right"
    img_base = image.rsplit(".", 1)[0]
    candidates = [
        (f"{img_base}-{w}.webp", w)
        for w in (320, 512, 640)
        if (ROOT / f"{img_base.lstrip('/')}-{w}.webp").exists()
    ]
    srcset_attr = ""
    if candidates:
        srcset = ", ".join(f"{path} {w}w" for path, w in candidates)
        srcset_attr = f' srcset="{esc(srcset)}" sizes="(min-width: 860px) 300px, 70vw"'
    return f"""    <section class="hero hero--panel">
      <div class="wrap">
        <div class="scene-panel scene-panel--{esc(tone)} scene-panel--split scene-panel--art-{art_pos}" data-reveal>
          <div class="scene-copy">
            <p class="eyebrow">{esc(kicker)}</p>
            <h1>{title_html}</h1>
            <p class="lede">{lede}</p>
            <div class="scene-metrics">
{cards}
            </div>
          </div>
          <div class="scene-art">
            <img src="{esc(image)}"{srcset_attr} alt="{esc(image_alt)}" width="640" height="640" loading="eager">
          </div>
        </div>
      </div>
    </section>"""


def cta_band(title: str, lede: str, *, light: bool = False) -> str:
    klass = "cta-band cta-band--light" if light else "cta-band"
    return f"""    <section class="{klass}" aria-labelledby="cta-title">
      <div class="wrap" data-reveal>
        <h2 id="cta-title">{esc(title)}</h2>
        <p class="lede">{esc(lede)}</p>
        <div class="btn-row">
          <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="cta_final">Descargar en App Store</a>
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



MODE_TITLE = {
    "gps": "Registra tus salidas de {n} con GPS | Repera",
    "fuerza": "Registra tus entrenos de {n} en tu diario | Repera",
    "wod": "Registra tus WOD de {n} en tu diario | Repera",
    "indoor": "Registra tus sesiones de {n} en tu diario | Repera",
}

MODE_H1 = {
    "gps": "{name}: ruta, ritmo y zonas en tu diario.",
    "fuerza": "{name}: series, kg y progreso en tu diario.",
    "wod": "{name}: tiempos y marcas en tu diario.",
    "indoor": "{name}: sesiones y pulso en tu diario.",
}


def render_caso(site: dict, caso: dict, modes: dict, data: dict) -> str:
    base = site["siteUrl"].rstrip("/")
    slug = caso["slug"]
    mode_key = caso.get("mode") or "indoor"
    mode = modes.get(mode_key, modes["indoor"])
    cap_file, cap_label = MODE_CAPS.get(mode_key, MODE_CAPS["indoor"])
    title = MODE_TITLE.get(mode_key, MODE_TITLE["indoor"]).format(n=caso["name"].lower())
    h1 = MODE_H1.get(mode_key, MODE_H1["indoor"]).format(name=esc(caso["name"]))
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
    # Contenido propio de la actividad primero; las funciones compartidas del
    # modo van aparte y etiquetadas, para que cada ficha diga algo distinto.
    unique_items = "".join(
        f"          <li>{esc(line)}</li>\n" for line in (caso.get("registers") or [])[:6]
    )
    shared_items = []
    for tile in mode["tiles"]:
        if isinstance(tile, dict):
            shared_items.append((tile.get("icon") or icon_for_text(tile.get("title", "")), tile["title"], tile["text"]))
        else:
            shared_items.append((icon_for_text(tile[0]), tile[0], tile[1]))
    tiles = "".join(
        f"""          <div class="record-row">
            {icon_svg(ic, 22)}
            <div>
              <h3>{esc(t)}</h3>
              <p>{esc(d)}</p>
            </div>
          </div>"""
        for ic, t, d in shared_items[:6]
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
          <h1>{h1}</h1>
          <p class="lede">{esc(caso["body"])}</p>
          <div class="btn-row">
            <a class="btn btn-primary" href="{APP_STORE}" rel="noopener noreferrer" data-track="download_click" data-track-platform="ios" data-track-cta="caso">Descargar en App Store</a>
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
          <h2>Lo que queda en tu diario en {esc(caso["name"].lower())}</h2>
        </div>
        <ul class="case-unique" data-reveal>
{unique_items}        </ul>
        <div class="case-shared" data-reveal>
          <h3>Funciones compartidas del diario</h3>
          <div class="records-stack">{tiles}
          </div>
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
{scene_panel_hero(
        "Casos de uso",
        "Cada actividad, <em>su caso de uso.</em>",
        "Los grupos son los del selector de la app. Elige un deporte: verás el muñeco, el flujo Antes/Durante/Después y lo que queda en tu diario.",
        [
            ("Antes", "Preparación y contexto según el deporte."),
            ("Durante", "Registro en vivo: GPS, series o WOD."),
            ("Después", "Lo que queda en tu diario y el progreso."),
        ],
        image="/assets/mascots/entrenamiento.webp",
        image_alt="Mascota de Repera lista para entrenar",
        tone="green",
        art="right",
    )}
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
        ("/privacy-en", "0.4", "monthly"),
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
