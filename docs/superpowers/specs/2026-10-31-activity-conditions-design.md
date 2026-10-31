# Condiciones por deporte (marea / nieve) — diseño

Última actualización: 2026-10-31

## Objetivo
- Watch: durante live, bloque «Condiciones» al hacer scroll hacia abajo.
- iPhone: misma info en revisión Guardar y en detalle finalizado.
- Gratis: WeatherKit (base) + Open-Meteo Marine/Forecast (marea, oleaje, nieve). Sin API keys de pago.
- Snapshot al finalizar para historial estable. Marea = modelo orientativo (no navegación).

## Familias
- `water`: surf, kite, windsurf, vela, kayak, remo, canoa (+ natación con coords).
- `snow`: esquí, snowboard, fondo.
- `outdoor`: resto GPS outdoor (temp/viento ya cubiertos; opcional lluvia).
- `none`: indoor / sin coords.

## Datos Open-Meteo
- Marine: `sea_level_height_msl`, `wave_height` → tendencia marea + oleaje.
- Forecast/Archive: `snowfall`, `snow_depth`, temp, viento (paridad Android).

## Sync
- Companion: iPhone publica snapshot en contexto live → Watch.
- Watch-owned: Watch consulta Open-Meteo con última coordenada GPS.
