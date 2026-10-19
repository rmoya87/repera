# Repera

App nativa de entrenamiento (**iPhone + Apple Watch**), **local-first + iCloud**, Sign in with Apple, UI **SwiftUI Liquid Glass** (iOS 27+).

Referencia de producto: [openGym](https://github.com/DuarteSantos8/openGym) (solo dominio/UX; no se copia código).

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Capas, targets, paquetes, datos |
| [docs/FEATURES.md](docs/FEATURES.md) | Funcionalidad por pestaña / flujo |
| [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Observation, caches, Home/HK, thumbs |
| [docs/BOARD_SCAN.md](docs/BOARD_SCAN.md) | Escáner de pizarra (OCR + IA + parser) |
| [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) | Checklist manual por feature |
| [docs/MONETIZATION.md](docs/MONETIZATION.md) | Freemium, RevenueCat, límites Gratis/Pro |
| [web/](web/) | Sitio estático (producto, precios, privacidad, términos, FAQ) |
| [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | Cómo mantener docs al día |
| [docs/ios27-modernization/](docs/ios27-modernization/) | Canvas modernización iOS 27 |
| [docs/decisions/](docs/decisions/) | ADRs (persistencia, timers, nav, HK, arte) |
| [AGENTS.md](AGENTS.md) | Instrucciones para agentes Cursor |
| [docs/business/PLAN_MAESTRO.md](docs/business/PLAN_MAESTRO.md) | Plataforma profesional, seguridad, fases y seguimiento |

> **Obligatorio:** cualquier cambio de comportamiento debe actualizar estos docs (ver `MAINTENANCE.md` y la regla Cursor `update-docs-on-change`).

## Estado actual (oct 2026)

| Área | Incluye |
|------|---------|
| **Inicio** | Semana/día, métricas Salud, entrenos + externos, avatar→Ajustes, planificar / pizarra |
| **Diario** | Vista de planificación del entrenador (sin sincronización todavía) + planificación personal/rutinas conservadas |
| **Center** | Vista nativa de centros y clases con estado vacío real (reservas no conectadas aún) |
| **Crear desde Inicio** | Botón +: entreno libre, **Apuntar series**, favoritos, timer, foto pizarra/TV (sin pestaña propia) |
| **Progreso** | Gratis: esta semana + teaser; Pro: periodos, deltas, cardio/kcal/peso, heatmap, equilibrio |
| **Ejercicios** | Biblioteca + ficha; evolución completa = Pro (Gratis: última sesión + PR) |
| **Sesión** | Series, WU/drop/rest-pause, RIR/RPE, discos, menú ⋯, Live Activity descanso |
| **Pizarra** | OCR lite; Gratis 4 escaneos/mes; Pro ilimitados |
| **Onboarding** | Sign in with Apple obligatorio → Gratis/Pro → permisos (notif, Salud, ubicación) |
| **Ajustes** | Cuenta Apple, Pro / restaurar, iCloud, permisos/Salud, historial, peso, export/import |
| **Datos** | JSON local + iCloud Documents; CSV Strong/Hevy (sin entitlement en el JSON) |
| **Watch** | Confirmar → conteo → **+1 serie** / log rápido (sin límites Pro en v1) |
| **Monetización** | StoreKit + RevenueCat; ver [docs/MONETIZATION.md](docs/MONETIZATION.md) |

## Arranque rápido en Mac (doble clic)

- [`Repera-Business.command`](Repera-Business.command): ejecuta localmente la demostración profesional en navegador; requiere Python 3 y permanece abierta una ventana Terminal. Los datos son ficticios.
- [`Repera-iOS.command`](Repera-iOS.command): intenta compilar y lanzar la app en Simulator; requiere macOS, Xcode con iOS 27, XcodeGen y un simulador compatible.
- Ambos lanzadores están en la raíz del repositorio; si clonas por Git, se conserva el permiso de ejecución. No se ha generado todavía una aplicación macOS firmada ni un paquete iOS listo para distribución.

**Estado:** el flujo deportista↔entrenador↔centro no está conectado completamente y el CI sigue fallando; `main` no debe recibir la rama Business sin revisión y pruebas.

## Arranque

```bash
xcodegen generate
open Repera.xcodeproj
# Tests dominio
cd Packages/ReperaDomain && swift test
# Web marketing (local)
cd web && python3 -m http.server 8080
```

Sitio público: [repera.app](https://repera.app) — `cd web && ./pack-ionos.sh` y extraer el zip en IONOS `htdocs`; ver [web/README.md](web/README.md).

Requisitos: **Xcode con SDK iOS 27**, dispositivo/simulador compatible. Apple Intelligence es opcional (fallback local en pizarra).

Cold start: Splash nativo y pantalla de espera usan la misma UIImageView UIKit en modo AspectFit y fijada a los cuatro bordes; evita saltos de escala, y una build nueva invalida la captura antigua de iOS. Store en shell vacío hasta hidratar disco; `Catalog.prewarm()` fuera del MainActor. En Debug+Simulador el dylib (~20 MB) puede retrasar el process start; medir en Release/dispositivo.

## Identificadores

| Qué | Valor |
|-----|--------|
| Bundle iOS | `com.app.repera` |
| iCloud | `iCloud.com.app.repera` |
| Team | ver `project.yml` |
| RevenueCat API key | `RevenueCatPublicAPIKey` en Info.plist (pública `appl_…`) |
| Productos | `repera_pro_monthly` / `repera_pro_annual` · entitlement `pro` |

## No integrados aún en las apps

- Android nativo: planificado, no implementado.
- Backend Supabase de Repera: primera migración segura de identidad/organizaciones/RLS aplicada el 2026-10-19; **sin integración de login con iOS ni panel profesional todavía**. Ver [docs/business/ESTADO_DESARROLLO.md](docs/business/ESTADO_DESARROLLO.md).
- Coach / tips con IA (sí hay Foundation Models on-device para pizarra)
- SDK RevenueCat en Apple Watch

## Licencia

Reimplementación Swift propia. openGym es AGPL — no se incorpora su código al binario.
