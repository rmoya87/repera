# Guía de pruebas — Repera

Última actualización: 2026-10-22 (integración de Play, WOD y calorías verificadas de Apple Salud)

Checklist manual por feature. Preferible dispositivo real para Live Activity y Watch.

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

- [ ] En una serie con peso y reps, introducir **72,5 kg** sin pulsar ✓; tocar reps, introducir **12** y tocar fuera: ambos valores siguen presentes.
- [ ] Modificar solo las reps de una serie y pulsar el check directamente, sin confirmar el teclado; el registro conserva exactamente las últimas cifras.
- [ ] Marcar la última serie, desmarcarla y editarla de nuevo: se muestran los valores **reales registrados**, no ceros ni los objetivos originales de la planificación.
- [ ] Con varias series pendientes, pulsar la flecha **negra** del teclado: peso → reps → peso de la siguiente serie (o la primera casilla habilitada), sin cerrar el teclado y omitiendo series marcadas.
- [ ] La última casilla ofrece **✓ verde**. Después de registrar, las series completadas permanecen bloqueadas hasta desmarcar.
- [ ] Introducir peso con coma o punto decimal, borrar cifras y usar +/−; cambiar de campo o cerrar el teclado sin perder valores válidos.
- [ ] Repetir con ejercicios de **solo reps**, **tiempo**, **déficit cm** y **Cal/metros**, incluyendo las series añadidas durante el entreno.
- [ ] Cambiar de ejercicio desde la lista o flechas de la barra superior y volver: permanecen las series editadas aunque aún no se haya marcado el check.
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
- [ ] Con un AMRAP antiguo que carece de `wodResults`, aparece «Añadir resultado» desde el primer render y permite grabar las rondas completas y las reps de la ronda parcial sin inventar series.
- [ ] Editar el mismo AMRAP dos veces seguidas y comprobar que reabre siempre la marca persistida (ningún estado cargado tarde borra ni oculta la puntuación).
- [ ] Un bloque marcado AMRAP que originalmente era de Fuerza no muestra series previstas como score, y guarda las rondas/reps corregidas.


- [ ] Terminar AMRAP 8' con resultado 4 rondas + 7 reps; Historial → entreno → Editar: aparece la marca, no series por cada movimiento. Modificar a 5 rondas + 3 reps, Guardar, cerrar y reabrir: se conserva 5 + 3 en el mismo entrenamiento.
- [ ] AMRAP y Death By sin `wodResults` históricos: aparece «Añadir resultado», se rellenan rondas/reps y Guardar actualiza la misma sesión sin generar series completadas.
- [ ] For Time / RFT, Chipper, AFAP, Ladder y Buy-in/Cash-out: editar minutos y segundos reales, por ejemplo 12:11 → 10:42; el time cap es solo la configuración, el resultado corregido permanece tras reabrir.
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
