## Verificación del seguimiento direccional del mapa (2026-10-29)

- [ ] En iOS y Android, en Caminata/Carrera con GPS fiable, mantener 2D: el norte no queda fijo arriba; el mapa gira para que la flecha apunte en la dirección de desplazamiento. La cámara sigue el pin sin desplazarlo en 2D.
- [ ] Pasar a 3D y comprobar rumbo coincidente, inclinación y encuadre por delante de la marcha; al detenerse o perder un único fix no se debe girar bruscamente al norte ni inventar dirección.
- [ ] Arrastrar el mapa durante más de cinco segundos, hacer zoom y rotarlo en ambos modos: **nunca recentrar mientras sigue moviéndose**; esperar cinco segundos completos después de soltar/dejar de mover el mapa para retornar al puntero y su rumbo actual.
- [ ] Volver a tocar el mapa antes de que termine la espera: el contador vuelve a cinco segundos. Probar un gesto que deje la cámara a menos de 65 m del GPS, y llegada de nuevos fixes durante la espera.
- [ ] Pulsar «Centrar en mi posición» durante la espera: volver inmediatamente; probar cambio 2D↔3D y salir/entrar en la pantalla sin un recenter tardío. Con GPS no disponible, no inventar un pin.
- [ ] Validar retrato, apaisado, iPhone DUO/iPad y Android; comprobar que el mapa de rutas guardadas no hereda el seguimiento automático de «Comenzar».

## Persistencia de ediciones en Play y OCR (2026-10-26)

## Validación integral de registros y sincronización (26/10/2026)

## Validación física pendiente: Comenzar, audio y autenticación (26/10/2026)

- [ ] Caducar JWT con refresh token válido: debe renovarse solo al regresar del segundo plano y al pulsar sincronización. Revocar refresh token: abrir Bienvenido sin perder JSON/iCloud. Simular modo avión con credenciales previas: permitir acceder al histórico offline sin logout. Reintentar al recuperar red.
- [ ] Escuchar Spotify/Apple Music con el iPhone bloqueado, iniciar Caminata en Comenzar y superar 1 km: pausar/interrumpir el audio de la otra aplicación, locutar «Kilómetro 1 completado» y tiempo/velocidad, reanudar el audio externo al terminar; no debe mostrarse aviso push de km.
- [ ] Probar Comenzar con ruta terrestre y acuática: los colores comienzan en azul y verde respectivamente, pasan por amarillo, naranja y rojo. Tocar el mapa en resumen y detalle: abrir pantalla completa, desplazar y pellizcar para zoom, cerrar por X.
- [ ] En resumen de caminata con 1,11 km/15:35 comprobar los tiles iniciales, mapa inmediato sin título Recorrido registrado y Parciales con ritmo/velocidad medios antes de lista. Valores siempre calculados con la distancia y tiempo real (no desde un parcial incompleto).
- [ ] Guardar Comenzar inmediatamente al abrir el resumen, antes de que acabe de cargar Apple Salud: detectar un HKWorkout externo ya existente y persistir el UUID y FC/kcal medidas; no escribir un duplicado en Salud.
- [ ] Guardar dos sesiones para el 26 de octubre desde Comenzar e Inicio. Ver en Inicio/Historial/Progreso dos UUID distintos, carga muscular, minutos cardio y progreso del deporte; no confundir marcas de ruta con récords e1RM.
- [ ] Revisar el icono nativo de Repera que muestra iOS en avisos generales tras actualizar la aplicación desde TestFlight; no existe un icono configurable por cada UNNotification.



- [ ] Progreso: CrossFit, boxeo, elíptica, raqueta y equipo cuentan minutos de cardio registrados; yoga, movilidad, Pilates y core no se convierten falsamente en cardio.


- [ ] Crear dos sesiones A y B para la misma fecha desde Inicio, Diario y OCR: aparecen separadas. Borrado por swipe de B no afecta A.
- [ ] Realizar y finalizar A y luego B; ambas aparecen en Inicio/Historial y alimentan correctamente volumen, fuerza, cardio y Equilibrio de Progreso.
- [ ] Copiar semana con dos sesiones en la misma fecha: copiar ambas si día destino estaba libre antes de empezar la operación.
- [ ] En Play, introducir y corregir peso/reps/RIR, series de máquina Cal/met, movilidad y bloques AMRAP/EMOM/For Time; eliminar primera, intermedia y última serie con swipe y volver a añadir. No recontar ni cambiar IDs de otras series.
- [ ] Comenzar: registrar deportes GPS/no GPS, importar Apple Watch por Salud, mostrar valores medidos de pulso, calorías, tiempo y ruta cuando existan; evitar duplicar la carga por UUID/solape.
- [ ] Cuenta: guardar local en modo avión; recuperar red, Sincronizar ahora y comprobar en athlete_workout_mirror el UUID/payload/series. Sin credenciales válidas ha de mostrar error y no prometer sincronización.
- [ ] Validación en Xcode 27 y dispositivo TestFlight con watchOS 27: los contratos de fuente/servidor no sustituyen prueba de sensores ni ejecución real.

- [ ] Escanear una pizarra con fuerza + WOD, programarla, editar kg/reps/RIR y terminar: los valores se guardan sin check por serie, y los resultados en Historial y Progreso.
- [ ] Editar una serie con teclado abierto y pulsar Finalizar entreno: los últimos datos se guardan sin ✓ por serie.
- [ ] Abrir «Editar entreno» desde Play, añadir/quitar ejercicio o bloque, reordenar, añadir/quitar series o cambiar pesos, pulsar Guardar y terminar: al reabrir Historial aparecen exactamente esos cambios; no reaparece el plan anterior. Con rutina programada existente, la plantilla también se actualiza; con escaneo efímero solo se actualiza la sesión.
- [ ] Repetir dos veces el mismo ejercicio en un bloque, registrar un peso en cada aparición, reordenar uno y añadir una tercera aparición: cada resultado queda con el elemento de origen por su ID; la nueva aparición no hereda datos registrados ajenos.
- [ ] Con WOD EMOM/Tabata/RFT, cambiar repeticiones/cargas o añadir series: se preservan `explicitPlannedSets`, el tiempo y el resultado global del bloque; no se convierten series pendientes en resultados ni se pierden pausas/rest.
- [ ] Cerrar Play, volver a abrir con sesión activa y reiniciar la app: las modificaciones persisten en almacenamiento local/iCloud y la estructura se reproduce de forma consistente en Apple Watch. Tras finalizar, probar la relectura por JSON.
- [ ] Verificar que precargar pesos sugeridos de una sesión anterior sin tocarlos NO altera el plan; solo las ediciones reales del usuario se guardan.
- [ ] Dynamic Type y VoiceOver: borrar cualquier serie en Play con swipe a la izquierda; no aparece el botón menos fijo y existe acción accesible «Eliminar serie».

# Guía de pruebas — Repera

Última actualización: 2026-10-28 (Play ownership Apple-parity; sesiones/deportes)

Checklist manual por feature. Preferible dispositivo real para Live Activity y Watch.

## Sincronización invisible nativa iOS 27 (25/10/2026)

