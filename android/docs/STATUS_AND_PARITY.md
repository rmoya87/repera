# Repera Android / Wear OS — matriz de paridad verificada en código

Base: commit Apple `135c4a65c8e9061ac4f3f6bdc29f0cde3b53302a` (23/10/2026).

La implementación Android **todavía no es completa**. La rama no altera Swift, iCloud, Xcode ni Supabase.

| Función | Situación en Android | Restricción vigente |
| --- | --- | --- |
| Cuenta Google | Inicio Credential Manager, cierre de sesión | Se necesita client ID OAuth y pruebas reales |
| Google Drive personal | Carpeta appDataFolder, permiso separado, control de conflictos y backups | Pendientes E2E y revisión multi-dispositivo |
| Importación | Selector SAF JSON, solo cuenta sin datos | No fusiona ni sustituye documentos existentes |
| Historial de ejercicio/rutinas | Listas reales y búsqueda bilingüe basada en 186 aliases Swift | Faltan filtros avanzados y fichas |
| Ejecutar fuerza existente | Crea sesiones reales de bloques fuerza y aumenta syncRevision | No inicia automáticamente bloques WOD |
| Registro de series | Cantidad/peso preprescrito; Apuntar series con últimas reps/peso si existe historial | Técnicas avanzadas no expuestas en UI |
| Reanudar sesión | Desde JSON `activeSession`, incluso tras recreación de Activity | La sesión se gestiona actualmente en el teléfono |
| Finalizar | Archiva la sesión sin duplicarla y limpia estado activo | Falta reconciliación con Health Connect |
| WOD | 14 formatos, resultados y matemáticas de reloj AMRAP/EMOM/For Time/Tabata/Circuito | Falta motor de ejecución y editor de bloques |
| Watch | Wear Material 3 y lectura Data Layer de sesión activa | Falta registro offline + Health Services + reconciliación |
| Actividad/Salud | Lectura explícita de pasos y energía activa reales vía Health Connect, con permisos opt-in | Resto de mediciones y E2E pendientes |
| Business | No habilitado | OAuth Google verificado por servidor, RLS y planes |
| Compras Pro | No habilitado | Play Billing/RevenueCat e id de productos |
| OCR pizarra | No habilitado | ML Kit on-device + compatibilidad del parser |

Pruebas de regresión declaradas: `domain/src/test` para reloj, WOD, presets y
conflictos; `mobile/src/androidTest` para persistencia e identidad de sesiones.
Deben ejecutarse antes de dar la funcionalidad por probada.

CI anterior: GitHub Actions ha marcado fallos con `runner_id=0` y cero pasos;
no constituye evidencia de fallo de código ni de éxito. Se requiere runner
operativo + Gradle 9.6, SDK 37 y emuladores/dispositivos.

## Catálogo y primera cuenta

El asset `mobile/src/main/assets/catalog_seed.json` contiene **196 ejercicios**
extraídos directamente de `CatalogEnrichment`, `CatalogHalterofilia`,
`CatalogGimnasia` y `CatalogCrossFit` de Swift en `main`, sin ejercicios
ficticios añadidos. Se aplican 189 descripciones y 189 instrucciones
localizadas del diccionario `CatalogSpanish`; el resto conserva el texto
fuente a falta de portar el traductor de frases. Los ID generados son estables
por nombre dentro de Android, pero **no son los UUID aleatorios de iOS**:
el traspaso del historial se hace importando los UUID originales del JSON
exportado, no emparejando UUID generados.

`exercise_search_aliases.json` contiene 186 parejas exactas procedentes
de `ExerciseSearch.bilingualPhrases`. Búsqueda prioriza nombre exacto,
alias inglés/español y coincidencia parcial. La selección de ejercicio
inicia Apuntar series; un bloque WOD no puede transformarse de manera tácita.

No se han ejecutado tests ni compilaciones completas: el CI depende de
la disponibilidad de runners de GitHub, que en las anteriores ejecuciones
figuraban sin runner y sin pasos.

## Refuerzo de seguridad y comportamiento (segunda revisión)

- Catálogo nativo original **196 movimientos** y alias bilingües **186**; los
  ejercicios que requieren registro de tiempo, Cal, metros o déficit tienen
  su clasificación, pero el editor avanzado no está habilitado hasta su port.
- Las rutinas con bloques WOD no se ejecutan mediante el motor de fuerza. No
  se convierten resultados de bloque en series ficticias.
- La nube conserva copias anteriores y bloquea historiales independientes
  (entrenamientos y rutinas con IDs exclusivos en ambas versiones, o sesiones
  activas incompatibles).
- Una cuenta recién inicializada con el catálogo se identifica como estado
  vacío de revisión 0 y fecha antigua. La primera sincronización prioriza el
  historial remoto real aunque el backup remoto sea legacy.
- Navegación Android usa iconografía Material y animación al actualizar
  la sesión activa. Wear muestra ejercicio y próxima serie prescrita con
  datos reales recibidos del teléfono.
- WodClock dispone de pruebas de AMRAP, For Time, EMOM, Tabata y Circuito
  basadas en `WatchSessionHub.swift`. Todavía no gobierna la ejecución
  de WOD en la interfaz.

**Advertencia:** pruebas escritas != pruebas ejecutadas. Requiere SDK 37,
Gradle 9.6, JDK 17, credenciales OAuth reales, emulador y reloj. Los workflows
de GitHub disponibles no están asignando runners.

## Salud Android (lectura observada)

Se utiliza `androidx.health.connect:connect-client:1.1.0` (estable), únicamente
con permisos de lectura `READ_STEPS` y `READ_ACTIVE_CALORIES_BURNED`.
La vista Inicio muestra las lecturas agregadas del día si existen y «—»
en ausencia de datos o permiso. Los datos de Salud **no** se vuelcan al
JSON de Repera ni a Drive/Supabase; no se generan kcal por inferencia.
El permiso se solicita sólo cuando el usuario pulsa conectar; se ofrece
explicación en la pantalla de gestión de permisos. Quedan pendientes
Health Services del reloj, operaciones de escritura y pruebas E2E.
