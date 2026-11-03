# Condiciones por deporte (marea / nieve) — diseño

Última actualización: 2026-10-31

## Objetivo
- Watch: durante live, bloque «Condiciones» al hacer scroll hacia abajo.
- iPhone: misma info en revisión Guardar y en detalle finalizado.
- Implementación actual (03/11): WeatherKit Apple (temperatura, humedad, viento, nevada por hora) + Open-Meteo Marine/Forecast (marea, oleaje y espesor de nieve). Una app con suscripciones debe tener licencia comercial Open-Meteo; ver `docs/WEATHER_SOURCES.md`.
- Snapshot al finalizar para historial estable. Marea = modelo orientativo (no navegación).

## Familias
- `water`: surf, kite, windsurf, vela, kayak, remo, canoa (+ natación con coords).
- `snow`: esquí, snowboard, fondo.
- `outdoor`: resto GPS outdoor (temp/viento ya cubiertos; opcional lluvia).
- `none`: indoor / sin coords.

## Datos Open-Meteo
- Marine: `sea_level_height_msl`, `wave_height` → tendencia marea + oleaje.
- Forecast: `snow_depth` exclusivamente en iOS/Watch; `snowfall`, temperatura y viento vienen de WeatherKit. Android permanece Open-Meteo.

## Sync
- Companion: iPhone publica snapshot en contexto live → Watch.
- Watch-owned: Watch consulta WeatherKit (atmósfera/nieve horaria) y Open-Meteo (marea/oleaje/espesor) con última coordenada GPS.
