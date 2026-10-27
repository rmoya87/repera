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
   `AccountSyncCard` (sync Drive / exportar / cerrar sesión). VERIFICADO: ambas
   se renderizan TAMBIÉN en Inicio (HomeTab.kt líneas 332-334) y la cuenta en
   Ajustes; DiaryTab es una segunda instancia, no la única. Sin acción.

## C2. Inicio (HomeTab) verificado — qué cubre ya (27oct 12:14)
- Strip semanal + rutinas del día (fechadas + recurrentes por weekday) ✓
- "Ver plan y empezar" → SessionPreviewSheet con Empezar / Editar / Eliminar
  (removeScheduledRoutine) ✓ (equivalente a plannedDayCard + preview Apple)
- "Añadir nuevo entrenamiento" → navega a Crear (NO es el DayPlusSheet por día
  de Apple: no lleva la fecha seleccionada ni ofrece favoritos/temporizador/
  escanear inline) — PARCIAL
- OverviewEmptyActions + AccountSyncCard ✓
- NO cubre (GAPs reales antes de retirar Diario):
  a) Asignar rutina a weekday recurrente ni a fecha (diálogos assigningDay/
     assigningDate de DiaryTab; Inicio no tiene onAssign*).
  b) "＋ Añadir otro entreno el <fecha>" (segundo entreno fechado del mismo día).
  c) Tarjeta de programas IA (sin parámetro aiPrograms en HomeTab).
  d) Biblioteca completa de Rutinas (lista) — sin ella no hay UI para asignar.
  e) Copiar semana anterior / Vaciar programación (Apple los dejó sin UI;
     retirar es PARIDAD, repository los conserva).

## D. Destinos Android propuestos (pendiente verificación de solapes)
| Función Android | Destino propuesto | Estado |
|---|---|---|
| Plan semanal ver/empezar/quitar del día | Inicio YA lo cubre (strip + preview + remove) | ✓ verificado 12:14 |
| ＋ Añadir a un día | DayPlusSheet existe (en DiaryTab); llevarlo a Inicio con la fecha seleccionada | POR PORTAR a Inicio |
| Asignación recurrente L-D / a fecha | Portar diálogos assigningDay/assigningDate a Inicio | POR PORTAR a Inicio (sin esto retirar Diario pierde función) |
| Biblioteca Rutinas completa | Conservar acceso (Inicio o Favoritos ampliado) | DECISIÓN CONSERVADORA documentada: Apple la eliminó, pero la asignación a día la necesita; mantener acceso hasta que la asignación no dependa de ella |
| Copiar semana anterior / Vaciar | Retirar del menú (paridad Apple), conservar repository | POR PORTAR (reversible) |
| Programas IA | Entrada `programas-ia` en nav + tarjeta; llevar tarjeta a Inicio o dejar solo acceso por Ajustes/menú IA | POR DECIDIR en el port |
| OverviewEmptyActions | Ya duplicada en Inicio | ✓ verificado 12:14 |
| AccountSyncCard | Ya duplicada en Inicio y Ajustes | ✓ verificado 12:14 |

## E. Reversibilidad y datos
- NO se borran datos: rutinas, programación (weekday/scheduledDate), favoritos y
  entrenos registrados se conservan; solo cambia navegación/UI.
- Port en rama local separada desde work/tree158-reconstructed; DiaryTab.kt se
  conserva en el árbol (fuera del grafo de navegación) hasta validación, para
  rollback instantáneo.
- Validación UI/dispositivo bloqueada (compile 120s + sin dispositivo): NO
  declarar fin ni cumplir condición de push con esta pieza sin validar.

## F. Plan de ejecución (rama local, reversible, próxima fase)
1. Portar a Inicio: DayPlusSheet por día seleccionado, diálogos de asignación
   (weekday recurrente + fecha + "＋ otro entreno"), tarjeta programas IA.
2. Conservar acceso a la biblioteca Rutinas (decisión conservadora, §D).
3. Retirar "Copiar semana anterior"/"Vaciar" del menú (repository intacto).
4. Sacar "diario" del grafo de navegación conservando DiaryTab.kt en el árbol
   (rollback instantáneo; sin borrar datos: rutinas, weekday, fechadas,
   favoritos e historial intactos).
5. Validación UI/dispositivo bloqueada: el cambio queda como WIP explícito; NO
   cuenta para declarar fin ni para la condición de push.
Resueltos: destino de OverviewEmptyActions/AccountSyncCard (Inicio/Ajustes ✓);
diálogo de borrado Apple (one-off elimina, plantilla quita del día) — verificar
que removeScheduledRoutine Android distingue ambos casos al portar el preview.
