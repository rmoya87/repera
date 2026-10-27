# Traza eliminación Diario (Apple c5aae1cc) — destino de TODAS las funciones

Trabajo preparatorio pedido por main (27oct 12:08): NO ejecutar aún; port reversible
en rama local, sin borrar datos, validación UI pendiente (bloqueo 120s + dispositivo).

## A. Qué eliminó Apple (c5aae1cc)
- `PlanView.swift`: −729 líneas. Fuera: `DiarioSection` (Programado/Rutinas), week
  selector, weekActionsMenu (acciones destructivas de semana), diaryTopBar, compact
  tabs, scheduleContent (asignación semanal), routinesContent (biblioteca completa),
  newRoutineGreenButton, refreshAIPrograms + tarjeta de programas IA.
- `RootTabView`: pestaña "Diario" eliminada. Menú final: Inicio · Comenzar ·
  Progreso · Ejercicios (+ Center condicional).
- `StartHubSheet`: pierde la sección "Entrenos por día" (lista de plannedRoutines
  + acceso "Crear/Editar plan"). Conserva: Crear mi entreno, Apuntar series,
  Favoritos, Temporizador, Escanear pizarra/TV.
- Conserva en `PlanView.swift`: DayEditorView (editor de rutina) y su chrome.

## B. Destino Apple de cada función eliminada
| Función (Diario viejo) | Destino post-c5aae1cc |
|---|---|
| Ver plan de la semana / entrenos del día | HomeView: strip semanal + `plannedDayCard` por día seleccionado (`onStartRoutine`, borrado con diálogo: one-off elimina; plantilla "Se quitará del día, seguirá en Rutinas") |
| Añadir entreno a un día (＋) | `DayPlusSheet` desde HomeView (favoritos / temporizador / editor nuevo / escanear) |
| Quitar rutina de un día | HomeView `routinePendingDelete` → `store.removeScheduledRoutine` |
| Empezar/editar rutina planificada | push estable: RootTabView flowPath → `SessionPreviewView` (onEdit) → `DayEditorView` (mode .plan/.oneOff, embedsNavigationStack=false) |
| Biblioteca completa de Rutinas (lista) | ELIMINADA como sección. Las rutinas sobreviven como entidades; creación vía DayEditor (DayPlusSheet/StartHubSheet), edición vía preview→edit push; favoritos en FavoritesHubView |
| Copiar semana anterior / Vaciar programación | SIN DESTINO UI: `ReperaStore.copyPreviousWeek`/`clearWeeklySchedule` siguen en el store pero ninguna vista las llama tras el commit (verificado por lectura de 0a640da8) |
| Tarjeta de programas IA en Diario | SIN DESTINO en Apps/ tras el commit (ninguna vista referencia AIPrograms en 0a640da8); los programas IA llegan por la bandeja IA (AIInbox), no por Diario |
| Edición de rutina favorita | FavoritesHubView: `navigationDestination(item:)` → DayEditorView (mode .favorite), push en vez de sheet |

## C. Inventario Android (DiaryTab 302 líneas + DiaryCatalog + DayPlusSheet)
1. Strip semanal (WeekCalendarStrip) + "Tu programación": asignación semanal
   recurrente L-D ("Día libre · toca para asignar"), quitar del día, entradas
   fechadas ("Quitar de <fecha>"), "＋ Añadir otro entreno el <fecha>".
2. Sección Rutinas: biblioteca completa (`DiaryCatalog.library`), "Nueva rutina",
   editor inline, progresión, estrella favorito, borrar.
3. Menú Opciones: "Copiar semana anterior", "Vaciar programación" (con confirmación).
4. "＋ Añadir" → DayPlusSheet Android (crear / favoritos / temporizador / escanear).
5. Tarjeta de programas IA (aiPrograms) → abre programas IA.
6. `OverviewEmptyActions` (inicializar local / importar JSON con cuenta vacía) y
   `AccountSyncCard` (sync Drive / exportar / cerrar sesión). Las acciones de
   cuenta TAMBIÉN existen en Ajustes (SettingsTab, verificado en
   ReperaMobileScreen.kt); `OverviewEmptyActions` SOLO se renderiza en DiaryTab
   (pendiente confirmar si hay equivalente en Inicio).
7. Android tiene además HomeView con strip semanal propio (verificar solape real
   con DiaryTab antes de tocar nada).

## D. Destinos Android propuestos (pendiente verificación de solapes)
| Función Android | Destino propuesto | Estado |
|---|---|---|
| Plan semanal ver/empezar/quitar del día | Inicio (HomeView Android): ya tiene strip + tarjetas por día | Verificar paridad de acciones (quitar del día, one-off vs plantilla) |
| ＋ Añadir a un día | DayPlusSheet ya existe; invocarlo desde Inicio | Verificar que Inicio lo ofrece por día |
| Asignación recurrente L-D | Decisión de conservación: Apple mantiene `Routine.weekday` en el modelo | Verificar que Inicio permite asignar weekday (si no, es GAP funcional real, no solo UI) |
| Biblioteca Rutinas completa | Destino nuevo necesario (p. ej. sección en Inicio o Favoritos ampliado) | ABIERTO: Apple la eliminó; Android la usa como fuente de "asignar a día" |
| Copiar semana anterior / Vaciar | Apple los dejó sin UI (store los conserva) | Reversible: retirar del menú, conservar repository |
| Programas IA | Bandeja/menú IA existente (`programas-ia` nav) | Verificar que la entrada existe fuera de Diario |
| OverviewEmptyActions | Mover a Inicio (cuenta vacía) | ABIERTO: única renderización actual |
| AccountSyncCard | Ya duplicada en Ajustes | OK sin trabajo |

## E. Reversibilidad y datos
- NO se borran datos: rutinas, programación (weekday/scheduledDate), favoritos y
  entrenos registrados se conservan; solo cambia navegación/UI.
- Port en rama local separada desde work/tree158-reconstructed; DiaryTab.kt se
  conserva en el árbol (fuera del grafo de navegación) hasta validación, para
  rollback instantáneo.
- Validación UI/dispositivo bloqueada (compile 120s + sin dispositivo): NO
  declarar fin ni cumplir condición de push con esta pieza sin validar.

## F. Abiertos antes de ejecutar
1. Confirmar que Inicio Android cubre: quitar rutina del día, distinguir one-off
   vs plantilla en el diálogo de borrado, asignar/editar weekday recurrente,
   ＋ por día, y entrada a programas IA. Los que falten son GAPs funcionales a
   portar (DayEditor/preview push ya tienen contrapartes parciales).
2. Confirmar destino de OverviewEmptyActions.
3. Decisión documentada (no de usuario): la biblioteca Rutinas como sección
   desaparece en Apple; si Inicio/Favoritos no cubren "asignar plantilla a día",
   la navegación Android debe conservar un acceso a la biblioteca (límite más
   conservador, a reportar).
