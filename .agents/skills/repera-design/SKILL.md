---
name: repera-design
description: >-
  Filosofía de diseño de producto Repera (hub estilo Apple Salud, chips,
  insights narrativos, Liquid Glass, métricas propias). Usar al proponer,
  rediseñar o pulir UI/UX de Progreso, métricas, dashboards o pantallas de
  datos en iOS/Android; complementar emil-design-eng y apple-design.
---

# Repera Design — filosofía de producto

Referencia viva validada con el rediseño de Progreso (2026-11). Complementa
`emil-design-eng` y `apple-design`; no las sustituye. Detalle de métricas y
evidencia: `docs/PROGRESS_DATA_SOURCES.md`. Componentes: `ProgressCategoryChips`
(iOS) / `ProgressCategoryChips.kt` (Android).

## Idea central

Tomar el **lenguaje de Apple Salud** (chips temáticos, insights narrativos,
ventanas fijas, jerarquía héroe → grid → semana → largo plazo) y aplicarlo a
**métricas propias de Repera** (entreno + Salud/Health Connect), sin copiar
marca, anillos Activity ni iconografía de Apple Salud.

La UI debe sentirse **nativa, clara y visual**: menos tablas densas, más
tarjeta insight con frase + número + mini viz.

## Navegación y tiempo

- Preferir **chips horizontales temáticos** frente a segmentados genéricos
  (Entreno / Actividad / Recuperación).
- **Sin calendario de periodo global** en hubs de datos. Ventanas fijas por
  bloque (hoy / última noche / **Últimos 7 días** / este mes). No etiquetar
  la ventana móvil de 7 días como «Esta semana» (no es lun–dom).
- **Gratis:** momento + Últimos 7 días (y teasers «Ejemplo») + resumen
  **Este mes** al final de Forma/Corazón/Recuperación/Deportes.
  **Pro:** mes embebido + «A largo plazo» real. Selectores D/S/M solo en
  detalle, no en el hub.
- Recuperación: icono **luna** + acento azul oscuro violáceo (noche).
  Deportes: acento **teal** (no reutilizar el morado de Recuperación).
- Chevron / affordance de navegación **solo** si hay destino real. Nunca
  chevron muerto.

## Chips (patrón canónico)

- Layout: **icono + nombre en la misma fila**; valor clave **debajo**.
- Seleccionado: fondo **verde sólido Repera**, icono/texto/valor **negros**,
  **sin outline**.
- No seleccionado (iOS): **Liquid Glass**; Android: surface Material
  equivalente. Fila de chips con **fondo transparente** (sin franja gris).
- Iconos **propios** (SF Symbol / Material alineados a Repera). Prohibido:
  anillos Activity, iconos del set Salud de Apple.

## Cards y jerarquía visual

Plantilla por categoría (adaptar, no forzar vacío):

1. **Héroe** — número/estado + frase narrativa corta.
2. **Cuadrícula glance** — 2×2 (o similar) de métricas con contexto
   (media / típico / —).
3. **Insights de periodo** («Últimos 7 días» / mes) — cards estilo Salud.
4. **A largo plazo** — solo Pro (tendencias, consistencia, mapas de días).

Card insight (`ProgressInsightCard` y equivalentes):

- Icono + título **tintados** de la métrica.
- Narrativa en lenguaje humano (no jerga de implementación).
- Héroe numérico grande + mini viz (`ProgressMiniRangeBars`,
  `ProgressConsistencyDots`, sparkline, etc.).
- Fondos = tokens de app (`OG.bg` / `surface` / Material `background`).
  **Nunca** tintar la pantalla entera de verde.

## Contenido y evidencia

- Priorizar **métricas propietarias** que combinen entreno Repera + sensores
  (carga, progresión, recuperación FC, consistencia, estímulo deduplicado).
- Sin dato real: «—» o estado «aprendiendo»; **nunca** inventar ceros
  fisiológicos.
- Freemium: teaser visual honesto («Ejemplo»), no mentir el valor Pro.

## Plataforma

- Misma IA y paridad funcional iOS ↔ Android; componentes nativos de cada SO.
- Reutilizar `OG*`, Theme y chips/cards existentes antes de inventar otro
  lenguaje visual.
- Movimiento solo si aclara feedback; sin decoración. Skills de animación
  aparte cuando haga falta.
- **Primera entrada a hubs / pantallas pesadas:** seguir la regla
  obligatoria en `AGENTS.md` → *Convenciones UI → Primera entrada / carga
  de páginas* (gate ~160 ms tras contenido estable, charts ~220 ms después,
  morph barato, sin IO en el pico del fade). Contrato
  `tests/test_metric_reveal_contract.py`.

## Checklist rápido

- [ ] ¿Se entiende como Salud (chips + insight) sin parecer un clon de Apple?
- [ ] ¿Hay métrica Repera, no solo un dump de HealthKit/HC?
- [ ] ¿Chip seleccionado = verde + negro; barra transparente; glass en iOS?
- [ ] ¿Sin calendario global ni chevron vacío?
- [ ] ¿Fondos de app, no tinte verde de pantalla?
- [ ] ¿Paridad pensada en la otra plataforma móvil?
- [ ] ¿Primera visita: revelado/charts/IO fuera del pico de la transición?
