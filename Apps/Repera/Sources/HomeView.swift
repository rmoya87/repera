import ReperaDomain
import SwiftUI
import UIKit

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
    /// Keep the 735-day carousel stable while selecting days or returning from detail.
    @State private var didBuildDayBuckets = false
    @State private var didBuildCalendarChrome = false
    @State private var lastCalendarWeekStartsOn: WeekStart?
    @State private var didBuildStreakChrome = false
    @State private var lastProcessedWorkoutsEpoch: UInt64?
    @State private var lastProcessedHealthRevision: Int?
    /// A selected week is only seven cells; the full carousel changes on data mutations.
    @State private var cachedCalendarLookup = CalendarDayLookup(
        planned: [], trainerPlans: [], bookings: []
    )
    @State private var stepsByDayKey: [String: Int] = [:]
    @State private var stepsCacheRevision = -1
    @State private var isExpandedLayout = false
    @State private var showSettingsPanel = false
    @State private var cachedAvatarJPEG: Data?
    @State private var cachedAvatarImage: UIImage?
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
    /// Solo rutinas personales persistidas; prescripciones profesionales no se editan.
    @State private var editingOwnRoutine: Routine?
    @State private var editingOwnSessionID: UUID?
    /// Build the historical editor only when tapped, not in a navigation builder.
    @State private var editingOwnSessionRoutine: Routine?
    @State private var healthPendingDelete: HealthKitStore.ExternalActivity?
    @State private var openWorkoutId: UUID?
    @State private var openProfessionalSessionId: UUID?
    @State private var openBusinessBookingId: UUID?
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
    @State private var calendarDatesByKey: [String: Date] = [:]
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

    /// Appointments and trainer plans share the normal day's workout section.
    /// A reservation with a published plan has ONE card, using that plan in detail.
    private var selectedDayBusinessBookings: [BusinessBooking] {
        // Avoid a linear occurrence lookup for every booking on each day tap.
        // The original nested scan was O(bookings × occurrences).
        let occurrencesByID = Dictionary(
            businessData.occurrences.map { ($0.id, $0.startsAt) },
            uniquingKeysWith: { _, latest in latest }
        )
        let selected = calendar.startOfDay(for: selectedDay)
        return businessData.bookings.filter { booking in
            guard booking.status == "booked",
                  let startsAt = occurrencesByID[booking.occurrenceId],
                  let date = BusinessDataStore.date(startsAt) else { return false }
            return calendar.isDate(date, inSameDayAs: selected)
        }
    }

    private var selectedDayProfessionalSessions: [BusinessProfessionalTrainingSession] {
        let day = BusinessDataStore.localDayKey(selectedDay)
        let reserved = Set(selectedDayBusinessBookings.map(\.occurrenceId))
        return businessData.trainingSessions.filter {
            $0.scheduledDate == day &&
                ($0.sourceOccurrenceId.map { !reserved.contains($0) } ?? true)
        }
    }

    /// Las fechas de la planificación cambian independientemente de los
    /// entrenos completados. No usar workoutsEpoch para cada edición del plan.
    private var scheduledCalendarSignature: Int {
        var hasher = Hasher()
        for routine in store.state.routines {
            guard let date = routine.scheduledDate else { continue }
            hasher.combine(routine.id)
            hasher.combine(calendar.startOfDay(for: date))
        }
        return hasher.finalize()
    }

    private var businessCalendarSignature: Int {
        // Avoid allocating, sorting and joining large strings on every
        // render when a day has several local or professional workouts.
        var hasher = Hasher()
        hasher.combine(businessData.trainingSessions.count)
        for entry in businessData.trainingSessions {
            hasher.combine(entry.id)
            hasher.combine(entry.scheduledDate)
            hasher.combine(entry.status)
        }
        hasher.combine(businessData.bookings.count)
        for booking in businessData.bookings {
            hasher.combine(booking.id)
            hasher.combine(booking.occurrenceId)
            hasher.combine(booking.status)
        }
        hasher.combine(businessData.occurrences.count)
        for occurrence in businessData.occurrences {
            hasher.combine(occurrence.id)
            hasher.combine(occurrence.startsAt)
            hasher.combine(occurrence.status)
        }
        return hasher.finalize()
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
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: isExpandedLayout ? .infinity : OG.contentColumnMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    // En paisaje la safe area lateral pertenece al gris de
                    // Progreso/Actividad; el blanco solo es calendario + entreno.
                    .background(OG.bg.ignoresSafeArea(edges: [.horizontal, .bottom]))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Durante una recarga o navegación, el ScrollView aún no ha
            // compuesto sus tarjetas. Su fondo no puede ser negro mientras
            // la topbar y el calendario usan OG.surface.
            // La sección Progreso/Actividad pinta OG.bg hasta abajo.
            .background(OG.surface.ignoresSafeArea())
            .onGeometryChange(for: Bool.self, of: { $0.size.width >= 620 }) { _, expanded in
                isExpandedLayout = expanded
                if !expanded { showSettingsPanel = false }
            }
            .refreshable { await businessData.refresh(); rebuildWeekChrome() }
            .onChange(of: businessCalendarSignature) { _, _ in
                rebuildWeekChrome()
            }
            .onChange(of: scheduledCalendarSignature) { _, _ in
                rebuildWeekChrome()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("repera.professionalPlansChanged"))) { _ in
                rebuildWeekChrome()
            }
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
            // Do not reveal the system's black background between a topbar
            // refresh and re-layout of the calendar cards. The content below
            // still paints its own grouped OG.bg surface.
            .background(OG.surface.ignoresSafeArea())
            .onAppear {
                LaunchTiming.mark("HomeView.onAppear")
                refreshAvatarIfNeeded()
                if let focusDay, focusDay != lastAppliedFocusDay {
                    lastAppliedFocusDay = focusDay
                    selectedDay = calendar.startOfDay(for: focusDay)
                }
                // Con diskPaint, workouts ya están en store (mismo ritmo que Salud).
                if !didBuildDayBuckets { rebuildDayBuckets() }
                if !didBuildCalendarChrome ||
                   lastCalendarWeekStartsOn != store.state.settings.weekStartsOn {
                    rebuildWeekChrome()
                }
                // Reentrar desde un detalle no debe recalcular rachas y PRs
                // ni regenerar el calendario. Los epochs actualizan cambios reales.
                if !didBuildStreakChrome {
                    Task(priority: .utility) {
                        rebuildStreakChrome()
                        prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                    }
                }
                Task(priority: .utility) {
                    health.refreshAuthorizationStatus()
                }
            }
            .onChange(of: store.state.settings.profileAvatarJPEG) { _, _ in
                refreshAvatarIfNeeded()
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
                    // Al volver de la hoja Crear puede seguir visible el
                    // Home anterior. Forzar el nuevo registro y el punto
                    // del calendario sin esperar una nueva aparición de la tab.
                    rebuildDayBuckets()
                    rebuildWeekChrome()
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
                rebuildSelectedWeekChrome()
            }
            .onChange(of: store.state.settings.weekStartsOn) { _, _ in
                rebuildWeekChrome()
            }
            .onChange(of: health.isAuthorized) { _, authorized in
                if authorized {
                    Task(priority: .utility) { await refreshProgressiveHealthIfNeeded() }
                }
            }
            // Personal-record calculations depend on the workout history,
            // not on every HealthKit authorization/sample callback.
            .task(id: store.workoutsEpoch) {
                // A cancelled navigation task must be allowed to retry:
                // mark the epoch handled only after its async work completes.
                let epoch = store.workoutsEpoch
                guard lastProcessedWorkoutsEpoch != epoch else { return }
                rebuildDayBuckets()
                rebuildWeekChrome()
                await Task.yield()
                guard !Task.isCancelled else { return }
                rebuildStreakChrome()
                prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                await health.refreshVerifiedWorkoutEnergy(for: store.state.workouts)
                guard !Task.isCancelled else { return }
                lastProcessedWorkoutsEpoch = epoch
            }
            .task(id: health.healthDataRevision) {
                let revision = health.healthDataRevision
                guard lastProcessedHealthRevision != revision else { return }
                // Health changes update calories/minutes and the day dots,
                // but should never repeat personal-record analysis.
                rebuildDayBuckets()
                rebuildWeekChrome()
                await Task.yield()
                guard !Task.isCancelled else { return }
                rebuildStreakChrome()
                lastProcessedHealthRevision = revision
            }
            .task(id: "\(dayKey(selectedDay))-\(health.healthDataRevision)-\(health.isAuthorized)") {
                let requestedDay = selectedDay
                let requestedKey = dayKey(requestedDay)
                if stepsCacheRevision != health.healthDataRevision {
                    stepsByDayKey.removeAll(keepingCapacity: true)
                    stepsCacheRevision = health.healthDataRevision
                }
                if let cached = stepsByDayKey[requestedKey] {
                    selectedDaySteps = cached
                    return
                }
                selectedDaySteps = nil
                // Inicio muestra UN día, no una serie de siete consultas a HK.
                let steps = await health.steps(for: requestedDay)
                guard !Task.isCancelled, dayKey(selectedDay) == requestedKey else { return }
                if let steps { stepsByDayKey[requestedKey] = steps }
                selectedDaySteps = steps
            }
            // Salud diferida: no bloquear el primer paint de Inicio.
            .task(id: store.isHydrated) {
                guard store.isHydrated else { return }
                if !didBuildCalendarChrome { rebuildWeekChrome() }
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
                    FavoritesHubView(
                        onOpenedWorkout: {
                            restoresAddSheetAfterPage = false
                            addWorkoutPage = nil
                            onOpenWorkout()
                        },
                        targetDate: selectedDay,
                        onScheduledWorkout: {
                            // Añadir la copia a ese día y regresar al calendario.
                            restoresAddSheetAfterPage = false
                            addWorkoutPage = nil
                        }
                    )
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
            .navigationDestination(item: $editingOwnRoutine) { routine in
                DayEditorView(
                    routine: routine,
                    mode: .oneOff(isNew: false),
                    onClose: { editingOwnRoutine = nil },
                    embedsNavigationStack: false,
                    usesPageCloseHeader: true
                )
            }
            .navigationDestination(isPresented: Binding(
                get: { editingOwnSessionID != nil },
                set: { if !$0 { editingOwnSessionID = nil } }
            )) {
                if let id = editingOwnSessionID,
                   let session = store.state.workouts.first(where: { $0.id == id }),
                   let editingOwnSessionRoutine {
                    DayEditorView(
                        routine: editingOwnSessionRoutine,
                        mode: .session,
                        onClose: { editingOwnSessionID = nil },
                        onApplyCompleted: { routine, details in
                            let updated = CompletedWorkoutEditing.applying(
                                routine, to: details, catalog: store.state.exercises
                            )
                            store.saveWorkout(updated)
                            rebuildDayBuckets()
                            rebuildWeekChrome()
                            rebuildStreakChrome()
                            prCountBySessionId = store.cachedPersonalRecordCountsBySession()
                        },
                        completedSession: session,
                        embedsNavigationStack: false,
                        usesPageCloseHeader: true
                    )
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
                get: { openProfessionalSessionId != nil },
                set: { if !$0 { openProfessionalSessionId = nil } }
            )) {
                if let id = openProfessionalSessionId,
                   let session = businessData.trainingSessions.first(where: { $0.id == id }) {
                    BusinessProfessionalSessionDetailView(session: session)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { openBusinessBookingId != nil },
                set: { if !$0 { openBusinessBookingId = nil } }
            )) {
                if let id = openBusinessBookingId,
                   let booking = businessData.bookings.first(where: { $0.id == id }),
                   let occurrence = businessData.occurrences.first(where: { $0.id == booking.occurrenceId }) {
                    BusinessBookedOccurrenceDetailView(booking: booking, occurrence: occurrence)
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
        let photo = cachedAvatarImage
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

    private func refreshAvatarIfNeeded() {
        let jpeg = store.state.settings.profileAvatarJPEG
        guard jpeg != cachedAvatarJPEG else { return }
        cachedAvatarJPEG = jpeg
        cachedAvatarImage = ProfileAvatar.uiImage(from: jpeg)
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
                // Enseñar solo el extremo derecho del día anterior. Su
                // recorte no debe alterar el ancho de cada casilla ni la
                // posición inicial que restaura scrollPosition.
                let leadingPeek = side * 0.7
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
                // El scroll comienza 70 % de casilla antes del borde visible.
                // Se amplía su viewport lo mismo para no dejar un hueco a la
                // derecha y se recorta al ancho real del calendario.
                .frame(width: geo.size.width + leadingPeek, alignment: .leading)
                .offset(x: -leadingPeek)
            }
            .frame(height: weekCarouselHeight)
            .clipped()
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
        let isToday = calendar.isDateInToday(day.date)
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
            // Mismo punto para entrenos realizados y planes de hoy o futuro.
            // No convertir planes pasados sin realizar en registros completados.
            let isTodayOrFuture = calendar.startOfDay(for: day.date)
                >= calendar.startOfDay(for: Date())
            if hasCompletedWorkout || (isTodayOrFuture && day.hasPlan) {
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
                    .strokeBorder(
                        isToday ? OG.accent : OG.surface3.opacity(0.75),
                        lineWidth: isToday ? 1.5 : 0.7
                    )
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
        let businessBookings = selectedDayBusinessBookings
        let professionalPlans = selectedDayProfessionalSessions

        LazyVStack(spacing: 6) {
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
            // Published professional plans and confirmed bookings have the same
            // card hierarchy as private workouts; no extra sections below Activity.
            ForEach(professionalPlans) { session in
                businessDayCard(
                    title: session.title,
                    label: "Entreno " + businessData.centerName(session.orgId),
                    time: session.scheduledTimeMinutes.map { SpanishDate.time(minutesFromMidnight: $0) },
                    symbol: "figure.strengthtraining.traditional",
                    summary: session.prescription.map { "\($0.blocks.count) bloq." } ?? "Entrenador",
                    action: { openProfessionalSessionId = session.id }
                )
                .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
            }
            ForEach(businessBookings) { booking in
                if let occurrence = businessData.occurrences.first(where: { $0.id == booking.occurrenceId }) {
                    businessDayCard(
                        title: occurrence.title,
                        label: (occurrence.kind == "class" ? "Clase " : "Entreno ") + businessData.centerName(occurrence.orgId),
                        time: BusinessDataStore.date(occurrence.startsAt).map { SpanishDate.time($0) },
                        symbol: occurrence.kind == "class" ? "figure.group" : "person.crop.circle",
                        summary: occurrence.kind == "class" ? "Reserva confirmada" : "Cita confirmada",
                        action: { openBusinessBookingId = booking.id }
                    )
                    .frame(minHeight: singleWorkoutMinHeight, alignment: .center)
                }
            }
            if !hasActive && workouts.isEmpty && planned.isEmpty
                && businessBookings.isEmpty && professionalPlans.isEmpty && !hasCompletedActivity {
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

    /// A read-only, tappable professional card in the native daily workout design.
    private func businessDayCard(
        title: String,
        label: String,
        time: String?,
        symbol: String,
        summary: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 12) {
                    OGRegisterLeadingIcon(systemName: symbol, tint: OG.label2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(WorkoutListCaption.dayTimeLine(for: selectedDay, time: time))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(OG.label3)
                            .tracking(0.3)
                        Text(title)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(OG.label)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(label + (time.map { " – " + $0 } ?? ""))
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OG.label3)
                }
                .padding(.horizontal, Self.registerCardPad)
                HStack(spacing: 7) {
                    OGRegisterChip(text: summary, icon: "calendar")
                }
                .padding(.leading, Self.chipsTitleLeading)
                .frame(height: 24, alignment: .center)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: singleWorkoutMinHeight, alignment: .center)
            .background(OG.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(OG.surface3.opacity(0.75), lineWidth: 0.7)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Toca para ver el detalle del entrenamiento o reserva")
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

    /// La autorización de edición se basa en el tipo/fuente del registro:
    /// entrenos propios del store, nunca prescripciones de BusinessDataStore.
    private func editOwnPlannedRoutine(_ routine: Routine) {
        guard let saved = store.state.routines.first(where: { $0.id == routine.id }),
              saved.scheduledDate != nil else { return }
        editingOwnRoutine = saved
    }

    private func editOwnCompletedWorkout(_ session: WorkoutSession) {
        guard let saved = store.state.workouts.first(where: { $0.id == session.id }) else { return }
        editingOwnSessionRoutine = CompletedWorkoutEditing.routine(
            from: saved,
            sourceRoutine: saved.routineId.flatMap { routineId in
                store.state.routines.first(where: { $0.id == routineId })
            }
        )
        editingOwnSessionID = saved.id
    }

    /// Entreno planificado del día (aún sin sesión hecha): edición solo local.
    private func plannedDayCard(_ routine: Routine) -> some View {
        return registerCardWithChipsOverlay(
            open: { onStartRoutine(routine) },
            accessibilityHint: "Toca para abrir. Desliza a la derecha para editar o a la izquierda para borrar.",
            deleteLabel: "Borrar entreno del día",
            onDelete: { routinePendingDelete = routine },
            onEdit: { editOwnPlannedRoutine(routine) },
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
            onEdit: session.timerDetails == nil ? { editOwnCompletedWorkout(session) } : nil,
            title: {
                HStack(alignment: .top, spacing: 12) {
                    // Completado: mismo símbolo que un plan gris, en verde.
                    // Las actividades de Comenzar mantienen su icono deportivo.
                    OGRegisterLeadingIcon(
                        systemName: session.timerDetails != nil ? "timer"
                            : (session.liveSportID.flatMap { LiveSport(rawValue: $0)?.symbol }
                                ?? "figure.strengthtraining.traditional"),
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
        onEdit: (() -> Void)? = nil,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder chips: @escaping () -> some View
    ) -> some View {
        RegisterSwipeRevealCard(
            onOpen: open,
            onDelete: onDelete,
            onEdit: onEdit,
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

    /// La tarjeta de racha abre el historial unificado de entrenamientos.
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
            // El cronómetro se registra en el día en que empezó,
            // incluso si cruzó medianoche; igual que un deporte en vivo.
            let day = (w.liveSportID != nil || w.timerDetails != nil)
                ? (w.startedAt ?? finishedAt) : finishedAt
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
        didBuildDayBuckets = true
    }

    /// Completado significa actividad real de Repera o Salud. Los puntos
    /// de planificación futura se representan por separado en el calendario,
    /// sin sumar a las estadísticas ni a las rachas.
    private func hasCompletedWorkoutOnDay(_ key: String) -> Bool {
        !(workoutsByDayKey[key]?.isEmpty ?? true)
            || !(healthByDayKey[key]?.isEmpty ?? true)
    }

    private func rebuildSelectedWeekChrome() {
        // Selecting a square never rebuilds the year-long horizontal carousel.
        cachedWeekDays = makeWeekDays(offset: weekOffset, lookup: cachedCalendarLookup)
    }

    private func rebuildWeekChrome() {
        // Full reconstruction is reserved for actual workout/plan/Health changes.
        let lookup = makeCalendarDayLookup()
        cachedCalendarLookup = lookup
        cachedWeekDays = makeWeekDays(offset: weekOffset, lookup: lookup)
        cachedCalendarDays = (-Self.weekCarouselRadius...Self.weekCarouselRadius).flatMap { offset in
            makeWeekDays(offset: offset, lookup: lookup)
        }
        calendarDatesByKey = Dictionary(
            cachedCalendarDays.map { ($0.iso, $0.date) },
            uniquingKeysWith: { _, latest in latest }
        )
        didBuildCalendarChrome = true
        lastCalendarWeekStartsOn = store.state.settings.weekStartsOn
        // En la primera apertura posicionar AYER como objetivo del scroll;
        // el viewport muestra solo su parte final y HOY queda como primera
        // casilla completa. No volver a
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
        didBuildStreakChrome = true
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

    /// Semanas consecutivas con al menos un entreno registrado en Repera o Salud.
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
        // scrollPosition can change on every drag frame; lookup is O(1)
        // instead of scanning the entire 735-day carousel each time.
        let leading = calendarScrollID.flatMap { calendarDatesByKey[$0] } ?? selectedDay
        let center = calendar.date(byAdding: .day, value: 3, to: leading) ?? leading
        return SpanishDate.monthHeadline(from: center, to: center, calendar: calendar)
    }

    private struct CalendarDayLookup {
        var planned: Set<String>
        var trainerPlans: Set<String>
        var bookings: Set<String>
    }

    private func makeCalendarDayLookup() -> CalendarDayLookup {
        let planned = Set(store.state.routines.compactMap { $0.scheduledDate }.map(dayKey))
        let professional = Set(businessData.trainingSessions.map(\.scheduledDate))
        var startsByOccurrence: [UUID: String] = [:]
        startsByOccurrence.reserveCapacity(businessData.occurrences.count)
        for occurrence in businessData.occurrences {
            if let date = BusinessDataStore.date(occurrence.startsAt) {
                startsByOccurrence[occurrence.id] = BusinessDataStore.localDayKey(date)
            }
        }
        let bookings = Set(businessData.bookings.compactMap { booking -> String? in
            guard booking.status == "booked" else { return nil }
            return startsByOccurrence[booking.occurrenceId]
        })
        return CalendarDayLookup(
            planned: planned, trainerPlans: professional, bookings: bookings
        )
    }

    private func makeWeekDays(
        offset: Int, lookup: CalendarDayLookup? = nil
    ) -> [DayCell] {
        let indexed = lookup ?? makeCalendarDayLookup()
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

        let weekDates: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
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
                hasPlan: indexed.planned.contains(key) ||
                    indexed.trainerPlans.contains(BusinessDataStore.localDayKey(d)) ||
                    indexed.bookings.contains(BusinessDataStore.localDayKey(d))
            )
        }
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
}