- [ ] Abrir/Reabrir Repera sin conexión: Inicio y la biblioteca aparecen con caché local, sin esperar al backend ni mostrar indicadores.
- [ ] En primer plano con cuenta conectada: consultar solo la revisión; si coincide, no descargar ejercicios ni reconstruir secciones.
- [ ] Simular `BGAppRefresh`: guardar nuevas revisiones en Application Support sin hidratar o modificar el historial personal/iCloud durante ejecución headless.
- [ ] Al volver a primer plano: aplicar una actualización descargada por `BGAppRefresh` y preservar favoritos, UUID, rutinas y récords sin saltos visuales.
- [ ] Verificar en la app instalada que `BGTaskSchedulerPermittedIdentifiers` y `UIBackgroundModes=fetch` están en el Info.plist generado y que el sistema puede registrar la tarea.
- [ ] Comprobar que si el SO no concede ejecución o el usuario fuerza el cierre, la sincronización se recupera silenciosamente al siguiente arranque; no hay promesas de periodicidad exacta.
- [ ] Observar Instruments Main Thread Checker/Time Profiler: lectura JSON, codificación y mezcla masiva deben ejecutarse fuera del hilo principal; SwiftUI solo publica el snapshot resultante.
- [ ] Cuenta ofrece «Sincronizar ahora» para entrenamientos con estado de error/último envío; el catálogo editorial sigue sin botón manual.

## Catálogo editorial Supabase (25/10/2026)

- [x] Backfill real de 288 ejercicios y cursor 1–293 en Supabase Repera, RLS de lectura authenticated, sin permiso de lectura anon.
- [x] Pruebas SQL reversibles: corregir nombre, material y archivar `catalog:Press banca` emite eventos; `ROLLBACK` mantiene los 287 eventos originales y el ejercicio activo.
- [ ] Con un iPhone autenticado, primera sincronización: recibir dos páginas (150 + 143) sin duplicados ni cambios de UUID ni favoritos.
- [ ] Dos aperturas con la misma revisión: el segundo inicio lee únicamente el último ID y no vuelve a bajar 287 fichas.
- [ ] En el panel de datos cambiar `mobile_description`, `mobile_instructions` y `mobile_equipment`: se reflejan en ficha y registro sin instalar otra versión; restaurar después el valor editorial original.
- [ ] Añadir un movimiento con nueva `catalog_key`; verificar que aparece tras sincronizar, que tiene UUID idéntico en dos iPhone y que se puede entrenar sin perder datos.
- [ ] Marcar `is_active=false`: desaparece de biblioteca y selector, pero rutinas, sesiones, récords y favoritos históricos conservan ID y datos. Reactivar y comprobar retorno.
- [ ] Renombrar un ejercicio sin cambiar `catalog_key` ni UUID: no crear duplicados y conservar evolución.
- [ ] Sin conexión: iniciar rápido, mostrar caché, seguir entrenando; reconectar para obtener únicamente los eventos pendientes.
- [ ] Con iCloud antiguo, cerrar/reabrir sin tocar controles: la copia remota corrige las fichas tras recuperarse iCloud.
- [ ] Revisar Watch activo al cambiar un ejercicio desde iPhone; probar app Watch sin conectividad con historial precargado.
- [ ] Compilar con Xcode 27, ejecutar Swift XCTest ReperaDomain, simulador iPhone/Watch y pruebas de dispositivos reales antes de fusionar PR.

## MCP multidisciplina (23/10/2026)

- [ ] Consultar `get_training_discipline_reference` para `crossfit`, `weightlifting`, `mobility`, `warmup`: comprobar claves **reales**, alias y metadatos; movilidad debe resolver **82** entradas.
- [ ] Consultar `get_warmup_prescription_reference` con `mainDiscipline=weightlifting`, trabajo «Snatch», sin material declarado: verificar secuencia específica y aviso de equipamiento **sin darlo por disponible**.
- [ ] Consultar `get_athlete_planning_context` con una cuenta real con consentimiento: métricas 7/28 días y semana anterior, programas y huecos de agenda, frescura del espejo, y máximos de kg/reps/m/cal separados. Confirmar que otra cuenta/token no puede acceder a este historial.
- [ ] En ausencia de historial, devolver preguntas y sin e1RM ni falsa recuperación. Al registrar metros/Cal/sesiones por duración, nunca añadirlos al tonelaje o estimar 1RM.
- [ ] Plan CrossFit AMRAP y Halterofilia fuerza + calentamiento: comprobar estructura aceptada por `create_training_plan` y que las duraciones especiales y fases warm-up aún no se presentan como métricas nativas inexistentes.
- [ ] Tras actualizar Edge Function, confirmar autenticación PAT, read-only scopes, revocación y que `create_training_plan` solo aparece con `training:write`.

## Biblioteca de ejercicios: ordenar y filtrar (23/10/2026)

- [ ] Elegir **Ordenar → Material**: comprobar que Wall Ball aparece en «Wall Balls», Ball Slam en «Slam Balls», SkiErg en «SkiErg / esquí de aire», Remo máquina en «Remoergómetros», GHD sit-up en «GHD», Sled Push/Pull en «Trineos», saltos al cajón en «Cajones», Double-Under en «Combas», Sandbag Lunges en «Sacos de arena» y Yoke Carry en «Yugos».
- [ ] Verificar que Remo con barra va a «Barras» y Remo sentado a «Poleas», que las variantes en anillas no quedan en barra de dominadas, y que se ordenan por material también los ejercicios etiquetados genéricamente «Máquina» o «Peso corporal».
- [ ] Verificar todas las categorías adicionales: gomas, mancuernas, kettlebells, discos, barras, cuerdas de trepa, pegboards, picas, rodillos, bancos, paredes, marcos de puerta y material desconocido sin pérdida de entradas.

- [ ] Abrir la misma hoja de filtros: confirmar dos secciones **Ordenar** y **Filtrar**, selección única independiente y botón **Hecho** sin cierre al cambiar una elección.
- [ ] Elegir **Halterofilia** y después **Músculo**: solo ejercicios olímpicos, distribuidos por grupo anatómico; cambiar a **Alfabético** no altera el filtro.
- [ ] Con **Todos**, **CrossFit**, **Gimnasia**, **Cardio**, **HYROX**, **Movilidad**, **Favoritos** y **WODs**, comprobar que cada filtro conserva el sort y funciona con búsqueda ES/EN. En WODs, título y botón de alta respetan la pantalla WOD.
- [ ] Buscar `snatch high pull`, `clean high pull`, `clean deadlift`, `squat jerk`, `jerk dip and drive`, `block power snatch`, `block power clean` y `snatch grip push press`: verificar la ficha sin duplicados y la asignación correcta a Halterofilia.
- [ ] Verificar 288 claves únicas en iOS y web, 48 etiquetadas directamente Halterofilia, y comprobar en backend las ocho altas sin sobrescribir historial ni categorías existentes.

## HYROX y evolución cardio (2026-10-23)

- [ ] En **Ejercicios → Filtro → HYROX** aparecen las nueve estaciones, con buscador ES/EN. En **Deporte** CrossFit/HYROX comparten Wall Ball y SkiErg sin duplicar UUID ni historial; nuevos ejercicios solo Burpee Broad Jump y Sandbag Lunges.
- [ ] En **Apuntar series / Play** registrar 1000 m en Remo máquina, 500 m SkiErg, 20 cal SkiErg y 50 m Sled Push; asegurar que se guarda la unidad y peso por movimiento cuando corresponda.
- [ ] En Evolución, verificar que **m máx.** y **cal máx.** muestran marcas independientes; el gráfico no mezcla 1000 m con 20 cal ni genera e1RM por metros; los totales tampoco mezclan unidades.
- [ ] Cuando no exista historial ni marca, no deben aparecer «Entrena este ejercicio para ver cal, metros o reps.» ni «Cuando entrenes este ejercicio, verás aquí el historial.».
- [ ] MCP: consultar `get_hyrox_training_reference` y `search_training_exercises_enriched(query="HYROX")`; verificar nueve claves, y que `get_exercise_progress` separa metros y calorías. Programar una sesión `forTime` alternando carrera 1000 m con cada una de las ocho estaciones y comprobar la prescripción recibida en iOS.
- [ ] Antes de publicar TestFlight: validar integración en dispositivo, sincronización Supabase y estado de despliegue de Edge Function; los tests de dominio no sustituyen estas comprobaciones.


