import ReperaDomain
import SwiftUI

/// Barra de progreso adaptable: el objetivo ocupa su fracción real del
/// total si se supera y el excedente aparece al final en un tono más oscuro.
/// Por debajo de la meta, el resto del recorrido permanece gris.
/// Destinos de «Añadir entreno»: misma navegación push nativa de Inicio.
private enum AddWorkoutPage: Hashable, Identifiable {
    case create(date: Date)
    case favorites
    case timer

    var id: Self { self }
}

private struct HomeGoalProgressBar: View {
    var measurement: Double?
    var goal: Double
    var tint: Color
    var label: String
    var unit: String = ""

    var body: some View {
        let value = measurement.flatMap { $0.isFinite ? max(0, $0) : nil } ?? 0
        let safeGoal = goal.isFinite && goal > 0 ? goal : 1
        let scale = max(value, safeGoal)
        let covered = min(value, safeGoal) / scale
        let overflow = max(0, value - safeGoal) / scale

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(OG.surface3)
                if covered + overflow > 0 {
                    Capsule()
                        .fill(tint)
                        .frame(width: min(
                            geometry.size.width,
                            max(geometry.size.height, geometry.size.width * CGFloat(covered + overflow))
                        ))
                }
                if overflow > 0 {
                    Capsule()
                        .fill(tint)
                        .overlay(Color.black.opacity(0.32), in: Capsule())
                        .frame(width: geometry.size.width * CGFloat(overflow))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(Capsule())
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso de \(label)")
        .accessibilityValue(
            measurement == nil
                ? "Sin medición"
                : "\(ReperaNumberFormat.integer(Int(value.rounded())))\(unit.isEmpty ? "" : " \(unit)") de \(ReperaNumberFormat.integer(Int(safeGoal.rounded())))\(unit.isEmpty ? "" : " \(unit)")\(value > safeGoal ? ", \(Int((value - safeGoal).rounded()).formatted()) adicionales" : "")"
        )
    }
}

/// Inicio: semana seleccionable + métricas del día + registros.
struct HomeView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(BusinessDataStore.self) private var businessData
    var onOpenWorkout: () -> Void
    var focusDay: Date? = nil
    var onStart: () -> Void
    /// Abre el preview / inicio de un entreno concreto (p. ej. suelto del viernes).
    var onStartRoutine: (Routine) -> Void = { _ in }

    /// La semana seleccionada gobierna el resumen, no la posición del scroll horizontal.
    @State private var weekOffset = 0
    /// Un año a cada lado del presente, con desplazamiento continuo día a día.
    private static let weekCarouselRadius = 52
    @State private var calendarScrollID: String?
    @State private var isExpandedLayout = false
    @State private var showSettingsPanel = false
    @ScaledMetric(relativeTo: .body) private var weekCarouselHeight: CGFloat = 72
    /// Shared baseline for a single exercise card and the no-workout state.
    /// Keeps the activity/progress cards below steady while changing days.
    @ScaledMetric(relativeTo: .body) private var singleWorkoutMinHeight: CGFloat = 108
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var lastAppliedFocusDay: Date?
    /// Live refine for **today** only (HK query). Past days use bucket metrics — never wait on HealthKit to paint.
    @State private var todayHealthLive = HealthKitStore.DayMetrics()
    /// Pasos reales de Salud del día seleccionado; nil si no hay lecturas disponibles.
    @State private var selectedDaySteps: Int?
    @State private var showCreatePlanForDay = false
    /// El menú es modal; los tres destinos son páginas fuera de la sheet.
    @State private var pendingAddWorkoutPage: AddWorkoutPage?
    @State private var addWorkoutPage: AddWorkoutPage?
    @State private var restoresAddSheetAfterPage = false
    /// Revisión de pizarra como página (fuera del sheet «Añadir entreno»).
    @State private var boardReviewPayload: BoardScanReviewPayload?
    @State private var workoutPendingDelete: WorkoutSession?
    @State private var routinePendingDelete: Routine?
    @State private var healthPendingDelete: HealthKitStore.ExternalActivity?
    @State private var openWorkoutId: UUID?
    @State private var openHealthActivityId: UUID?
    /// Day-keyed buckets — rebuilt off the critical body path (no full-array filter per paint).
    @State private var workoutsByDayKey: [String: [WorkoutSession]] = [:]
    @State private var healthByDayKey: [String: [HealthKitStore.ExternalActivity]] = [:]
    @State private var kcalByDayKey: [String: Double] = [:]
    @State private var healthMinutesByDayKey: [String: Double] = [:]
    @State private var prCountBySessionId: [UUID: Int] = [:]
    /// Semana / racha precalculados — cambiar de día no recalcula dots ni streak.
    @State private var cachedWeekDays: [DayCell] = []
    @State private var cachedCalendarDays: [DayCell] = []
    @State private var cachedStreakWeeks = 0
    @State private var cachedStreakWeekDone = 0
    @State private var cachedStreakPlanned = 0
    @State private var cachedStreakTotal = 0

    private var calendar: Calendar { Calendar.current }

    private var selectedISOWeekday: Int {
        CalendarHelpers.isoWeekday(for: selectedDay)
    }

    private var healthActivities: [HealthKitStore.ExternalActivity] {
        healthByDayKey[dayKey(selectedDay)] ?? []
    }

    /// Reconciliación diaria sin duplicados: los entrenos de Repera aportan
    /// duración registrada, los externos no solapados aportan su duración de Salud.
    /// Cuando existe HKWorkout enlazado se usa su duración si coincide
    /// razonablemente con el intervalo registrado; si está truncado no
    /// sustituye una sesión completa por unos pocos minutos.
    private var recordedDayWorkoutMinutes: Double {
        let local = workoutsOnSelectedDay.reduce(0.0) { total, session in
            let logged = max(0, session.displayDurationMinutes)
            let measured = session.healthKitWorkoutUUID.flatMap {
                health.verifiedWorkoutDurationMinutes[$0]
            }
            let resolved: Double
            if let measured, measured > 0,
               (session.healthKitWorkoutUUID.map {
                   health.verifiedExternalWorkoutUUIDs.contains($0)
               } == true || abs(measured - logged) <= max(5, logged * 0.25)) {
                // HealthKit Watch tiene prioridad incluso cuando sus pausas
                // producen una duración distinta al tiempo de pared.
                resolved = measured
            } else {
                resolved = logged
            }
            return total + resolved
        }
        let external = healthMinutesByDayKey[dayKey(selectedDay)] ?? 0
        return local + external
    }

