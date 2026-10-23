# Repera Android / Wear OS — matriz de paridad verificada en código

Base: commit Apple `135c4a65c8e9061ac4f3f6bdc29f0cde3b53302a` (23/10/2026).

La implementación Android **todavía no es completa**. La rama no altera Swift, iCloud, Xcode ni Supabase.

| Función | Situación en Android | Restricción vigente |
| --- | --- | --- |
| Cuenta Google | Inicio Credential Manager, cierre de sesión | Se necesita client ID OAuth y pruebas reales |
| Google Drive personal | Carpeta appDataFolder, permiso separado, control de conflictos y backups | Pendientes E2E y revisión multi-dispositivo |
| Importación | Selector SAF JSON, solo cuenta sin datos | No fusiona ni sustituye documentos existentes |
| Historial de ejercicio/rutinas | Listas desde estado real, búsqueda básica | No todas las fichas y filtros |
| Ejecutar fuerza existente | Crea sesión real según rutina de bloques fuerza; cuenta revision | No inicia automáticamente bloques WOD |
| Registro de series | Cantidad/peso preprescrito por serie, guardado atómico; no crea series ficticias | Técnicas avanzadas no expuestas en UI |
| Reanudar sesión | Desde JSON `activeSession`, incluso tras recreación de Activity | La sesión se gestiona actualmente en el teléfono |
| Finalizar | Archiva la sesión sin duplicarla y limpia estado activo | Falta reconciliación con Health Connect |
| WOD | 14 formatos y clasificación de score modelados en módulo dominio | Falta motor de ejecución y editor |
| Watch | Wear Material 3 y lectura Data Layer de sesión activa | Falta registro offline + Health Services + reconciliación |
| Progreso/Salud | Sólo datos locales reales, sin inventar kcal | Health Connect y métricas pendientes |
| Business | No habilitado | OAuth Google verificado por servidor, RLS y planes |
| Compras Pro | No habilitado | Play Billing/RevenueCat e id de productos |
| OCR pizarra | No habilitado | ML Kit on-device + compatibilidad del parser |

Pruebas de regresión declaradas: `domain/src/test` para reloj, WOD, presets y
conflictos; `mobile/src/androidTest` para persistencia e identidad de sesiones.
Deben ejecutarse antes de dar la funcionalidad por probada.

CI anterior: GitHub Actions ha marcado fallos con `runner_id=0` y cero pasos;
no constituye evidencia de fallo de código ni de éxito. Se requiere runner
operativo + Gradle 9.6, SDK 37 y emuladores/dispositivos.