## Navegación deportista (2026-10-19)

- [ ] La barra muestra **Inicio · Diario · Crear · Progreso · Ejercicios** sin vínculo a centro; con gimnasio/entrenador, **Center** en lugar de Crear.
- [ ] **Inicio → +** abre todas las acciones antiguas: crear entreno, apuntar series, favoritos, temporizador y escanear pizarra; iniciar/continuar entreno conserva la navegación.
- [ ] **Inicio → Añadir entreno** conserva su sheet por día y **Crear plan** abre Diario en «Personal».
- [ ] **Diario** abre en «Entrenador» con sesiones profesionales recibidas tras invitación/Apple Auth, o estado vacío sin vinculaciones; «Personal» y «Rutinas» conservan todos los datos y acciones.
- [ ] **Center** muestra selector **Clases · Citas** y los horarios reales publicados por un centro. Sin datos, muestra un estado vacío; con bono válido, reserva mediante RPC. Comprobar aforo, citas solapadas, cancelación y devolución en PostgreSQL.
- [ ] **Ajustes** separa centros/entrenadores, servicios externos y el plan «Repera Pro» de Apple.
- [ ] Con futuro backend: validar reservas grupales y citas 1:1, evitar solapes de entrenador/sala, doble reserva de la última plaza, saldo y caducidad separados, devolución de crédito, notificaciones, varios centros y revocación, sin borrar historial local.

## E2E profesional / Apple Auth (pendiente de ejecutar en iOS 27)
- [ ] Configurar Apple provider para bundle `com.app.repera` en Supabase Repera, luego validar registro/login en dispositivo y restauración de sesión tras reinicio.
- [ ] Cambiar entre dos identidades Apple: ningún centro, invitación, bono o reserva debe filtrarse entre cuentas.
- [ ] Owner crea empresa e invita un atleta; atleta acepta desde iOS; aparece centro en Ajustes.
- [ ] Entrenador publica sesión fechada; aparece en Diario e Inicio del atleta, pero no en la cuenta de un tercero ni sustituye la planificación personal.
- [ ] Manager publica clase y cita; ofrece bono de cortesía por tipo; atleta reserva cada modalidad con el bono correcto, sin saldos negativos.
- [ ] Cancelar a más y menos de 12h; comprobar política provisional y ledger; no emitir facturas/pagos ficticios.
- [ ] Dos deportistas reservan la última plaza simultáneamente desde dispositivos diferentes; verificar exactamente una reserva.
- [ ] Center muestra «Completo» si aforo=reservas, sin filtrar información de otras personas ni ofrecer botón Reservar; si falla RPC, deshabilita la reserva.
- [ ] Modo avión, token caducado, Apple ocultar correo, sesión revocada y eliminación/revocación del vínculo.
- [ ] Ejecutar build/UITests con Xcode e iOS 27 y revisar todo el CI antes de merge.

## Calorías de Apple Salud — Inicio, Historial y Progreso

- [ ] Sin permitir lectura de Salud, registrar un entreno manual, finalizarlo y regresar a Inicio: **sin chip kcal**; el total diario muestra «—», no una estimación por minutos.
- [ ] Con Salud autorizado pero sin datos reales de energía, finalizar un entreno de fuerza sin Watch: **sin chip kcal**, y el workout guardado en Apple Salud **sin muestra sintética** de energía activa.
- [ ] Sin entrenos, pero con energía activa realmente registrada por Apple Watch en Salud, Inicio debe mostrar **las kcal reales del día** (aunque no exista registro de Repera).
- [ ] Vincular un HKWorkout **externo** con energía registrada: aparece su chip kcal en Inicio e Historial con el valor obtenido de Salud; el resumen corresponde al dato verificado.
- [ ] Vincular un workout sin energía o propio de Repera con un valor histórico estimado: **no** aparece chip de kcal; no se debe tratar como entrenamiento externo de Salud.
- [ ] Importar sesiones antiguas que llevaban `appleActiveEnergyKcal` estimado: la migración limpia el número no verificado y no modifica las series, el tiempo ni la ruta.
- [ ] Revisar días pasados: el total solo recoge energía medida por Salud; Progreso usa los mismos datos, sin sumar de nuevo las estimaciones antiguas.
- [ ] Revocar lectura de Salud o utilizar un dispositivo sin HealthKit: no se pintan calorías ficticias ni se convierte «sin datos» en «0 kcal».
- [ ] Tras autorizar Salud y sincronizar, los datos aparecen sin reiniciar el entrenamiento; repetir tras reiniciar la aplicación para verificar la caché v2.
- [ ] Revisar en Apple Salud que una sesión creada por Repera no genera nuevas muestras de kcal calculadas; las muestras de versiones anteriores no se borran automáticamente.

## Monetización (Gratis / Pro)

Detalle: [MONETIZATION.md](MONETIZATION.md).

- [ ] Sin `RevenueCatPublicAPIKey` → StoreKit 2 carga productos reales de App Store Connect; si Apple no los ofrece, mostrar motivo en el paywall, sin conceder Pro.
- [ ] Debug → Ajustes → Debug Pro: simular Free / Pro mensual / anual / trial / gracia / caducada / offline.
- [ ] Crear 4ª rutina biblioteca → paywall; editar/borrar las 3 existentes OK.
- [ ] Crear 6º ejercicio custom → paywall; catálogo seed sin límite.
- [ ] 4 escaneos OK en el mes; 5º → paywall; fallo OCR / cancelar no consumen.
- [ ] Ficha ejercicio Gratis: última sesión + teaser; Pro: evolución completa.
- [ ] Progreso Gratis: solo «Esta semana»; periodos Pro abren paywall sin cambiar rango.
- [ ] WOD: registro libre; historial completo = Pro.
- [ ] Restaurar compras (sandbox) y gestionar suscripción (enlace Apple).
- [ ] Import JSON no activa Pro; export sigue incluyendo datos deportivos.

## Log rápido (Apuntar series)

- [ ] **Inicio → + → Apuntar series** → elige ejercicio → modal de series → guardar → aparece en Inicio / Historial.
- [ ] Racha en Inicio con Salud autorizada → Historial lista Repera **y** entrenos de Salud (sin duplicar vinculados).
- [ ] Distinto de **Crear mi entreno**: no pide bloques/WOD.
- [ ] **Ficha ejercicio → +** → mismo modal de series (no abre sesión completa).
- [ ] En modal: check (guardar) estilo topbar; cancelar = X.

## Play — conservación de entradas numéricas (iOS 27)

