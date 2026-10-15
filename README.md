# Gymbro

App nativa de entrenamiento (**iPhone + Apple Watch**), **local-first + iCloud**, UI **SwiftUI Liquid Glass** (iOS 26+).

Referencia de producto: [openGym](https://github.com/DuarteSantos8/openGym) (clone en `reference/openGym`).

## Estado: v1.0 local cerrado

| Área | Incluye |
|------|---------|
| Inicio | Día de hoy, peso, racha; + para planificar o foto pizarra/TV |
| Plan | Rutinas que tú creas (sin plan demo) |
| Biblioteca | ~190 ejercicios seed (gym + CrossFit + halterofilia + gimnasia) + custom |
| Sesión | Series normales, WU, drop, rest-pause, RIR/RPE, discos, Watch |
| Progresión | Off / lineal / doble / Greyskull / triple |
| Stats | Volumen, PRs, mapa muscular, peso |
| Coach | Insights locales por reglas (sin API) |
| Datos | JSON local + iCloud Documents; export/import; CSV Strong/Hevy |
| Watch | Confirmar ejercicio → conteo auto/manual → siguiente |

## Arranque

```bash
xcodegen generate
open Gymbro.xcodeproj
cd Packages/GymbroDomain && swift test
```

## iCloud

Contenedor `iCloud.app.gymbroapp.ios`. Misma Apple ID → recuperación tras reinstalar. Sync al abrir/foreground. Bundle id: `app.gymbroapp.ios`.

## Fuera de v1.0 (siguiente producto)

- **Android** (otro cliente; mismo diseño de datos cuando haya backend)
- **Backend social / Supabase** (cuando haya org Free o presupuesto Pro)
- **AI coach con LLM** (el coach actual es reglas locales)

## Licencia

Reimplementación Swift; openGym es AGPL — no se copia su código al binario.