    private var dayHealth: HealthKitStore.DayMetrics {
        let key = dayKey(selectedDay)
        let recordedMinutes = recordedDayWorkoutMinutes
        if calendar.isDateInToday(selectedDay) {
            // Priorizar los HKWorkouts conciliados individualmente; una
            // suma cruda de Salud podría contener duplicados anteriores.
            // Si aún no existen entradas conciliadas, usar la lectura de hoy.
            let healthToday = todayHealthLive.workoutMinutes ?? health.workoutMinutesToday
            let minutes = recordedMinutes > 0 ? recordedMinutes : (healthToday ?? 0)
            return HealthKitStore.DayMetrics(
                activeEnergyKcal: todayHealthLive.activeEnergyKcal
                    ?? health.activeEnergyTodayKcal
                    ?? kcalByDayKey[key],
                workoutMinutes: minutes > 0 ? minutes : nil
            )
        }
        return HealthKitStore.DayMetrics(
            activeEnergyKcal: kcalByDayKey[key],
            workoutMinutes: recordedMinutes > 0 ? recordedMinutes : nil
        )
    }

    /// Professional plan read from Supabase, projected as real editable-style blocks.
    /// Never overwrites the athlete's local routines, results or HealthKit history.
    @ViewBuilder
    private var professionalSessionsForSelectedDay: some View {
        let selected = BusinessDataStore.localDayKey(selectedDay)
        let published = businessData.trainingSessions.filter { $0.scheduledDate == selected }
        if !published.isEmpty {
            OGCardSectionTitle(title: "Planificado por tu entrenador")
            ForEach(published) { session in
                BusinessProfessionalSessionCard(
                    session: session,
                    centerName: businessData.centerName(session.orgId),
                    compact: true
                )
            }
        }
    }