- [ ] En una serie con peso y reps, introducir 72,5 kg y 12 reps sin ✓ y salir del campo: se conservan ambos valores.
- [ ] Modificar solo las reps y pulsar Finalizar directamente: persisten las cifras más recientes.
- [ ] Borrar una serie por swipe, añadir otra y finalizar: la eliminada no reaparece ni cuenta en Progreso.
- [ ] Con varias series, la flecha avanza entre peso/reps; borrar una intermedia con swipe no cambia los IDs restantes.
- [ ] La última serie también se puede borrar por swipe, dejando solo Añadir serie y ningún resultado ficticio.
- [ ] Introducir peso con coma o punto decimal, borrar cifras y usar +/−; cambiar de campo o cerrar el teclado sin perder valores válidos.
- [ ] Repetir con ejercicios de **solo reps**, **tiempo**, **déficit cm** y **Cal/metros**, incluyendo las series añadidas durante el entreno.
- [ ] Cambiar de ejercicio y volver: el borrador modificado persiste sin check individual.
- [ ] En técnicas avanzadas, editar peso/reps del stepper y dropset; cambiar de campo sin pulsar ✓ y comprobar el valor actualizado.
- [ ] En la planificación, editar dos valores de un formato WOD con el mismo teclado: el avance y los valores se mantienen al cambiar de campo.

## % → kg

- [ ] Ejercicio con historial de peso (e1RM) + pizarra con `#70%` → en revisión ves kg sugeridos.
- [ ] Ficha → **Carga sugerida**: slider % muestra kg.
- [ ] Ficha → toque en el número de un stepper → teclado + **intro** confirma y cierra (sin barra Listo).
- [ ] Ficha → **Evolución**: pulsar Tope 1RM edita a mano; al superar e1RM al guardar, el tope sube solo.
- [ ] Filtro **Músculo**: Thruster / Arrancada aparecen bajo Piernas/Hombros/… no bajo CrossFit; filtro **Deporte** sí agrupa CrossFit/Halterofilia/Gimnasia.

## Copiar semana pasada

- [ ] Diario → ⋯ → **Copiar semana pasada**.
- [ ] Con entrenos sueltos la semana ISO anterior → aparecen en esta semana (nuevos IDs).
- [ ] Sin datos → alerta «No había entrenos sueltos…».

## Progreso

- [ ] Periodo «Esta semana» → tiles muestran delta vs semana previa (sin switch).
- [ ] Con «Todo» no hay deltas.
- [ ] Cardio / kcal con Salud autorizada.
- [ ] **Peso**: gráfica + línea de meta si hay objetivo; Δ actual vs objetivo.
- [ ] Periodo corto → refresco Salud acotado (`healthFetchDayCount`).
- [ ] **Más detalle** colapsable; empty states si no hay ejercicios / PRs.
- [ ] Sin autorización Salud → card «Salud no conectada».

## Peso corporal

- [ ] Ajustes → Peso: registrar → un solo valor por día (re-registrar hoy actualiza).
- [ ] Objetivo en la misma sección; se refleja en Progreso.
- [ ] Tras sync Salud no aparecen varios pesajes del mismo día.

## Sesión / eliminación

- [ ] Menú ⋯ → eliminar entreno → `OGConfirmSheet` glass.
- [ ] Swipe en Inicio / sesión en curso → eliminar con confirmación.
- [ ] Borrar entreno guardado → desaparece también de Salud (si estaba enlazado).
- [ ] Terminar Apuntar series: check verde en círculo (sin doble círculo).

## Formatos WOD y temporizadores en Play (iOS 27)

- [ ] **AMRAP 12'** con 3 movimientos: mostrar un resultado del bloque (rondas completas + reps de la ronda incompleta), no una tabla de series por movimiento; registrar manualmente 5+7 y comprobar el resumen.
- [ ] Iniciar AMRAP: cuenta previa de 3 s, cuenta atrás de 12', abre captura de rondas/reps al acabar; cancelar la captura no debe inventar registros.
- [ ] **4 RFT / For Time** con TC de 12': cronómetro ascendente; avisar al minuto 12 sin parar; si termina en 13:17, guardar 13:17 y no 12:00 ni series ficticias.
- [ ] **Chipper, AFAP, Ladder y Buy-in/Cash-out**: capturar tiempo único del bloque, aun sin haberse arrancado el reloj; respetar cap opcional.
- [ ] **EMOM 12'** cada 60 s: 12 intervalos; **Every 2' ×4**: cuatro intervalos de 120 s; las repeticiones son series por movimiento y la duración no se cuenta como cuatro series adicionales.
- [ ] **Tabata 20/10 ×8**: contar 8 ventanas de trabajo, alternar exactamente 20 s y 10 s y mostrar ronda 1/8 hasta 8/8. Con dos movimientos alternos prescribir 4 ventanas de trabajo por movimiento, no ocho a cada uno.
- [ ] **Circuito 3 rondas ×2 estaciones de 45 s con descanso de 25 s entre rondas**: comprobar secuencia trabajo/trabajo/descanso/trabajo/trabajo/descanso/trabajo/trabajo.
- [ ] **Death By**: avisos cada intervalo (1 min por defecto), permitir Terminar al fallar, capturar rondas completas + reps adicionales.
- [ ] **Max Effort** por reps: pedir repetición máxima; **Partner, RFQ, Fuerza**: seguir por series con reloj libre o timebox según configuración.
- [ ] Con EMOM/Tabata corriendo, minimizar el reloj, cambiar entre movimientos del mismo bloque, registrar peso/reps y reabrirlo: mantiene fase y avisos y no reinicia.
- [ ] Poner la app en segundo plano cruzando varias fases Tabata; al volver debe estar en la fase correcta, sin acumular restos ni avisar una vez por cada intervalo pasado.
- [ ] Tras terminar un EMOM/Tabata, revisar/corregir series antes de pulsar «Finalizar bloque»; no se deben crear series ni cerrar el entrenamiento automáticamente.
- [ ] Guardar el score global de un bloque anterior cuando otro está seleccionado: solo se confirma el bloque correcto, sin finalizar el otro.
- [ ] Validar test de dominio y `test_wod_play_contract.py` en CI iOS 27 y, manualmente, en dispositivo.

## Corregir el peso o reps originales de un WOD terminado

- [ ] Historial → Entreno terminado → Editar: en un AMRAP de 8' comprobar que aparecen «Resultado del entreno», **Prescrito (editable)** y **Realizado (opcional)** para cada movimiento; ninguna sección de series ficticias por ejercicio.
- [ ] Prescrito: cambiar cargada y envión de 20 reps/40 kg a 18 reps/35 kg y Realizado: mantener 15 reps/25 kg. Guardar y reabrir: ambos conjuntos de datos se conservan, y sigue intacta la marca global de 5 rondas + 4 reps.
- [ ] Si existen sets realmente registrados (p. ej. 16 reps/27 kg), editar solo el peso Rx de 40 a 35: las series registradas siguen siendo 16/27 y la rutina reutilizable original sigue marcando 40.
- [ ] Editar un número decimal usando coma o punto en el peso prescrito sin perder caracteres mientras se teclea.
- [ ] Cuando Realizado coincide exactamente con Prescrito (p. ej. 15 reps, 25 kg en ambos), sigue mostrando «Realizado» en Historial, pero la nota no se identifica como «Adaptado» por esa coincidencia.
- [ ] En un esquema 21-15-9 se presenta el esquema sin aplanarlo automáticamente; sigue siendo posible corregir el peso prescrito del movimiento.
- [ ] También verificar bloques originalmente de Fuerza con formato de puntuación global: editar Rx no sustituye sus series registradas; la nota se recalcula.
- [ ] En edición de rutinas y entrenos por series (EMOM, Tabata, Circuito) mantener el comportamiento habitual de las series sin convertir Rx en resultados.

