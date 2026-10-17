# Gymbro

App nativa de entrenamiento (**iPhone + Apple Watch**), **local-first + iCloud**, UI **SwiftUI Liquid Glass** (iOS 27+).

Referencia de producto: [openGym](https://github.com/DuarteSantos8/openGym) (solo dominio/UX; no se copia código).

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Capas, targets, paquetes, datos |
| [docs/FEATURES.md](docs/FEATURES.md) | Funcionalidad por pestaña / flujo |
| [docs/BOARD_SCAN.md](docs/BOARD_SCAN.md) | Escáner de pizarra (OCR + IA + parser) |
| [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) | Checklist manual por feature |
| [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | Cómo mantener docs al día |
| [docs/ios27-modernization/](docs/ios27-modernization/) | Canvas modernización iOS 27 |
| [docs/decisions/](docs/decisions/) | ADRs (persistencia, timers, nav, HK, arte) |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes Cursor |

> **Obligatorio:** cualquier cambio de comportamiento debe actualizar estos docs (ver `MAINTENANCE.md` y la regla Cursor `update-docs-on-change`).

## Estado actual (oct 2026)

| Área | Incluye |
|------|---------|
| **Inicio** | Semana/día, métricas Salud, entrenos + externos, avatar→Ajustes, planificar / pizarra |
| **Diario** | Plan semanal, rutinas, WOD, favoritos, **copiar semana pasada** |
| **Crear** | Entreno libre, **Apuntar series**, favoritos, timer, foto pizarra/TV |
| **Progreso** | Periodo, deltas vs anterior, cardio/kcal/peso vs objetivo, heatmap, equilibrio |
| **Ejercicios** | Biblioteca + ficha (modal series, %→kg, discos, arte full-bleed) |
| **Sesión** | Series, WU/drop/rest-pause, RIR/RPE, discos, menú ⋯, Live Activity descanso |
| **Pizarra** | OCR + parser local (skip IA si ≥2 bloques) + Apple Intelligence fallback + %→kg |
| **Ajustes** | iCloud, Salud, historial, peso+objetivo, barra/discos, export/import |
| **Datos** | JSON local + iCloud Documents; CSV Strong/Hevy |
| **Watch** | Confirmar → conteo → **+1 serie** / log rápido |

## Arranque

```bash
xcodegen generate
open Gymbro.xcodeproj
# Tests dominio
cd Packages/GymbroDomain && swift test
```

Requisitos: **Xcode con SDK iOS 27**, dispositivo/simulador compatible. Apple Intelligence es opcional (fallback local en pizarra).

## Identificadores

| Qué | Valor |
|-----|--------|
| Bundle iOS | `app.gymbroapp.ios` |
| iCloud | `iCloud.app.gymbroapp.ios` |
| Team | ver `project.yml` |

## Fuera de alcance (por ahora)

- Cliente Android
- Backend social / multi-usuario
- Coach / tips con IA (sí hay Foundation Models on-device para pizarra)

## Licencia

Reimplementación Swift propia. openGym es AGPL — no se incorpora su código al binario.
