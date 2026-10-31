# Watch / Wear hub — plan + Comenzar + temporizador

Última actualización: 2026-10-31

## Objetivo

Hub de pocos toques en Apple Watch y Wear OS inspirado en Deportes de Apple Watch: plan prioritario, carrusel de actividades Comenzar, métricas en vivo (mapa solo en el teléfono al consolidar) y temporizador libre.

## Decisiones

| Tema | Decisión |
|------|---------|
| Play híbrido | Plan → fuerza/WOD actual; actividad → métricas |
| Plataformas | Watch y Wear en paralelo |
| Plan | Hoy; si no, pendiente más reciente de días pasados |
| Live | FC/kcal/duración + GPS outdoor; sin mapa en reloj |
| Carrusel | Plan → recientes/favoritos → catálogo LiveSport |
| Chrome | Mute círculo abajo izq., timer abajo der.; tap en el centro inicia (sin Play) |
| Audio off | Silencia pitidos/cuenta atrás; conserva hápticos |
| Arranque | Cuenta atrás 3 s si audio on |

## Relación con main (2026-10-30)

`origin/main` ya incluye Comenzar **phone-owned** (`WatchLiveActivitySnapshot`, controles pause/resume/finish). El hub **convive** con ese modelo:

- Si el teléfono inicia Comenzar → el reloj muestra el companion existente.
- Si el hub hace Play de un deporte con teléfono reachable → `startLive` en el teléfono.
- Si no hay teléfono → grabación autónoma en reloj (HK + GPS outdoor) y consolidate al finalizar.

## Sync

### iPhone → reloj

- `todayWorkout` / `/repera/today-plan`: plan **efectivo** (hoy \| atrasado más reciente).
- `todayDayStart`: día de sync (hoy) para frescura del contexto.
- `recentLiveSportIDs`: lista ordenada de últimos deportes Comenzar.
- `audioMuted`: preferencia de audio (`spokenGuidance` invertido).

### Reloj → iPhone

- Sesión fuerza/WOD: flujo existente (`session` + ACK).
- `startLive` / live finish: teléfono o sesión Watch con `liveSportID`, `routePoints`, HK UUID.
- Timer save: sesión con `timerDetails`.
- `setAudioMuted`: alinea preferencia de audio del teléfono.

## UI home

Icono + título del ítem; corona/rotary cambia ítem; **tocar el centro inicia**; mute abajo izq. y timer abajo der.; sin pantallas vacías «Sin plan» — si no hay plan, primer ítem del catálogo.

## Live

Pantalla métricas compacta (duración, ritmo\|velocidad, km, tramo, desnivel si aplica, FC, kcal). Controles Audio / Pausa / Finalizar. Outdoor graba GPS en el reloj; el resumen del teléfono muestra el mapa.

## Temporizador

Config Arriba / Abajo / Intervalos → UI LED → Guardar/Descartar → `timerDetails` al teléfono.