## Valoración v11: ejercicios entre formatos y WOD con estímulo calibrado

- [ ] Repetir un push press en dos EMOM históricos y en un bloque de Fuerza nuevo, con RIR similar, mismo material y reps ±2: Evolución personal aparece como **Nivel 2 · Mismo ejercicio**, confianza media; NO se exige repetir idéntico EMOM.
- [ ] Mismas series pero sin RIR registrado entre contextos: no crear una nota de comparación cruzada. Push press no puede heredar datos de press banca.
- [ ] Con dos sesiones previas del mismo formato/contexto exacto, dar prioridad a **Nivel 1** sobre las referencias Nivel 2 y no mezclar marcas incompatibles.
- [ ] AMRAP 8 min de burpees con 4 rondas y dos For Time/RFT previos de burpees: con solo dos días anteriores NO se activa Nivel 3; necesita al menos **tres días** independientes.
- [ ] Con tres For Time de la misma tarea y repeticiones por ronda similares (≤25%), carga idéntica y tiempos similares (máximo ratio 1,5), un AMRAP distinto puede obtener **Nivel 3 · Estímulo comparable**, puntuado por reps/minuto y confianza baja.
- [ ] Si los nombres de los movimientos difieren (por ejemplo burpees vs push-ups, push press vs banca), las cargas no coinciden, hay escalado sin normalizar, diferentes unidades o esquemas variables, ocultar Nivel 3.
- [ ] Una sesión mixta con cobertura válida inferior al 60% del trabajo prescrito no muestra nota global aunque alguno de sus movimientos sí tenga referencias.
- [ ] Abrir el historial tras actualizar a fórmula 11: recalcular o eliminar puntuaciones v10 y mantener series, rondas, tiempos y kcal originales.
- [ ] La tarjeta iOS enseña la fuente Nivel 1/2/3 en cada indicador disponible, y Cumplimiento continúa sin puntuación numérica.

## Valoración verificable v10 (sin nota antes del histórico mínimo)

- [ ] Primera sesión terminada de un ejercicio: Inicio **solo Kcal y Tiempo** (sin tarjeta Nota), Historial mantiene kg/reps/RIR pero **no presenta card de valoración ni nivel**; tampoco se muestra hoja de puntuación al acabar.
- [ ] Segunda sesión del mismo ejercicio en otro día: sigue sin nota. Cinco series en un único entreno o dos entrenamientos el mismo día NO desbloquean ninguna puntuación.
- [ ] Tercera sesión del mismo ejercicio, con al menos **dos sesiones anteriores en días distintos** y rango de reps ±2, material y RIR compatibles: aparece la tarjeta de **Nota global, Evolución personal, Cumplimiento, Rendimiento WOD**; indicador no disponible = «Sin referencia» sin valor numérico.
- [ ] Cumplimiento muestra series realmente registradas/planificadas, no 9/10 por cubrir los campos. Modificar el número de sets no mejora directamente la valoración.
- [ ] WOD AMRAP 8' con 2 marcas anteriores del mismo formato, duración, ejercicios, reps, peso y adaptación: tercera marca desbloquea Rendimiento WOD. Cambiar Rx o Scaled, duración o prescripción invalida esa comparación.
- [ ] Una sesión mixta con 1 bloque comparable y otros dos sin referencias: si la cobertura de rendimiento es menor del 60%, **no mostrar ninguna nota**. Con dos de tres unidades comparables y dos días previos, aparece nota personal con nivel de confianza «En construcción».
- [ ] Un máximo 1RM aislado no habilita puntuación de evolución; un día de descarga intencionada tampoco debe bajar la nota por comparación injusta. Nunca comparar push press con press banca, ni barras y mancuernas como si fueran iguales.
- [ ] Corregir un entrenamiento histórico (prescripción, reps, resultado, adaptación) y guardar: se conserva el registro original y se recalcúla con referencias cronológicamente anteriores, sin crear nuevas series ni degradar histórico.
- [ ] Versionar valoración a 10 y abrir un histórico con nota vieja: debe desaparecer antes de existir referencias verificables. En Inicio la nota no aparece como «—/10» cuando no existe histórico.
- [ ] La confianza solo puede ser «Alta» cuando todas las unidades puntuadas tienen ≥5 días de referencia y cobertura ≥80%; el score no cambia por datos HealthKit aislados.

## Nota de sesión mixta: EMOM + AMRAP

- [ ] Reproducir el entrenamiento del 22/10/2026: EMOM 12' con 4 sets de push press y 4 de peso muerto; EMOM 9' con 2 sets de fondos y pistol squat sin series; AMRAP 8' con 2 rondas + 20 reps. La nota global NO debe ser la del AMRAP aislado ni mostrarse como «Principiante».
- [ ] Registrar un entrenamiento anterior de **press banca 90 kg × 7**: push press 70 kg × 2 no debe compararse con bench ni perder puntos por esa referencia. El detalle debe limitarse a ejercicios realmente comparables.
- [ ] Mostrar el desglose de la nota orientativa: ritmo del AMRAP, EMOM 12' (8/8 series registradas) y EMOM 9' (2/4). No inferir que la ausencia de pistol squat significa que no se hizo.
- [ ] El inicio y fin almacenados muestran 3 min 38 s para la sesión de 29 min planificados: advertir de la discrepancia y NO usar esa duración total para penalizar.
- [ ] Comprobar que la sesión de prueba no cambia de fecha, duración registrada, rondas ni series, y que se elimina la nota antigua hasta acumular historial suficiente con la fórmula 10.
- [ ] El pie del resultado no debe decir «nivel de catálogo» cuando el score es una estimación de sesión mixta; una única sesión no determina el nivel atlético.

## Edición de adaptaciones y nota Scaled (todos los scores globales)

- [ ] AMRAP 8': guardar 5 rondas + 4 reps; en «Cargada y envión» poner 15 reps y 25,5 kg (Rx: 20 reps y 40 kg). Guardar, reabrir y comprobar **resultado global 5+4**, prescripción 20/40 intacta, valores adaptados 15/25,5 y **ninguna serie inventada**.
- [ ] Editar el peso decimal tecleando «25,5» o «25.5» sin que desaparezcan caracteres intermedios; dejar campo vacío restaura Rx.
- [ ] Ver la adaptación en Historial debajo de cada movimiento y comprobar que «Nota» se ha recalculado; el informe debe indicar «Adaptado» y base orientativa de ritmo de trabajo real, **sin bandas ni PR Rx**.
- [ ] For Time/RFT, AFAP, Chipper, Ladder, Death By, Max Effort y Buy-in/Cash-out: las adaptaciones por movimiento no sustituyen el tiempo/rondas/reps del bloque; la nota usa datos de ejecución si se modifican.
- [ ] WOD con carga ajustada pero sin peso Rx disponible: no inventar una comparación de kg; mantener nota solo si existe evidencia de ritmo/volumen útil.
- [ ] EMOM/Every X, Tabata, Circuito y Fuerza/Skill: mantener el registro habitual de series, cargas, reps y RIR, sin convertir adaptaciones globales en series.
- [ ] Tras modificar el entrenamiento terminado, comprobar persistencia del ID, fecha, posición, notas, HealthKit y resultados en el detalle.

## Editar resultados de entrenos terminados (todos los formatos)