    /// Confirmed external reservations live beside local workouts, without modifying ReperaStore.
    @ViewBuilder
    private var confirmedBusinessBookingsCard: some View {
        let todayBookings = businessData.bookings.filter { booking in
            guard booking.status == "booked",
                  let occurrence = businessData.occurrences.first(where: { $0.id == booking.occurrenceId }),
                  let begins = BusinessDataStore.date(occurrence.startsAt) else { return false }
            return Calendar.current.isDate(begins, inSameDayAs: selectedDay)
        }
        if !todayBookings.isEmpty {
            OGCardSectionTitle(title: "Reservas confirmadas")
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(todayBookings) { booking in
                        if let occurrence = businessData.occurrences.first(where: { $0.id == booking.occurrenceId }) {
                            HStack(spacing: 12) {
                                Image(systemName: occurrence.kind == "class" ? "figure.group" : "person.crop.circle")
                                    .foregroundStyle(OG.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(occurrence.title).font(.headline)
                                    Text(businessData.centerName(occurrence.orgId))
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                    if let start = BusinessDataStore.date(occurrence.startsAt) {
                                        Text(start.formatted(date: .omitted, time: .shortened))
                                            .font(.footnote)
                                            .foregroundStyle(OG.label2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(OG.accent)
                            }
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // El blanco del calendario y Entreno continúa por detrás del
                    // topbar transparente, sin crear un fondo propio para la barra.
                    VStack(alignment: .leading, spacing: 12) {
                        weekSelectorCard
                        dayWorkoutSection
                            .padding(.horizontal, OG.pad)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(OG.surface.ignoresSafeArea(edges: [.top, .horizontal]))

                    // Progreso/Actividad conservan el lienzo agrupado gris,
                    // que empieza justo donde termina la sección blanca.
                    VStack(alignment: .leading, spacing: 12) {
                        if isExpandedLayout {
                            HStack(alignment: .top, spacing: 12) {
                                weeklyProgressCard
                                    .frame(maxWidth: .infinity, alignment: .top)
                                activityTodayCard
                                    .frame(maxWidth: .infinity, alignment: .top)
                            }
                            .padding(.horizontal, OG.pad)
                        } else {
                            weeklyProgressCard
                                .padding(.horizontal, OG.pad)
                            activityTodayCard
                                .padding(.horizontal, OG.pad)
                        }
                        if calendar.isDateInToday(selectedDay) {
                            RecoveryHomeCard()
                                .padding(.horizontal, OG.pad)
                        }
                        professionalSessionsForSelectedDay
                            .padding(.horizontal, OG.pad)
                        confirmedBusinessBookingsCard
                            .padding(.horizontal, OG.pad)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: isExpandedLayout ? .infinity : OG.contentColumnMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    // En paisaje la safe area lateral pertenece al gris de
                    // Progreso/Actividad; el blanco solo es calendario + entreno.
                    .background(OG.bg.ignoresSafeArea(edges: .horizontal))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // El gris agrupado debe ocupar el viewport entero y la zona
            // inferior segura, incluso si no hay tarjetas más abajo.
            .background(OG.bg.ignoresSafeArea(edges: .bottom))
            .onGeometryChange(for: Bool.self, of: { $0.size.width >= 620 }) { _, expanded in
                isExpandedLayout = expanded
                if !expanded { showSettingsPanel = false }
            }
            .refreshable { await businessData.refresh() }
            .ogFixedTopBar("repera", subtitle: SpanishDate.long(selectedDay)) {
                if !businessData.athleteCenterIds.isEmpty {
                    NavigationLink {
                        MessagesInboxView()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: OG.toolbarGlassIcon, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .symbolRenderingMode(.monochrome)
                                .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                                .contentShape(Circle())
                                .glassEffect(.regular.interactive(), in: .circle)
                            if !businessData.personalNotices.isEmpty {
                                Circle()
                                    .fill(OG.label)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -10, y: 10)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mensajes con centro o entrenador")
                }
                if isExpandedLayout {
                    Button {
                        showSettingsPanel = true
                    } label: {
                        iCloudAvatar
                            .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Abrir Ajustes en la columna derecha")
                } else {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        iCloudAvatar
                            .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ajustes y cuenta iCloud")
                }
            }
            // Fondo independiente del topbar: el blanco continúa visualmente
            // desde la zona segura superior hasta calendario + entreno.
            // El componente de navegación y sus controles no se modifican.
            .background(alignment: .top) {
                // Cubrir también todo el margen superior derecho del DUO:
                // una franja fija de 160 pt no alcanzaba el safe area horizontal.
                OG.bg.ignoresSafeArea()
                    .overlay(alignment: .top) {
                        OG.surface
                            .frame(maxWidth: .infinity)
                            .frame(height: 360, alignment: .top)
                            .ignoresSafeArea(edges: [.top, .horizontal])
                    }
            }
            .onAppear {
                LaunchTiming.mark("HomeView.onAppear")
                if let focusDay, focusDay != lastAppliedFocusDay {
                    lastAppliedFocusDay = focusDay
                    selectedDay = calendar.startOfDay(for: focusDay)
                }
                // Con diskPaint, workouts ya están en store (mismo ritmo que Salud).
                rebuildDayBuckets()
                rebuildWeekChrome()
                Task(priority: .utility) {
                    rebuildStreakChrome()
                    prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                }
                Task(priority: .utility) {
                    health.refreshAuthorizationStatus()
                }
            }
            .onChange(of: store.isHydrated) { _, hydrated in
                guard hydrated else { return }
                rebuildDayBuckets()
                rebuildWeekChrome()
            }
            .onChange(of: focusDay) { _, day in
                if let day {
                    lastAppliedFocusDay = day
                    selectedDay = calendar.startOfDay(for: day)
                }
            }
            .onChange(of: selectedDay) { _, newDay in
                // Al elegir un cuadrado, el progreso semanal sigue esa fecha.
                let newOffset = weekOffset(for: newDay)
                if weekOffset != newOffset {
                    weekOffset = newOffset
                }
                if calendar.isDateInToday(newDay) {
                    Task(priority: .utility) { await refineTodayMetricsInBackground() }
                }
            }
            .onChange(of: weekOffset) { _, _ in
                rebuildWeekChrome()
            }
            .onChange(of: health.isAuthorized) { _, authorized in
                if authorized {
                    Task(priority: .utility) { await refreshProgressiveHealthIfNeeded() }
                }
            }
            .task(id: "\(store.workoutsEpoch)-\(health.healthDataRevision)") {
                rebuildDayBuckets()
                rebuildWeekChrome()
                await Task.yield()
                rebuildStreakChrome()
                prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                await health.refreshVerifiedWorkoutEnergy(for: store.state.workouts)
            }
            .task(id: "\(dayKey(selectedDay))-\(health.healthDataRevision)-\(health.isAuthorized)") {
                let requestedDay = selectedDay
                let requestedKey = dayKey(requestedDay)
                selectedDaySteps = nil
                let series = await health.dailySteps(endingAt: requestedDay)
                guard !Task.isCancelled, dayKey(selectedDay) == requestedKey else { return }
                selectedDaySteps = series.first(where: {
                    calendar.isDate($0.date, inSameDayAs: requestedDay)
                })?.steps
            }
            // Salud diferida: no bloquear el primer paint de Inicio.
            .task(id: "\(weekOffset)-\(store.isHydrated)") {
                guard store.isHydrated else { return }
                rebuildWeekChrome()
                try? await Task.sleep(for: .milliseconds(120))
                await refreshProgressiveHealthIfNeeded()
                if calendar.isDateInToday(selectedDay) {
                    await refineTodayMetricsInBackground()
                }
            }
            .sheet(isPresented: $showCreatePlanForDay, onDismiss: {
                // Abrir la página tras el cierre vertical completo del sheet.
                guard let pending = pendingAddWorkoutPage else { return }
                pendingAddWorkoutPage = nil
                restoresAddSheetAfterPage = true
                addWorkoutPage = pending
            }) {
                DayPlusSheet(
                    targetDate: selectedDay,
                    onCreateWorkout: { openAddWorkoutPage(.create(date: selectedDay)) },
                    onOpenFavorites: { openAddWorkoutPage(.favorites) },
                    onOpenTimer: { openAddWorkoutPage(.timer) },
                    onBoardReady: { payload in
                        showCreatePlanForDay = false
                        // Empujar página tras cerrar el sheet.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(280))
                            boardReviewPayload = payload
                        }
                    }
                )
            }
            .navigationDestination(item: Binding(
                get: { addWorkoutPage },
                set: { next in
                    let returnedFromPage = addWorkoutPage != nil && next == nil
                    addWorkoutPage = next
                    guard returnedFromPage && restoresAddSheetAfterPage else { return }
                    restoresAddSheetAfterPage = false
                    // Dejar terminar el pop lateral antes de recuperar la modal.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(330))
                        guard addWorkoutPage == nil, !showCreatePlanForDay else { return }
                        showCreatePlanForDay = true
                    }
                }
            )) { destination in
                switch destination {
                case .create(let date):
                    DayEditorView(
                        routine: Routine(
                            title: "Entreno · " + CalendarHelpers.weekdayName(CalendarHelpers.isoWeekday(for: date)),
                            weekday: nil,
                            scheduledDate: date,
                            blocks: [.strength(title: "Bloque 1")],
                            progression: .off
                        ),
                        mode: .oneOff(isNew: true),
                        onClose: {
                            // Guardar vuelve al calendario sin reabrir el menú.
                            restoresAddSheetAfterPage = false
                            addWorkoutPage = nil
                        },
                        embedsNavigationStack: false,
                        usesPageCloseHeader: true
                    )
                case .favorites:
                    FavoritesHubView(onOpenedWorkout: {
                        restoresAddSheetAfterPage = false
                        addWorkoutPage = nil
                        onOpenWorkout()
                    })
                case .timer:
                    StandaloneTimerView(embedsNavigation: false)
                }
            }
            .navigationDestination(item: $boardReviewPayload) { payload in
                BoardImportReviewView(
                    lines: payload.lines,
                    ocrText: payload.ocrText,
                    detectedBlocks: payload.blocks,
                    interpretSource: payload.source,
                    preferredWeekday: CalendarHelpers.isoWeekday(for: payload.targetDate),
                    preferredDate: payload.targetDate,
                    embedsNavigationStack: false
                ) { started in
                    boardReviewPayload = nil
                    if started {
                        onOpenWorkout()
                    }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { openWorkoutId != nil },
                set: { if !$0 { openWorkoutId = nil } }
            )) {
                if let id = openWorkoutId {
                    WorkoutDetailView(sessionId: id)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { openHealthActivityId != nil },
                set: { if !$0 { openHealthActivityId = nil } }
            )) {
                if let id = openHealthActivityId {
                    HealthActivityDetailView(activityId: id)
                }
            }
            .sheet(item: $workoutPendingDelete) { session in
                OGConfirmSheet(
                    title: "¿Eliminar registro?",
                    message: "Se borrará «\(session.title)» de este día. No se puede deshacer.",
                    onConfirm: {
                        store.deleteWorkout(session.id)
                        workoutPendingDelete = nil
                        Task {
                            await refreshProgressiveHealthIfNeeded()
                            rebuildDayBuckets()
                            rebuildWeekChrome()
                            rebuildStreakChrome()
                            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                        }
                    },
                    onCancel: { workoutPendingDelete = nil }
                )
            }
            .sheet(item: $routinePendingDelete) { routine in
                OGConfirmSheet(
                    title: "¿Borrar entreno?",
                    message: routine.isOneOff
                        ? "Se eliminará «\(routine.title)» de este día."
                        : "Se quitará «\(routine.title)» de este día. La plantilla seguirá en Rutinas.",
                    confirmTitle: "Borrar entreno",
                    onConfirm: {
                        store.removeScheduledRoutine(id: routine.id)
                        routinePendingDelete = nil
                        rebuildWeekChrome()
                        rebuildStreakChrome()
                    },
                    onCancel: { routinePendingDelete = nil }
                )
            }
            .sheet(item: $healthPendingDelete) { activity in
                OGConfirmSheet(
                    title: "¿Eliminar registro?",
                    message: "Se borrará «\(activity.title)» de este día. No se puede deshacer.",
                    onConfirm: {
                        let id = activity.id
                        healthPendingDelete = nil
                        Task {
                            _ = await health.deleteExternalWorkout(id: id)
                            await refreshProgressiveHealthIfNeeded()
                            rebuildDayBuckets()
                            rebuildWeekChrome()
                            rebuildStreakChrome()
                            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                        }
                    },
                    onCancel: { healthPendingDelete = nil }
                )
            }
        }
        .ogTrailingColumnPanel(
            isPresented: isExpandedLayout && showSettingsPanel,
            onDismiss: { showSettingsPanel = false }
        ) {
            NavigationStack {
                SettingsView()
                    .toolbar(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showSettingsPanel = false
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(OG.label)
                            }
                            .accessibilityLabel("Cerrar Ajustes")
                        }
                    }
            }
            .background(OG.bg)
        }
    }

    @ViewBuilder
    private var iCloudAvatar: some View {
        let synced = store.iCloudStatus == .available
        let photo = ProfileAvatar.uiImage(from: store.state.settings.profileAvatarJPEG)
        // El liquid glass lo aplica el `NavigationLink` (mismo diámetro que el +).
        Color.clear
            .overlay {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let iconSize = synced ? side * 0.42 : side * 0.34
                    ZStack {
                        if photo != nil || synced {
                            Circle()
                                .fill(OG.accent.opacity(0.22))
                        }
                        if let img = photo {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: synced ? "person.fill" : "gearshape")
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundStyle(synced ? OG.accent : OG.label)
                        }
                    }
                    .frame(width: side, height: side)
                    .clipShape(Circle())
                }
            }
    }

    /// Calendario horizontal de cuadrados: se mueve por días, sin flechas ni
    /// saltos obligatorios de semana. El mes corresponde a los días visibles.
    private var weekSelectorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(visibleCalendarMonthTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(OG.label2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, OG.pad)

            GeometryReader { geo in
                let preferredSide = max(1, weekCarouselHeight - 8)
                let visibleDays = isExpandedLayout
                    ? max(7, Int((geo.size.width + 4) / (preferredSide + 12)))
                    : 7
                let side = min(preferredSide, max(1, (geo.size.width - 4 * CGFloat(visibleDays - 1)) / CGFloat(visibleDays)))
                let spacing = isExpandedLayout && visibleDays > 1
                    ? max(4, (geo.size.width - CGFloat(visibleDays) * side) / CGFloat(visibleDays - 1))
                    : CGFloat(4)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(cachedCalendarDays, id: \.iso) { day in
                            Button {
                                selectedDay = day.date
                            } label: {
                                calendarDayColumn(day, side: side)
                            }
                            .buttonStyle(.plain)
                            .id(day.iso)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $calendarScrollID, anchor: .leading)
            }
            .frame(height: weekCarouselHeight)
            // SOLO los días son edge-to-edge. Se elimina el antiguo ancho
            // fijo de 7 días, el centrado y los 16 pt de padding exterior.
            // La geometría calcula las celdas con TODO el ancho real,
            // incluso dentro de las safe areas horizontales del DUO/iPad.
            // El rótulo de mes y las tarjetas restantes conservan sus márgenes.
            .ignoresSafeArea(edges: .horizontal)
        }
    }

    private func calendarDayColumn(_ day: DayCell, side: CGFloat) -> some View {
        let selected = calendar.isDate(day.date, inSameDayAs: selectedDay)
        // No fiarse del hasWorkout precalculado de DayCell: puede quedarse
        // obsoleto cuando cambian las sesiones o las lecturas de Salud.
        // El punto debe reflejar exactamente los datos que pinta la tarjeta
        // del día seleccionado, incluso antes de reconstruir el carrusel.
        let hasCompletedWorkout = hasCompletedWorkoutOnDay(day.iso)
        return VStack(spacing: 2) {
            Text(day.lbl)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selected ? OG.onAccent : OG.label2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(day.num)")
                .font(.system(size: 17, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? OG.onAccent : OG.label)
            // Solo marcar entrenamientos finalizados (Repera o Apple Salud).
            // La selección cambia el color del punto, nunca su visibilidad.
            if hasCompletedWorkout {
                Circle()
                    .fill(selected ? OG.onAccent : OG.accent)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: side, height: side)
        .background(
            selected ? OG.accent : OG.surface,
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            if !selected {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.lbl) \(day.num)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    /// Debajo del calendario, sin cabecera redundante ni tarjeta contenedora.
    /// Se conservan las tarjetas nativas de Repera y sus acciones originales.
    private var dayWorkoutSection: some View {
        dayEntrenoStack(workouts: workoutsOnSelectedDay)
    }

    /// Resumen 100 % local: los checks no navegan fuera de Inicio.
    private var weeklyProgressCard: some View {
        let days = cachedWeekDays.isEmpty ? makeWeekDays(offset: weekOffset) : cachedWeekDays
        return OGCard {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progreso semanal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(OG.label)
                        if isExpandedLayout {
                            Text("\(days.filter(\.hasWorkout).count) días entrenados")
                                .font(.system(size: 12))
                                .foregroundStyle(OG.label2)
                        }
                    }
                    Spacer(minLength: 8)
                    if !isExpandedLayout || store.state.settings.weeklyWorkoutGoal != nil {
                        Text(weeklyProgressSummary(for: days))
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                    }
                }
                HStack(alignment: .center, spacing: 4) {
                    ForEach(days, id: \.iso) { day in
                        VStack(spacing: 9) {
                            Text(day.lbl)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(OG.label2)
                            ZStack {
                                Circle()
                                    .fill(day.hasWorkout ? OG.accent : Color.clear)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                day.hasPlan && !day.hasWorkout
                                                    ? OG.accent.opacity(0.55) : OG.surface3,
                                                lineWidth: day.hasWorkout ? 0 : 1.5
                                            )
                                    }
                                if day.hasWorkout {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(OG.onAccent)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .accessibilityLabel(
                                "\(day.lbl) \(day.num): " +
                                (day.hasWorkout ? "entrenamiento completado" :
                                    day.hasPlan ? "entrenamiento planificado" : "sin entrenamiento")
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                if let target = store.state.settings.weeklyWorkoutGoal, target > 0 {
                    HomeGoalProgressBar(
                        measurement: Double(weeklyWorkoutCount(for: days)),
                        goal: Double(target),
                        tint: OG.accent,
                        label: "entrenamientos semanales",
                        unit: "entrenos"
                    )
                }
            }
        }
    }

    private func weeklyProgressSummary(for days: [DayCell]) -> String {
        let daysWithWorkout = days.filter(\.hasWorkout).count
        if let goal = store.state.settings.weeklyWorkoutGoal, goal > 0 {
            return "\(weeklyWorkoutCount(for: days)) de \(goal) entrenos"
        }
        return "\(daysWithWorkout) días entrenados"
    }

    private func weeklyWorkoutCount(for days: [DayCell]) -> Int {
        days.reduce(0) { total, day in
            total + (workoutsByDayKey[day.iso]?.count ?? 0)
                + (healthByDayKey[day.iso]?.count ?? 0)
        }
    }

    /// Actividad diaria real, sin gráfica de evolución semanal.
    private var activityTodayCard: some View {
        let workouts = workoutsOnSelectedDay
        let kcal = dayHealth.activeEnergyKcal.flatMap { $0 >= 0 ? $0 : nil }
        let score = workouts.compactMap { session -> Int? in
            guard let review = session.sessionReview,
                  review.scoreBasis == .personalHistory,
                  (review.evidenceCoverage ?? 0) >= 0.60 else { return nil }
            return min(max(review.overallScore, 0), 10)
        }.first

        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(calendar.isDateInToday(selectedDay) ? "Actividad de hoy" : "Actividad del día")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.label)

                HStack(alignment: .top, spacing: 8) {
                    homeActivityMetric(
                        title: "Pasos",
                        value: selectedDaySteps.map { ReperaNumberFormat.integer($0) } ?? "—",
                        unit: "",
                        symbol: "figure.walk",
                        tint: OG.accent,
                        measurement: selectedDaySteps.map { Double($0) },
                        goal: store.state.settings.dailyStepsGoal.map { Double($0) }
                    )
                    homeActivityMetric(
                        title: "Calorías",
                        value: kcal.map { ReperaNumberFormat.integer(Int($0.rounded())) } ?? "—",
                        unit: "kcal",
                        symbol: "flame",
                        tint: OG.orange,
                        measurement: kcal,
                        goal: store.state.settings.dailyActiveEnergyGoalKcal.map { Double($0) }
                    )
                    homeActivityMetric(
                        title: "Tiempo",
                        value: dayHealth.workoutMinutes.map {
                            ReperaNumberFormat.integer(Int($0.rounded()))
                        } ?? "—",
                        unit: "min",
                        symbol: "clock",
                        tint: OG.blue,
                        measurement: dayHealth.workoutMinutes,
                        goal: store.state.settings.dailyWorkoutMinutesGoal.map { Double($0) }
                    )
                }

                if let score {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(OG.accent)
                            .frame(width: 26, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Puntuación del entrenamiento")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(OG.label2)
                            Text("\(score)/10")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(OG.label)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func homeActivityMetric(
        title: String,
        value: String,
        unit: String,
        symbol: String,
        tint: Color,
        measurement: Double? = nil,
        goal: Double? = nil
    ) -> some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 20, alignment: .leading)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .center)

            // Número y unidad comparten línea, sin incrementar la altura.
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(OG.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(OG.label2)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            if let goal, goal > 0 {
                HomeGoalProgressBar(
                    measurement: measurement,
                    goal: goal,
                    tint: tint,
                    label: title,
                    unit: unit
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(10)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// Entreno del día: una ficha tiene la misma altura mínima en todos los estados.
    /// Varias sesiones suman fichas y pueden crecer sin límite artificial.
    @ViewBuilder
    private func dayEntrenoStack(workouts: [WorkoutSession]) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let hasActive = isToday && store.hasActiveSession
        let hasCompletedActivity = !workouts.isEmpty || !healthActivities.isEmpty
        let planned = plannedRoutinesForSelectedDay

        VStack(spacing: 6) {
            if hasActive {
                Button(action: onStart) {
                    dayActionRowContent
                }
                .buttonStyle(.plain)
                .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    OGSwipeDeleteButton(accessibilityLabel: "Descartar entreno en curso") {
                        store.endActiveSession(save: false)
                    }
                }
            }
            // La sesión estándar activa no debe ocultar actividades En vivo ya guardadas.
            ForEach(workouts) { session in
                dayWorkoutCard(session)
                    .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
            }
            // Una sesión ya realizada no oculta los otros entrenos pendientes
            // de esa misma fecha. Cada plan conserva su ficha y su gesto swipe.
            ForEach(planned) { routine in
                plannedDayCard(routine)
                    .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
            }
            if !hasActive && workouts.isEmpty && planned.isEmpty && !hasCompletedActivity {
                emptyWorkoutCard
            }

            ForEach(healthActivities) { activity in
                healthActivityCard(activity)
                    .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
            }

            // El CTA ocupa siempre la misma posición si solo hay una ficha.
            // Cuando hay varias sesiones, el listado sí crece verticalmente.
            if !hasActive {
                addAnotherWorkoutButton
                    .padding(.top, 12)
            }
        }
        .swipeActionsContainer()
    }

    /// Usa la misma retícula del registro real (44 pt de icono, título y banda
    /// inferior) en lugar de una sola línea que hacía saltar la Home.
    private var emptyWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 12) {
                OGRegisterLeadingIcon(systemName: "calendar.badge.minus", tint: OG.label3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(WorkoutListCaption.dayTimeLine(for: selectedDay, time: nil))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(OG.label3)
                        .tracking(0.3)
                    Text("Sin entrenamientos programados")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(OG.label)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Self.registerCardPad)

            HStack(spacing: 7) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 12, weight: .medium))
                Text("Día libre · puedes añadir un entrenamiento")
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(OG.label2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 30, alignment: .center)
            .padding(.leading, Self.chipsTitleLeading)
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: singleWorkoutMinHeight, alignment: .center)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
        }
        .accessibilityElement(children: .combine)
    }

    /// CTA inequívoco. Reutiliza el color exacto OG.accent (#30D158).
    private var addAnotherWorkoutButton: some View {
        Button {
            showCreatePlanForDay = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(OG.onAccent)
                Text("Añadir nuevo entreno")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.onAccent)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(OG.onAccent.opacity(0.85))
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                OG.accent,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Añadir nuevo entreno")
        .accessibilityHint("Abre el menú para crear o importar un entrenamiento para el día seleccionado")
    }

    /// Entreno planificado del día (aún sin sesión hecha): mismo swipe de borrar que los registros.
    private func plannedDayCard(_ routine: Routine) -> some View {
        return registerCardWithChipsOverlay(
            open: { onStartRoutine(routine) },
            accessibilityHint: "Toca para abrir el entreno. Desliza para borrarlo de este día.",
            deleteLabel: "Borrar entreno del día",
            onDelete: { routinePendingDelete = routine },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    // Pendiente: icono de fuerza gris, incluso si ya hay
                    // otro entreno completado en la misma fecha.
                    OGRegisterLeadingIcon(
                        systemName: "figure.strengthtraining.traditional",
                        tint: OG.label2
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(WorkoutListCaption.dayTimeLine(
                            for: selectedDay,
                            time: routine.normalizedScheduledTimeMinutes.map {
                                SpanishDate.time(minutesFromMidnight: $0)
                            }
                        ))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(OG.label3)
                            .tracking(0.3)
                        Text(routine.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Self.registerCardPad)
            },
            chips: {
                let blockCount = routine.blocks.count
                if blockCount > 0 {
                    OGRegisterChip(text: "\(blockCount) bloq.", icon: "square.stack.3d.up")
                }
                if let wod = routine.blocks.first(where: { $0.kind == .wod }) {
                    OGRegisterChip(text: wod.headerLabel, icon: "timer")
                }
            }
        )
    }

    private func dayWorkoutCard(_ session: WorkoutSession) -> some View {
        let prs = prCountBySessionId[session.id] ?? 0
        return registerCardWithChipsOverlay(
            open: { openWorkoutId = session.id },
            accessibilityHint: "Toca para ver el detalle del entreno",
            deleteLabel: "Eliminar registro de entreno",
            onDelete: { workoutPendingDelete = session },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    // Completado: mismo símbolo que un plan gris, en verde.
                    // Las actividades de Comenzar mantienen su icono deportivo.
                    OGRegisterLeadingIcon(
                        systemName: session.liveSportID.flatMap { LiveSport(rawValue: $0)?.symbol }
                            ?? "figure.strengthtraining.traditional",
                        tint: OG.accent
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(WorkoutListCaption.dayTimeLine(
                            for: selectedDay,
                            time: session.startedAt.map(SpanishDate.time)
                        ))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(OG.label3)
                        .tracking(0.3)
                        Text(session.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Self.registerCardPad)
            },
            chips: {
                if let meters = session.recordedDistanceMeters, meters > 0 {
                    OGRegisterChip(text: "\(ReperaNumberFormat.decimal(meters / 1000)) km", icon: "point.topleft.down.curvedto.point.bottomright.up")
                }
                WorkoutRegisterChips.repera(
                    session: session,
                    prCount: prs,
                    verifiedHealthKcal: session.healthKitWorkoutUUID.flatMap {
                        health.verifiedWorkoutEnergyKcal[$0]
                    }
                )
            }
        )
    }

    private func healthActivityCard(_ activity: HealthKitStore.ExternalActivity) -> some View {
        return registerCardWithChipsOverlay(
            open: { openHealthActivityId = activity.id },
            accessibilityHint: "Toca para ver el detalle de la actividad",
            deleteLabel: "Eliminar registro de Salud",
            onDelete: { healthPendingDelete = activity },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    OGRegisterLeadingIcon(systemName: activity.symbolName, tint: OG.red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(WorkoutListCaption.dayTimeLine(
                            for: selectedDay,
                            time: SpanishDate.time(activity.start)
                        ))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(OG.label3)
                        .tracking(0.3)
                        Text(activity.title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Self.registerCardPad)
            },
            chips: {
                WorkoutRegisterChips.health(activity)
            }
        )
    }

    /// Card con chips: la caja entera (chips incluidos) se desliza; gesto de borrar solo fuera del carrusel.
    private func registerCardWithChipsOverlay<Title: View>(
        open: @escaping () -> Void,
        accessibilityHint: String,
        deleteLabel: String,
        onDelete: @escaping () -> Void,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder chips: @escaping () -> some View
    ) -> some View {
        RegisterSwipeRevealCard(
            onOpen: open,
            onDelete: onDelete,
            deleteAccessibilityLabel: deleteLabel,
            cardBackground: OG.surface,
            minimumCardHeight: singleWorkoutMinHeight,
            title: title,
            chips: {
                OGRegisterChipsRow(leadingInset: Self.chipsTitleLeading) {
                    chips()
                }
                // La ScrollView horizontal no tiene altura intrínseca fija:
                // .frame(minHeight:) permitía crecer toda la banda y creaba
                // un hueco grande entre titular, chip y borde inferior.
                // Altura acotada idéntica al estado sin entrenamiento.
                .frame(height: 24, alignment: .center)
                .padding(.top, 0)
            }
        )
        .accessibilityHint(accessibilityHint)
    }

    /// Progressive window for dots / past-day metrics. Not tied to day selection.
    private func refreshProgressiveHealthIfNeeded() async {
        health.refreshAuthorizationStatus()
        // El permiso de LECTURA no puede consultarse mediante sharingAuthorized:
        // ejecutar la consulta y respetar un resultado vacío / denegado.
        guard health.isAvailable else { return }

        let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
        // Day swipe must not wait on a 2‑minute TTL — coverage + dirty flag is enough.
        if health.hasProgressiveCache,
           health.healthCacheCoverageDays >= 7,
           !health.healthNeedsRefresh {
            return
        }

        await health.refreshRecentExternalActivities(
            excludingUUIDs: linked,
            overlappingSessions: store.state.workouts
        )
    }

    /// Soft refine for today tiles only; never clears displayed cache while waiting.
    private func refineTodayMetricsInBackground() async {
        guard health.isAvailable, calendar.isDateInToday(selectedDay) else { return }
        let key = dayKey(selectedDay)
        let hasBuckets = kcalByDayKey[key] != nil || healthMinutesByDayKey[key] != nil
            || health.activeEnergyTodayKcal != nil
        if !hasBuckets {
            await health.refreshToday()
        }
        let live = await health.dayMetrics(for: selectedDay)
        guard calendar.isDateInToday(selectedDay) else { return }
        if live.activeEnergyKcal != nil || live.workoutMinutes != nil {
            todayHealthLive = live
        }
    }

    /// Padding del título; el carrusel va edge-to-edge dentro de la card.
    private static let registerCardPad: CGFloat = 14
    /// Card pad + icono 44 + gap 12 → chips alineados al título en reposo.
    private static let chipsTitleLeading: CGFloat = registerCardPad + 44 + 12

    private func openAddWorkoutPage(_ page: AddWorkoutPage) {
        // El sheet usa su propia animación de entrada/salida vertical;
        // la navegación push empieza únicamente después de onDismiss.
        guard showCreatePlanForDay, pendingAddWorkoutPage == nil else { return }
        pendingAddWorkoutPage = page
        showCreatePlanForDay = false
    }

    private func startPlannedDayIfPossible() {
        if calendar.isDateInToday(selectedDay), store.hasActiveSession {
            onStart()
            return
        }
        if let planned = plannedRoutineForSelectedDay {
            onStartRoutine(planned)
            return
        }
        showCreatePlanForDay = true
    }

    /// Calcula la semana (respecto de hoy) a la que pertenece el día pulsado.
    /// Las fechas visibles pueden avanzar día a día sin modificar la selección.
    private func weekOffset(for day: Date) -> Int {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = store.state.settings.weekStartsOn == .monday
            ? (weekday == 1 ? -6 : 2 - weekday)
            : 1 - weekday
        guard let weekStart = calendar.date(byAdding: .day, value: startOffset, to: today) else {
            return 0
        }
        let delta = calendar.dateComponents([.day], from: weekStart, to: day).day ?? 0
        return min(Self.weekCarouselRadius, max(-Self.weekCarouselRadius, Int(floor(Double(delta) / 7.0))))
    }

    private var dayActionRow: some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let planned = plannedRoutineForSelectedDay
        return Button {
            if isToday, store.hasActiveSession {
                onStart()
            } else if let planned {
                onStartRoutine(planned)
            } else {
                showCreatePlanForDay = true
            }
        } label: {
            dayActionRowContent
        }
        .buttonStyle(.plain)
    }

    /// Contenido de la fila de entreno del día (sin Button; usable con swipeActions).
    private var dayActionRowContent: some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let planned = plannedRoutineForSelectedDay
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(todayIconBg)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: todayIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(todayIconFg)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(WorkoutListCaption.dayTimeLine(for: selectedDay, time: selectedDayTimeLabel))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)
                Text(selectedDayTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isToday, store.hasActiveSession {
                    Text("Toca para continuar · desliza para eliminar")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label2)
                } else if planned != nil {
                    Text("Toca para abrir y empezar")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label2)
                } else if !hasCompletedActivityOnSelectedDay {
                    Text("Día libre · toca para añadir un entreno")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label2)
                } else {
                    Text("Toca para añadir un entreno")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label2)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OG.label3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metricTile(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        // El valor ocupa el alto libre sin dejar más aire abajo que encima de la cabecera.
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .top)
        .padding(12)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func setLine(_ set: LoggedSet) -> String {
        let w = set.weightKg.map { "\(ReperaNumberFormat.decimal($0, maximumFractionDigits: 0))kg" } ?? "PC"
        return "\(set.reps)×\(w)"
    }

    /// Como openGym: la racha abre el calendario/historial de entrenos (no Stats).
    private var streakCard: some View {
        NavigationLink {
            HistoryView()
        } label: {
            OGCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(OG.orange)
                            Text(cachedStreakTitle)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .tracking(-0.4)
                        }
                        Text(streakSubtitle(
                            weekDone: cachedStreakWeekDone,
                            planned: cachedStreakPlanned,
                            total: cachedStreakTotal
                        ))
                            .font(.system(size: 13))
                            .foregroundStyle(OG.label2)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(OG.label3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre el historial de entrenos")
    }

    // MARK: - Derived

    /// Solo entrenos ya terminados ese día (no borradores ni sesiones a medias).
    private var workoutsOnSelectedDay: [WorkoutSession] {
        workoutsByDayKey[dayKey(selectedDay)] ?? []
    }

    private func rebuildDayBuckets() {
        var workouts: [String: [WorkoutSession]] = [:]
        for w in store.state.workouts {
            // Una sesión en curso no es un entrenamiento terminado.
            // En actividades GPS la fecha corresponde al inicio, pero solo
            // después de tener confirmación de fin.
            guard let finishedAt = w.finishedAt else { continue }
            let day = w.liveSportID == nil ? finishedAt : (w.startedAt ?? finishedAt)
            workouts[dayKey(day), default: []].append(w)
        }
        // En Inicio, los entrenamientos del mismo día se leen en orden
        // cronológico: el más antiguo arriba y el más reciente abajo.
        for key in workouts.keys {
            workouts[key]?.sort {
                ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast)
            }
        }

        var healthMap: [String: [HealthKitStore.ExternalActivity]] = [:]
        var minutes: [String: Double] = [:]
        for activity in health.recentExternalActivities {
            let key = dayKey(activity.start)
            healthMap[key, default: []].append(activity)
            minutes[key, default: 0] += max(0, activity.durationMinutes)
        }
        for key in healthMap.keys {
            healthMap[key]?.sort { $0.start < $1.start }
        }

        var kcals: [String: Double] = [:]
        for point in health.recentDailyActiveEnergy where point.kcal > 0 {
            kcals[dayKey(point.date)] = point.kcal
        }

        workoutsByDayKey = workouts
        healthByDayKey = healthMap
        kcalByDayKey = kcals
        healthMinutesByDayKey = minutes.filter { $0.value > 0 }
    }

    /// Fuente única del punto y de la tarjeta del día: únicamente las
    /// sesiones terminadas de Repera y las actividades completadas de Salud.
    /// Ni la fecha seleccionada ni una rutina programada aportan un punto.
    private func hasCompletedWorkoutOnDay(_ key: String) -> Bool {
        !(workoutsByDayKey[key]?.isEmpty ?? true)
            || !(healthByDayKey[key]?.isEmpty ?? true)
    }

    private func rebuildWeekChrome() {
        cachedWeekDays = makeWeekDays(offset: weekOffset)
        cachedCalendarDays = (-Self.weekCarouselRadius...Self.weekCarouselRadius).flatMap { offset in
            makeWeekDays(offset: offset)
        }
        // En la primera apertura mostrar AYER a la izquierda y HOY
        // como segundo día, manteniendo hoy seleccionado. No volver a
        // reposicionar al regenerar métricas o deslizar el carrusel.
        if calendarScrollID == nil {
            let firstVisibleDate = calendar.date(byAdding: .day, value: -1, to: selectedDay)
                ?? selectedDay
            calendarScrollID = cachedCalendarDays.first(where: {
                calendar.isDate($0.date, inSameDayAs: firstVisibleDate)
            })?.iso ?? makeWeekDays(offset: 0).first?.iso
        }
    }

    private func rebuildStreakChrome() {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let healthWeek = health.recentExternalActivities.reduce(into: 0) { count, activity in
            if activity.start >= weekAgo { count += 1 }
        }
        cachedStreakWeekDone = StatsEngine.workoutCount(from: store.state.workouts, days: 7) + healthWeek
        cachedStreakPlanned = store.scheduledRoutines(inWeekContaining: Date()).count
        cachedStreakTotal = store.state.workouts.count + health.recentExternalActivities.count
        cachedStreakWeeks = consecutiveWeekStreak()
    }

    /// Excluir solo la rutina activa o ya terminada; las demás siguen
    /// visibles y se pueden comenzar aunque haya otro registro ese día.
    private var plannedRoutinesForSelectedDay: [Routine] {
        let completedIDs = Set(workoutsOnSelectedDay.compactMap(\.routineId))
        let activeID = calendar.isDateInToday(selectedDay)
            ? store.state.activeSession?.routineId : nil
        return store.scheduledRoutines(on: selectedDay).filter {
            !completedIDs.contains($0.id) && $0.id != activeID
        }
    }

    private var plannedRoutineForSelectedDay: Routine? {
        plannedRoutinesForSelectedDay.first
    }

    private var plannedTitleForSelectedDay: String? {
        plannedRoutineForSelectedDay?.title
    }

    /// Hay algo completado ese día (Repera o Salud visible).
    private var hasCompletedActivityOnSelectedDay: Bool {
        !workoutsOnSelectedDay.isEmpty || !healthActivities.isEmpty
    }

    private var selectedDayTitle: String {
        if calendar.isDateInToday(selectedDay), store.hasActiveSession {
            let name = store.continueAccessory?.title ?? "Entreno"
            return "\(name) (en curso)"
        }
        if let done = workoutsOnSelectedDay.first {
            return done.title
        }
        // Actividad de Apple Salud = día trabajado, no descanso.
        if let health = healthActivities.first {
            return health.title
        }
        // Plan solo si aún no hay registro completado.
        if let planned = plannedRoutineForSelectedDay {
            return planned.title
        }
        return "Día de descanso"
    }

    /// Hora a la derecha del día (no en el título) para dejar ancho al nombre del entreno.
    private var selectedDayTimeLabel: String? {
        if calendar.isDateInToday(selectedDay), store.hasActiveSession {
            return nil
        }
        if let done = workoutsOnSelectedDay.first, let start = done.startedAt {
            return SpanishDate.time(start)
        }
        if let health = healthActivities.first {
            return SpanishDate.time(health.start)
        }
        if let planned = plannedRoutineForSelectedDay,
           let minutes = planned.normalizedScheduledTimeMinutes {
            return SpanishDate.time(minutesFromMidnight: minutes)
        }
        return nil
    }

    private var todayIconBg: Color {
        if calendar.isDateInToday(selectedDay), store.hasActiveSession { return OG.orange }
        if calendar.isDateInToday(selectedDay), store.routineForToday() != nil { return OG.accent }
        return OG.surface3
    }

    private var todayIconFg: Color {
        if calendar.isDateInToday(selectedDay),
           store.hasActiveSession || store.routineForToday() != nil {
            return Color.black
        }
        return OG.label2
    }

    private var todayIcon: String {
        if calendar.isDateInToday(selectedDay), store.hasActiveSession { return "play.fill" }
        if hasCompletedActivityOnSelectedDay { return "checkmark" }
        if plannedTitleForSelectedDay != nil { return "figure.strengthtraining.traditional" }
        return "moon.fill"
    }

    private var cachedStreakTitle: String {
        if cachedStreakWeeks == 0 { return "Sin racha todavía" }
        return cachedStreakWeeks == 1 ? "Racha de 1 semana" : "Racha de \(cachedStreakWeeks) semanas"
    }

    private func streakSubtitle(weekDone: Int, planned: Int, total: Int) -> String {
        if total == 0 { return "Cuando entrenes, verás aquí tu progreso" }
        if planned > 0 {
            return "\(weekDone) / \(planned) esta semana · \(total) entrenos en total"
        }
        return "\(weekDone) esta semana · \(total) entrenos en total"
    }

    /// Semanas consecutivas con al menos un entreno (Repera o Salud), como openGym `streakWeeks`.
    private func consecutiveWeekStreak() -> Int {
        var weekCal = calendar
        weekCal.firstWeekday = store.state.settings.weekStartsOn == .monday ? 2 : 1

        var activeWeeks = Set<String>()
        for w in store.state.workouts {
            guard let d = w.finishedAt ?? w.startedAt else { continue }
            activeWeeks.insert(weekKey(d, calendar: weekCal))
        }
        for activity in health.recentExternalActivities {
            activeWeeks.insert(weekKey(activity.start, calendar: weekCal))
        }
        guard !activeWeeks.isEmpty else { return 0 }

        var streak = 0
        var cursor = Date()
        for i in 0..<520 {
            let key = weekKey(cursor, calendar: weekCal)
            if activeWeeks.contains(key) {
                streak += 1
            } else if i > 0 {
                break
            }
            guard let prev = weekCal.date(byAdding: .day, value: -7, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private func weekKey(_ date: Date, calendar: Calendar) -> String {
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-\(week)"
    }

    private struct DayCell {
        var iso: String
        var date: Date
        var lbl: String
        var num: Int
        var hasWorkout: Bool
        var hasPlan: Bool
    }

    /// Actualiza el mes conforme se desplazan las casillas visibles.
    /// Se toma el centro del grupo de siete días para los cambios entre meses.
    private var visibleCalendarMonthTitle: String {
        let leading = cachedCalendarDays.first(where: { $0.iso == calendarScrollID })?.date
            ?? selectedDay
        let center = calendar.date(byAdding: .day, value: 3, to: leading) ?? leading
        return SpanishDate.monthHeadline(from: center, to: center, calendar: calendar)
    }

    private func makeWeekDays(offset: Int) -> [DayCell] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = store.state.settings.weekStartsOn == .monday
            ? (weekday == 1 ? -6 : 2 - weekday)
            : 1 - weekday
        guard var start = calendar.date(byAdding: .day, value: startOffset + offset * 7, to: today) else {
            return []
        }
        start = calendar.startOfDay(for: start)
        let labels: [String] = store.state.settings.weekStartsOn == .monday
            ? ["LU", "MA", "MI", "JU", "VI", "SA", "DO"]
            : ["DO", "LU", "MA", "MI", "JU", "VI", "SA"]

        // Un solo pase de rutinas → keys de plan de la semana visible.
        var planKeys = Set<String>()
        let weekDates: [Date] = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        for routine in store.state.routines {
            guard let scheduled = routine.scheduledDate else { continue }
            if weekDates.contains(where: { calendar.isDate($0, inSameDayAs: scheduled) }) {
                planKeys.insert(dayKey(scheduled))
            }
        }

        return weekDates.enumerated().map { i, d in
            let dayStart = calendar.startOfDay(for: d)
            let key = dayKey(dayStart)
            return DayCell(
                iso: key,
                date: dayStart,
                lbl: labels[i],
                num: calendar.component(.day, from: d),
                hasWorkout: hasCompletedWorkoutOnDay(key),
                hasPlan: planKeys.contains(key)
            )
        }
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
}