- [ ] Verificar **en una compilación nueva instalada en el iPhone** que Editar desde el detalle de una sesión **terminada** enseña «Resultado del entreno» justo debajo de la configuración del AMRAP; no se ven cuadros de «SERIE ANTERIOR / KG / REPS / RIR» por movimiento. Si aparecen, la versión instalada no está usando el editor terminado actualizado.
- [ ] Con un AMRAP antiguo que carece de `wodResults`, las casillas «Rondas completas» y «Reps adicionales» aparecen **directamente**, sin pulsar «Añadir resultado». Una marca heredada de la primera serie se muestra como valor inicial y se puede corregir sin duplicar series.
- [ ] Editar el mismo AMRAP dos veces seguidas y comprobar que reabre siempre la marca persistida (ningún estado cargado tarde borra ni oculta la puntuación).
- [ ] Un bloque marcado AMRAP que originalmente era de Fuerza no muestra series previstas como score, y guarda las rondas/reps corregidas.


- [ ] Terminar AMRAP 8' con resultado 4 rondas + 7 reps; Historial → entreno → Editar: aparece la marca, no series por cada movimiento. Modificar a 5 rondas + 3 reps, Guardar, cerrar y reabrir: se conserva 5 + 3 en el mismo entrenamiento.
- [ ] AMRAP y Death By sin `wodResults` históricos: introducir rondas/reps directamente, pulsar Guardar sin cerrar antes el teclado, reabrir y confirmar que se almacenó el resultado explícito sin crear ninguna serie completada.
- [ ] For Time / RFT, Chipper, AFAP, Ladder y Buy-in/Cash-out: editar minutos y segundos reales, por ejemplo 12:11 → 10:42; pulsar Guardar **con el teclado abierto**, volver a Historial y reabrir Editar; debe verse 10:42 en detalle y en ambos campos. Repetir cuando el bloque carecía de `wodResults`: editar directamente desde 0 y generar un único resultado. El time cap no cambia.
- [ ] Batería de los ocho formatos de puntuación global: AMRAP, Death By, Max Effort, For Time/RFT, Chipper, AFAP, Ladder y Buy-in/Cash-out. Para cada uno, probar **con y sin** marca anterior; Guardar debe crear/actualizar una sola entrada de `wodResults`, sin mover `loggedSets`, otra marca de bloque, fechas ni UUID de Salud.
- [ ] En una sesión con AMRAP y RFT independientes, corregir solo el tiempo del RFT: conserva la marca de rondas/reps del AMRAP. Cambiar la marca del AMRAP después no altera el RFT; tras reiniciar la aplicación siguen ambas.
- [ ] En un ejercicio de WOD añadido o reordenado en un entrenamiento terminado, la identidad del movimiento debe conservarse en la próxima edición, aunque existan otros movimientos del mismo tipo.
- [ ] Max Effort: editar reps máximas sin confundirlas con rondas AMRAP (marca de kg/cal/metros todavía no soportada globalmente).
- [ ] EMOM/Every X, Tabata, Circuito, Partner, RFQ y Fuerza/Skill: editar una serie existente con carga, reps y RIR, guardar y volver; conservar ID de sesión/serie y no generar ninguna serie en movimientos sin registro.
- [ ] Comprobar que «Prescripción» se muestra de forma separada del resultado global en AMRAP/For Time, y que la tabla por intervalos distingue «Series registradas» de «Sin series registradas · prescripción».
- [ ] Cambiar el formato de AMRAP a For Time en un histórico: no reinterpretar sus rondas como segundos ni reutilizar la marca antigua; permitir añadir tiempo nuevo.
- [ ] Con Circuito de tres rondas, modificar el resultado por serie sin perder los segundos de descanso entre rondas; mantener fechas, datos Salud, notas y ruta anteriores.

## Pizarra

- [ ] Foto con EMOM 8’ @6-8 + 2 HIGH HSQ SNATCH → ejercicio correcto.
- [ ] Foto con EVERY 2’ X 4 + 4-3-3-2 BACK SQUAT @6-8 → fuerza: 4 series de 4/3/3/2; conservar la indicación de RPE, sin inventar RIR.
- [ ] Foto con 4 RFT (TC 12’) + POWER SNATCH 40/25 + BOB + BACK RACK R. LUNGES 40/25 + 1’ REST → cuatro movimientos, orden intacto, pesos M/F, 4 rondas, cap 12' y descanso de 60 s.
- [ ] Buscar Back Squat/sentadilla, power snatch/arrancada, high hsq snatch/arrancada colgante y lunges/zancadas; resultados pertinentes con imágenes o placeholder explícito.
- [ ] En editor: Crear WOD, Elegir WOD, Añadir ejercicio, Añadir movimiento libre → push de derecha a izquierda, topbar con volver y título debajo. Volver preserva formulario existente.
- [ ] JPG presentes en bundle tanto como ExerciseArt/<nombre>.jpg como aplanados en raíz: miniaturas visibles en picker y al configurar entreno.
- [ ] TestFlight: ver mensual/anual con precios Apple, completar compra sandbox, restaurar, cancelar, comprobar Pro tras relanzar y denegación tras caducar. Sin tarjetas/cargos reales y sin habilitar Pro por compra pendiente.
- [ ] ASC primera suscripción: confirmar que ambas se envían a revisión con una nueva versión y tienen localizaciones, disponibilidad, precios y contrato de pago configurados.

- [ ] Pizarra con ≥2 bloques claros → «Análisis local» sin espera larga de IA.
- [ ] Imagen oscura (TV) → OCR legible (lienzo negro).

## Live Activity (dispositivo real)

- [ ] En sesión, inicia descanso → Live Activity / Dynamic Island con cuenta atrás.
- [ ] Al acabar el rest, la activity se cierra.

## Watch log rápido

- [ ] iPhone + Watch emparejados, app Watch abierta.
- [ ] Sin sesión: **Iniciar en iPhone** / **+1 serie** arranca log rápido del último ejercicio.
- [ ] Con sesión: **+1 serie** registra una serie en el ejercicio actual.

## Ajustes / navegación

- [ ] Avatar Inicio → Ajustes con botón volver.
- [ ] Ajustes → Cuenta → tocar el avatar con distintivo Apple: se abre el selector nativo de Fotos; elegir imagen actualiza el avatar sin fallo Swift 6 ni cambios de diseño, y se sincroniza con el perfil.
- [ ] Cancelar la selección de foto mantiene el avatar anterior; volver a abrir el selector funciona y el distintivo Apple sigue visible.
- [ ] Historial / Peso / Rotación: topbar fijo transparente (como Ejercicios) + volver del sistema.
- [ ] No existe entrada Coach.

## Splash de lanzamiento (regresión)

- En iPhone pequeño y grande, cerrar por completo y abrir en vertical: personaje y logo mantienen la misma forma y tamaño relativo del LaunchScreen a la pantalla de espera.
- Repetir con sesión iniciada y onboarding pendiente: sin zoom, estiramiento, flash negro ni salto de posición.
- Girar a horizontal en dispositivo compatible: `scaleAspectFit` conserva la imagen entera, sin distorsión.
- Instalar una compilación nueva (5 o posterior) para invalidar la captura de lanzamiento cacheada por iOS.

## Cambio de cuenta durante sincronización profesional (pendiente de dispositivo)

- [ ] Iniciar una consulta de Center/Diario con cuenta Apple A, salir e iniciar con B antes de terminar la respuesta: ninguna invitación, centro, bono o sesión de A debe volver a aparecer.
- [ ] Cerrar sesión cuando una petición está en vuelo: la UI no repuebla datos de A.
- [ ] Cancelar una reserva con menos de 12h: aparece confirmación avisando de la no devolución provisional de crédito; con más de 12h, explica la posible devolución y exige confirmación.
- [ ] Tras un error de red o cambio de cuenta, el cliente nunca presenta aforo o créditos antiguos como disponibles.

## UI tests en simulador limpio (2026-10-19)

`ReperaSmokeUITests` arranca la app Debug con `--repera-ui-test-tabs` y `REPERA_UI_TEST_MODE=1` para acceder únicamente al contenedor de pestañas sin cuenta Apple del runner. La compilación Release **no** reconoce este modo. Los tests comprueban `Inicio · Diario · Crear|Center · Progreso · Ejercicios` y navegación a Ejercicios. El login real con Apple debe probarse en otro escenario E2E con cuenta y TestFlight, nunca se simula como superado.

## Inicio, Recuperación y sincronización histórica (2026-10-22)

- [ ] Inicio → Actividad: tres tarjetas del mismo ancho **Pasos, Calorías, Tiempo**. No aparece FC media ni la franja ancha de Tiempo. Con 57 min propios y 4 min de lectura parcial de Salud debe verse **57 min** y no 61; las barras respetan el objetivo configurado, incluida la fracción extra más oscura si se supera.
- [ ] Con y sin objetivos de minutos, tarjeta Tiempo compacta y unidad «min» en la misma línea. Sin duración real, mostrar «—» sin inventar minutos.
- [ ] Progreso → Recuperación: primera tarjeta «Preparación para entrenar» con nota entera 0–10 y consejo (8–10 verde, 6–7 amarillo, 0–5 rojo). Iconos moon, dumbbell, heart, waveform/bed de contorno. La segunda tarjeta es una **sola curva de evolución** 0–10 suavizada con gradiente de abajo rojo, medio amarillo y arriba verde; puntos coloreados según el score. Revisar 1 punto: no mostrar gráfica vacía.
- [ ] La tarjeta Sueño muestra exclusivamente horas y fases con una única gráfica; no aparece «Evolución del sueño», texto «Puntuación orientativa…», ni proyección de mañana basada en sueño supuesto. Sin sueño/carga observada, no mostrar nota: «Datos insuficientes».
- [ ] Salud con VFC/FC en reposo sin referencia histórica: no restar puntos. Con siete días de comparación calibrada y VFC baja o FC reposo alta: reducir la nota; sin ese dato no inventar pulsaciones. Cardio externo de HKWorkout añadido en últimas 48–96 h influye en la carga **una sola vez**, sin duplicar sesiones Repera enlazadas.
- [ ] Ajustes → Cuenta: confirmar que no hay botón ni spinner de sincronización. Al reabrir la app con sesión válida, se recuperan los cambios pendientes sin intervención.
- [ ] Revisar modo oscuro/claro, Dynamic Type, VoiceOver de nota y tendencia, permisos parciales de Apple Salud y estados de carga.

## Escritura en Apple Salud y fuente de verdad (2026-10-22)

- [ ] Autorizar lectura y escritura de **Entrenamientos** en Ajustes → Apple Salud. Terminar una sesión Repera desde iPhone: en la app Salud debe aparecer un HKWorkout de fuerza con inicio, fin, nombre Repera e identidad estable; el registro Repera almacena el mismo UUID.
- [ ] Finalizar una sesión con un entrenamiento real de Entreno de Apple Watch solapado al menos 70 % y no ambiguo: enlazar el UUID externo, sus fechas y duración **aunque no tenga calorías**; no escribir otro HKWorkout de Repera. Si la sesión del reloj estuvo pausada, el indicador de tiempo de Inicio debe usar la duración real del HKWorkout, no el tiempo de pared.
- [ ] Con energía medida por el propio HKWorkout de Apple Watch, mostrarla; sin muestra de energía, mostrar — en kcal por sesión, no energía activa ambiente del mismo periodo.
- [ ] Denegar escritura pero permitir lectura: vincular un HKWorkout de Apple Watch coincidente. Si no existe, conservar el entrenamiento local sin marcarlo como guardado en Salud y mantener el entrenamiento local sin exigir interacción de sincronización.
- [ ] Sin permisos para escribir ni workout externo, guardar Repera únicamente en local. Dar el permiso posteriormente y reabrir la app: se crea **una** muestra HealthKit con UUID y la app deja de informar de ella como pendiente.
- [ ] Terminar entreno, cerrar/reabrir la app y regresar a primer plano: debe encontrar el HKWorkout propio por metadatos ReperaSessionID, sin generar duplicados.
- [ ] Simular doble sincronización concurrente: «Terminar» y la actualización automática al volver a primer plano no crean dos HKWorkout de la misma sesión. Mantener los datos originales si HealthKit devuelve error o no confirma UUID (p. ej. dispositivo bloqueado).
- [ ] Con varios HKWorkout en un día, comprobar que un registro de Watch enlazado no se suma de nuevo como actividad externa ni duplica minutos. Una actividad externa distinta y no solapada sí se suma.
- [ ] No dar por cubierta captura de FC y kcal propias de la app watchOS Repera: actualmente no ejecuta HKWorkoutSession; probar solo con entrenamientos de HealthKit reales (p. ej. Entreno de Apple).
- [ ] Revisar permisos, modo avión, bloqueo/desbloqueo de pantalla, reintentos, cambios de día y sincronización iCloud con el iPhone real. Validar que se omiten kcal estimadas históricas.

## Conciliación de minutos y navegación de Progreso (2026-10-22)

- [ ] En Inicio, elegir un día pasado con un entrenamiento Repera de 60 minutos sin actividad externa: Tiempo de entrenamiento muestra 60 min aunque la caché histórica de Salud no tenga una sesión propia.
- [ ] Hoy, un entrenamiento Repera de 57 min y una lectura parcial HealthKit de 4 min deben mostrar 57 min, nunca 4 ni 61. Tras finalizar/guardar en Salud, refrescar y comprobar que no cambia a un total duplicado.
- [ ] Si Salud tiene un HKWorkout vinculado por UUID con duración consistente, prevalece su medición. Si devuelve una duración incoherentemente corta, se utiliza como respaldo el intervalo del registro Repera (sin convertirlo en una medición de energía).
- [ ] Dos entrenos distintos de 40 y 20 min contabilizan 60 min; un workout importado externo no solapado de 30 min eleva el total a 90. El mismo HKWorkout enlazado a un entreno Repera se cuenta **una sola vez**.
- [ ] Si falta permiso para escribir entrenos en Salud, la sesión no desaparece de Inicio ni muestra calorías estimadas. Verificar en Salud que el HKWorkout existe tras finalizar con permiso de escritura; la lectura local no es prueba de que se haya guardado en HealthKit.
- [ ] En Progreso → Entreno, bajar al final y cambiar a Actividad y Recuperación: aparece el **inicio** de la nueva categoría (título/selector y primera tarjeta), sin zona negra vacía. Probar también el regreso a Entreno.
- [ ] Con seis o más ejercicios y récords en el periodo, mostrar solo los cinco más recientes, seguidos de «Ver más» con flecha. Al tocar abre página con **todos** los elementos y permite regresar sin alterar periodo; desde la página de ejercicios se navega al detalle. Con 0–5 elementos no aparece «Ver más».
- [ ] Verificar Dynamic Type, modo oscuro, VoiceOver, scroll de los listados largos y orden por fechas con empates.

## Inicio y objetivos de Salud — revisión iOS 27 (2026-10-22)

- [ ] Abrir Inicio en modo claro y oscuro: calendario, entrenamiento (incluido día vacío) y «Añadir nuevo entreno» comparten un lienzo OG.surface a ancho total; Progreso semanal, Actividad y Recuperación mantienen sus márgenes.
- [ ] Deslizar el calendario por días y cruzar un cambio de mes: la cabecera se actualiza, los días siguen siendo cuadrados y el seleccionado tiene color de marca OG.accent (#30D158).
- [ ] En día vacío, planificado y completado, «Añadir nuevo entreno» sigue siendo verde con letras negras, pero queda a solo 6 pt de la ficha. Día vacío y una ficha con entreno tienen el mismo alto base compacto de 100 pt (Dynamic Type puede ampliarlo), con 10 pt de padding vertical y título/chips centrados entre el borde superior e inferior, sin margen inferior mayor que el superior. Si el título necesita más líneas, la caja crece sin recortarse. Abrir el flujo y regresar sin perder selección de fecha.
- [ ] Con entrenos completos, planificados y externos, comprobar borde gris, papelera oculta antes del swipe, revelación al deslizar y confirmación obligatoria de eliminación. El día vacío debe llevar el mismo borde.
- [ ] Ajustes → Salud → Objetivos muestra solo pasos, kcal, minutos, entrenos semanales y peso con teclado numérico Repera, guardado automático y sin botón Guardar ni textos explicativos al pie. **No aparece FC media ni deja hueco**; «Siguiente» desde Calorías pasa directamente a Tiempo. Vaciar el campo quita solo su objetivo.
- [ ] Desde versiones anteriores se conserva el peso objetivo y se admite decodificar la antigua meta de FC media aunque ya no sea editable ni aparezca en Inicio. Editar, volver atrás sin botón Guardar, reiniciar y comprobar persistencia de los cinco objetivos visibles.
- [ ] Establecer objetivos de pasos y energía: en Inicio las métricas presentan un progreso solo con datos medidos; si Salud no suministra dato, mostrar raya, no cero.
- [ ] En Actividad de Inicio no hay evolución de siete días ni texto «Meta» en las tarjetas. Con y sin objetivos, comprobar que cada tarjeta usa solo la altura necesaria y que kcal/min aparecen junto al valor, en la misma línea. Cuando hay objetivo, solo barra verde/naranja/azul con progreso accesible por VoiceOver; sin objetivo no hay barra ni hueco adicional; sin medición no se inventa relleno.
- [ ] Tiempo de entrenamiento ya no tiene el texto «Objetivo: … min» bajo la barra: sin meta, cero barra; con 45/60 min, 75 % de la barra azul y 25 % gris; con 75/60 min, barra llena con 60/75 azul y 15/75 azul oscuro. Comprobar también pasos 12 000/10 000, calorías 650/500, tiempo 75/60 y entrenos semanales 6/5, cada excedente proporcional y más oscuro. La cifra visible siempre refleja el total real; sin datos de Salud no inventar minutos ni pulsaciones.
- [ ] Entrenar dos veces en un día y comprobar que el progreso semanal muestra dos entrenamientos frente a la meta, aunque haya solo un check para el día.
- [ ] Al editar un input numérico que presenta 0 por defecto, la primera cifra sustituye al cero; probar series, RIR, formatos, prescripciones y adaptaciones.
- [ ] Comprobar que el componente topbar de Inicio no tiene fondo pintado (como el de Ejercicios): el blanco real del bloque calendario/entreno se prolonga sin cortes por detrás de la topbar y el área de estado. El fondo gris reaparece solo al empezar Progreso semanal; revisar scroll, modo claro y oscuro.
- [ ] Verificar Dynamic Type, VoiceOver, pantalla estrecha, pantalla amplia, reducción de movimiento y navegación de gestos dentro de un ScrollView vertical.

### Incidencias de compilación y herramientas de Xcode

- “Cannot find HealthGoalsView in scope”: desde este cambio HealthGoalsView reside en Apps/Repera/Sources/SettingsView.swift, un archivo ya incluido en el proyecto Xcode antiguo. Actualizar main y comprobar que el archivo local está actualizado; no debe quedar una definición duplicada de la vista. Si se regenera con XcodeGen, usar project.yml desde la raíz y reabrir el proyecto.
- “Assets.xcassets: Could not get trait set for device Watch8,3 with version 27.0”: este mensaje procede del procesado del catálogo por Xcode/CoreSimulator; no confirma que falte el icono ni explica por sí solo el fallo SwiftCompile. Verificar que Xcode y los componentes de watchOS 27 están completos, instalar actualizaciones disponibles (Xcode → Ajustes → Componentes), cambiar al destino iPhone real para aislarlo, limpiar Build Folder y volver a compilar. Conservar el catálogo original si el JSON y los iconos son correctos; investigar el resto del log si la compilación falla.
- Registrar por separado los errores reales de Swift y los avisos de actool y ejecutar el build completo con Xcode 27 antes de publicar TestFlight.

## Movilidad (82 movimientos)

- [ ] Ejercicios → Filtro → **Movilidad** muestra solo movimientos de movilidad, también tras buscar en español o inglés.
- [ ] «cat cow» encuentra Gato-vaca; «knee to wall ankle mobility» encuentra Rodilla a pared para tobillo; acentos y 90/90 no bloquean la búsqueda.
- [ ] En Alfabético y Músculo siguen apareciendo ejercicios de movilidad con sus fichas; en Deporte no se agrupan erróneamente bajo Fuerza.
- [ ] La ficha de movilidad conserva explicación y pasos sin mostrar «Carga sugerida» ni campo de kg; se puede marcar favorita.
- [ ] Registrar movilidad y volver a Progreso no añade series artificiales al mapa de fatiga.
- [ ] Los movimientos nuevos se añaden una sola vez tras migrar el catálogo existente y conservan el historial al reiniciar.
- [ ] Imagen específica: por ahora debe aparecer placeholder de movilidad; no asignar una fotografía de fuerza por coincidencia textual. Generar y validar las 82 imágenes antes de declarar cobertura visual.
- [ ] Crear rutina con postura del niño (1 mantenimiento de 45 s) y Gato-vaca (8 repeticiones en 60 s); reabrir y comprobar segundos prescritos, duplicación y compatibilidad JSON.
- [ ] Iniciar Play: el tiempo inicial debe coincidir con la prescripción, sin kg ni RIR, y las posturas no deben mostrar un campo de reps.
- [ ] Cambiar segundos y completar series en Play; comprobar que Evolución usa tiempo **registrado**, incluyendo mejor sostén y tiempo acumulado, no tiempo prescrito.
- [ ] Comprobar resumen global de Movilidad (sesiones + minutos reales), tanto en Gratis —semana actual— como Pro —periodo seleccionado—.
- [ ] Comprobar que los ejercicios existentes de fuerza, cardio, comba y WOD mantienen sus campos y récords anteriores.

### Android Play: delete + restore Pro (paridad Apple)

- [ ] Con identidad **desechable**: comprar/tester Pro → Eliminar cuenta → recrear
      con la misma cuenta Google Play → refresh/restaurar concede Pro si la
      suscripción sigue ACTIVE (verify backend). No exige el UUID antiguo.
- [ ] Otro JWT vivo no puede hijackear un `purchaseToken` ya claimed.
- [ ] No ejecutar E2E de borrado con la cuenta real del propietario.

