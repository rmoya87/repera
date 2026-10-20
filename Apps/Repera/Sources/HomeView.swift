import ReperaDomain
import SwiftUI

/// Inicio: semana seleccionable + métricas del día + registros.
struct HomeView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    @Environment(BusinessDataStore.self) private var businessData
    var onOpenWorkout: () -> Void
    var onStart: () -> Void
    /// Abre el preview / inicio de un entreno concreto (p. ej. suelto del viernes).
    var onStartRoutine: (Routine) -> Void = { _ in }
    var onGoPlan: () -> Void
    var onOpenStartHub: () -> Void

    /// 0 = semana actual; negativo = pasadas; positivo = futuras. Carrusel horizontal.
    @State private var weekOffset = 0
    /// Rango de páginas del carrusel (±1 año).
    private static let weekCarouselRadius = 52
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    /// Live refine for **today** only (HK query). Past days use bucket metrics — never wait on HealthKit to paint.
    @State private var todayHealthLive = HealthKitStore.DayMetrics()
    @State private var showCreatePlanForDay = false
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
    @State private var healthActiveDayKeys: Set<String> = []
    @State private var kcalByDayKey: [String: Double] = [:]
    @State private var healthMinutesByDayKey: [String: Double] = [:]
    @State private var prCountBySessionId: [UUID: Int] = [:]
    /// Semana / racha precalculados — cambiar de día no recalcula dots ni streak.
    @State private var cachedWeekDays: [DayCell] = []
    @State private var cachedWeekMonthTitle = "—"
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

    private var dayHealth: HealthKitStore.DayMetrics {
        let key = dayKey(selectedDay)
        if calendar.isDateInToday(selectedDay) {
            return HealthKitStore.DayMetrics(
                activeEnergyKcal: todayHealthLive.activeEnergyKcal
                    ?? health.activeEnergyTodayKcal
                    ?? kcalByDayKey[key],
                workoutMinutes: todayHealthLive.workoutMinutes
                    ?? health.workoutMinutesToday
                    ?? healthMinutesByDayKey[key]
            )
        }
        return HealthKitStore.DayMetrics(
            activeEnergyKcal: kcalByDayKey[key],
            workoutMinutes: healthMinutesByDayKey[key]
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
                VStack(alignment: .leading, spacing: 12) {
                    weekAndDayCard
                    professionalSessionsForSelectedDay
                    confirmedBusinessBookingsCard
                    streakCard
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 0)
                .padding(.bottom, 28)
            }
            .background(OG.bg)
            .refreshable { await businessData.refresh() }
            .ogFixedTopBar("repera", subtitle: SpanishDate.long(selectedDay)) {
                OGToolbarGlassButton(
                    systemName: "plus",
                    accessibilityLabel: "Crear entreno, apuntar series o escanear pizarra",
                    appliesGlass: true,
                    action: onOpenStartHub
                )
                NavigationLink {
                    SettingsView()
                } label: {
                    iCloudAvatar
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ajustes y cuenta iCloud")
            }
            .onAppear {
                LaunchTiming.mark("HomeView.onAppear")
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
            .onChange(of: selectedDay) { _, newDay in
                if calendar.isDateInToday(newDay) {
                    Task(priority: .utility) { await refineTodayMetricsInBackground() }
                }
            }
            .onChange(of: weekOffset) { _, _ in
                rebuildWeekChrome()
                snapSelectedDayToVisibleWeek()
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
            .sheet(isPresented: $showCreatePlanForDay) {
                DayPlusSheet(
                    targetDate: selectedDay,
                    onGoPlan: {
                        showCreatePlanForDay = false
                        onGoPlan()
                    },
                    onStartedWorkout: {
                        showCreatePlanForDay = false
                        onOpenWorkout()
                    },
                    onBoardReady: { payload in
                        showCreatePlanForDay = false
                        // Empujar página tras cerrar el sheet.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(280))
                            boardReviewPayload = payload
                        }
                    }
                )
                .preferredColorScheme(.light)
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
                        if routine.isOneOff {
                            store.deleteRoutine(routine.id)
                        } else {
                            store.assignRoutine(routine.id, toWeekday: nil)
                        }
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
    }

    @ViewBuilder
    private var iCloudAvatar: some View {
        let synced = store.iCloudStatus == .available
        let photo = ProfileAvatar.uiImage(from: store.state.settings.profileAvatarJPEG)
        // Sin glassEffect: el halo liquid glass sobresalía por encima de «repera».
        Color.clear
            .overlay {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let iconSize = synced ? side * 0.42 : side * 0.34
                    ZStack {
                        Circle()
                            .fill(synced || photo != nil ? OG.accent.opacity(0.22) : OG.surface2)
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
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
                }
            }
    }

    /// Semana + detalle del día en un solo bloque.
    private var weekAndDayCard: some View {
        let workouts = workoutsOnSelectedDay
        let durationMin = max(
            workouts.reduce(0.0) { $0 + sessionMinutes($1) },
            dayHealth.workoutMinutes ?? 0
        )
        let kcal = healthKcal(for: workouts, durationMin: durationMin)
        let dayScore: Int? = {
            let scores = workouts.compactMap(\.sessionReview?.overallScore)
            return scores.max()
        }()

        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            weekOffset = max(weekOffset - 1, -Self.weekCarouselRadius)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .frame(width: 30, height: 30)
                    }
                    .disabled(weekOffset <= -Self.weekCarouselRadius)
                    Spacer()
                    Text(visibleWeekMonthTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(OG.label2)
                    Spacer()
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            weekOffset = min(weekOffset + 1, Self.weekCarouselRadius)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .frame(width: 30, height: 30)
                    }
                    .disabled(weekOffset >= Self.weekCarouselRadius)
                }

                // Carrusel: swipe horizontal entre semanas (misma fila de 7 días).
                // `buildDays` se evalúa en el body de la página (TabView solo pide las visibles).
                TabView(selection: $weekOffset) {
                    ForEach(-Self.weekCarouselRadius...Self.weekCarouselRadius, id: \.self) { offset in
                        WeekCarouselPage(
                            selectedDay: $selectedDay,
                            calendar: calendar,
                            buildDays: { makeWeekDays(offset: offset) },
                            dayDot: dayDot
                        )
                        .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 72)

                dayEntrenoStack(workouts: workouts)

                HStack(spacing: 10) {
                    metricTile(title: "Kcal", value: kcal.map { "\(Int($0.rounded()))" } ?? "—", icon: "flame.fill", tint: OG.orange)
                    metricTile(title: "Tiempo", value: durationMin > 0 ? "\(Int(durationMin.rounded()))′" : "—", icon: "clock.fill", tint: OG.blue)
                    metricTile(
                        title: "Nota",
                        value: dayScore.map { "\($0)/10" } ?? "—",
                        icon: dayScore.map { SessionReview.scoreSymbolName(for: $0) } ?? "star.circle",
                        tint: OG.accent
                    )
                }
            }
        }
    }

    /// Entreno del día: sesión hecha (swipe eliminar), Salud (swipe eliminar), o descanso / plan.
    @ViewBuilder
    private func dayEntrenoStack(workouts: [WorkoutSession]) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let hasActive = isToday && store.hasActiveSession
        let hasCompletedActivity = !workouts.isEmpty || !healthActivities.isEmpty

        VStack(spacing: 10) {
            if hasActive {
                Button(action: onStart) {
                    dayActionRowContent
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    OGSwipeDeleteButton(accessibilityLabel: "Descartar entreno en curso") {
                        store.endActiveSession(save: false)
                    }
                }
            } else if !workouts.isEmpty {
                ForEach(workouts) { session in
                    dayWorkoutCard(session)
                }
            } else if let planned = plannedRoutineForSelectedDay {
                // Planificado (aún sin registro): swipe borrar como en entrenos pasados.
                plannedDayCard(planned)
            } else if !hasCompletedActivity {
                // Día libre → añadir.
                dayActionRow
            }

            ForEach(healthActivities) { activity in
                healthActivityCard(activity)
            }

            // Ya hay algo ese día → permitir sumar otro entreno.
            if hasCompletedActivity, !hasActive {
                addAnotherWorkoutButton
            }
        }
        .swipeActionsContainer()
    }

    private var addAnotherWorkoutButton: some View {
        Button {
            showCreatePlanForDay = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(OG.accent)
                Text("Añadir nuevo entreno")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OG.label)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Entreno planificado del día (aún sin sesión hecha): mismo swipe de borrar que los registros.
    private func plannedDayCard(_ routine: Routine) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        return registerCardWithChipsOverlay(
            open: { onStartRoutine(routine) },
            accessibilityHint: "Toca para abrir el entreno. Desliza para borrarlo de este día.",
            deleteLabel: "Borrar entreno del día",
            onDelete: { routinePendingDelete = routine },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(todayIconBg)
                        Image(systemName: todayIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(todayIconFg)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayLabelWithTime(isToday: isToday, time: selectedDayTimeLabel))
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
                    registerChip("\(blockCount) bloq.", icon: "square.stack.3d.up")
                }
                if let wod = routine.blocks.first(where: { $0.kind == .wod }) {
                    registerChip(wod.headerLabel, icon: "timer")
                }
            }
        )
    }

    private func dayWorkoutCard(_ session: WorkoutSession) -> some View {
        let minutes = sessionMinutes(session)
        let kcal = session.appleActiveEnergyKcal
        let prs = prCountBySessionId[session.id] ?? 0
        let isToday = calendar.isDateInToday(selectedDay)
        return registerCardWithChipsOverlay(
            open: { openWorkoutId = session.id },
            accessibilityHint: "Toca para ver el detalle del entreno",
            deleteLabel: "Eliminar registro de entreno",
            onDelete: { workoutPendingDelete = session },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(OG.accent.opacity(0.22))
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.accent)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayLabelWithTime(isToday: isToday, time: session.startedAt.map(SpanishDate.time)))
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
                if minutes > 0 {
                    registerChip("\(Int(minutes.rounded())) min", icon: "timer")
                }
                if let kcal, kcal > 0 {
                    registerChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                }
                if let review = session.sessionReview {
                    registerChip(review.scoreLabel, icon: review.scoreSymbolName)
                }
                if prs > 0 {
                    registerChip("\(prs) PR", icon: "trophy.fill")
                }
            }
        )
    }

    private func healthActivityCard(_ activity: HealthKitStore.ExternalActivity) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        return registerCardWithChipsOverlay(
            open: { openHealthActivityId = activity.id },
            accessibilityHint: "Toca para ver el detalle de la actividad",
            deleteLabel: "Eliminar registro de Salud",
            onDelete: { healthPendingDelete = activity },
            title: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(OG.red.opacity(0.22))
                        Image(systemName: activity.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(OG.red)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayLabelWithTime(isToday: isToday, time: SpanishDate.time(activity.start)))
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
                registerChip("Salud", icon: "heart.fill")
                if activity.durationMinutes > 0 {
                    registerChip("\(Int(activity.durationMinutes.rounded())) min", icon: "timer")
                }
                if let kcal = activity.activeEnergyKcal, kcal > 0 {
                    registerChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                }
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
            title: title,
            chips: { registerChipsRow(content: chips) }
        )
        .accessibilityHint(accessibilityHint)
    }

    /// Progressive window for dots / past-day metrics. Not tied to day selection.
    private func refreshProgressiveHealthIfNeeded() async {
        health.refreshAuthorizationStatus()
        guard health.isAuthorized else { return }

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
        guard health.isAuthorized, calendar.isDateInToday(selectedDay) else { return }
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

    /// Carrusel edge-to-edge; sin gesto de borrar (vive en el título de `RegisterSwipeRevealCard`).
    @ViewBuilder
    private func registerChipsRow(@ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content()
            }
            .padding(.leading, Self.chipsTitleLeading)
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func registerChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(OG.label2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(OG.surface3.opacity(0.65), in: Capsule())
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

    /// Al cambiar de semana (swipe/chevrons), conservar el weekday ISO si está en la nueva semana.
    private func snapSelectedDayToVisibleWeek() {
        let wanted = CalendarHelpers.isoWeekday(for: selectedDay)
        if let match = cachedWeekDays.first(where: {
            CalendarHelpers.isoWeekday(for: $0.date) == wanted
        }) {
            selectedDay = match.date
        } else if let first = cachedWeekDays.first {
            selectedDay = first.date
        }
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
                Text(dayLabelWithTime(isToday: isToday, time: selectedDayTimeLabel))
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
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metricTile(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func setLine(_ set: LoggedSet) -> String {
        let w = set.weightKg.map { "\($0.formatted(.number.precision(.fractionLength(0))))kg" } ?? "PC"
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
            guard let d = w.finishedAt else { continue }
            workouts[dayKey(d), default: []].append(w)
        }
        for key in workouts.keys {
            workouts[key]?.sort {
                ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast)
            }
        }

        var healthMap: [String: [HealthKitStore.ExternalActivity]] = [:]
        var minutes: [String: Double] = [:]
        var keys = Set<String>()
        for activity in health.recentExternalActivities {
            let key = dayKey(activity.start)
            keys.insert(key)
            healthMap[key, default: []].append(activity)
            minutes[key, default: 0] += max(0, activity.durationMinutes)
        }
        for key in healthMap.keys {
            healthMap[key]?.sort { $0.start > $1.start }
        }

        var kcals: [String: Double] = [:]
        for point in health.recentDailyActiveEnergy where point.kcal > 0 {
            kcals[dayKey(point.date)] = point.kcal
        }

        workoutsByDayKey = workouts
        healthByDayKey = healthMap
        healthActiveDayKeys = keys
        kcalByDayKey = kcals
        healthMinutesByDayKey = minutes.filter { $0.value > 0 }
    }

    private func rebuildWeekChrome() {
        let days = makeWeekDays(offset: weekOffset)
        cachedWeekDays = days
        if let first = days.first?.date, let last = days.last?.date {
            cachedWeekMonthTitle = SpanishDate.monthHeadline(from: first, to: last, calendar: calendar)
        } else {
            cachedWeekMonthTitle = "—"
        }
    }

    private func rebuildStreakChrome() {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let healthWeek = health.recentExternalActivities.reduce(into: 0) { count, activity in
            if activity.start >= weekAgo { count += 1 }
        }
        cachedStreakWeekDone = StatsEngine.workoutCount(from: store.state.workouts, days: 7) + healthWeek
        cachedStreakPlanned = store.state.routines.reduce(into: 0) { $0 += $1.weekday != nil ? 1 : 0 }
        cachedStreakTotal = store.state.workouts.count + health.recentExternalActivities.count
        cachedStreakWeeks = consecutiveWeekStreak()
    }

    private var plannedRoutineForSelectedDay: Routine? {
        store.routineForDay(selectedDay)
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

    private var dayHeaderLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f.string(from: selectedDay)
    }

    private func dayLabelWithTime(isToday: Bool, time: String?) -> String {
        let day = isToday ? "ENTRENO" : dayHeaderLabel.uppercased()
        guard let time, !time.isEmpty else { return day }
        return "\(day) · \(time)"
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

    /// Minutos del chip: inicio→fin del registro (no el time-cap usado solo para estimar kcal).
    private func sessionMinutes(_ session: WorkoutSession) -> Double {
        if let start = session.startedAt {
            let end = session.finishedAt ?? start.addingTimeInterval(60)
            let wall = max(0, end.timeIntervalSince(start) / 60)
            if wall > 0 { return wall }
        }
        return session.durationMinutes
    }

    /// Tile del día: max(energía activa Salud del día, suma de chips del día).
    /// Así un estimado Repera (aún no en Salud) no desaparece del total.
    private func healthKcal(for workouts: [WorkoutSession], durationMin: Double) -> Double? {
        let fromSessions = workouts.compactMap(\.appleActiveEnergyKcal).reduce(0, +)
        let fromExternal = healthActivities.compactMap(\.activeEnergyKcal).reduce(0, +)
        let fromCards = fromSessions + fromExternal

        let fromHealth: Double? = {
            if let hk = dayHealth.activeEnergyKcal, hk > 0 { return hk }
            if calendar.isDateInToday(selectedDay), let hk = health.activeEnergyTodayKcal, hk > 0 {
                return hk
            }
            return nil
        }()

        if let hk = fromHealth, fromCards > 0 {
            return max(hk, fromCards)
        }
        if let hk = fromHealth { return hk }
        if fromCards > 0 { return fromCards }
        guard durationMin > 0 else { return nil }
        let volume = workouts.reduce(0.0) { $0 + $1.totalVolumeKg }
        return durationMin * 7.5 + volume * 0.02
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

    /// Una página del carrusel semanal — el body solo corre cuando TabView la muestra.
    private struct WeekCarouselPage: View {
        @Binding var selectedDay: Date
        var calendar: Calendar
        var buildDays: () -> [DayCell]
        var dayDot: (DayCell) -> Color

        var body: some View {
            let days = buildDays()
            HStack(alignment: .top, spacing: 2) {
                ForEach(days, id: \.iso) { day in
                    Button {
                        selectedDay = day.date
                    } label: {
                        dayColumn(day)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }

        private func dayColumn(_ day: DayCell) -> some View {
            let selected = calendar.isDate(day.date, inSameDayAs: selectedDay)
            return VStack(spacing: 0) {
                Text(day.lbl)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)
                Text("\(day.num)")
                    .font(.system(size: 17, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? OG.onAccent : OG.label)
                    .frame(width: 31, height: 31)
                    .background {
                        if selected { Circle().fill(OG.accent) }
                    }
                    .padding(.vertical, 4)
                Circle()
                    .fill(dayDot(day))
                    .frame(width: 5, height: 5)
            }
            .padding(.vertical, 8)
        }
    }

    private var visibleWeekMonthTitle: String { cachedWeekMonthTitle }

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

        var workoutDays = Set(workoutsByDayKey.keys)
        for w in store.state.workouts where w.finishedAt == nil {
            if let d = w.startedAt { workoutDays.insert(dayKey(d)) }
        }
        workoutDays.formUnion(healthActiveDayKeys)

        // Un solo pase de rutinas → keys de plan de la semana visible.
        var planKeys = Set<String>()
        let weekDates: [Date] = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let weekISO = Set(weekDates.map { CalendarHelpers.isoWeekday(for: $0, calendar: calendar) })
        for routine in store.state.routines {
            if let scheduled = routine.scheduledDate {
                let key = dayKey(scheduled)
                if weekDates.contains(where: { calendar.isDate($0, inSameDayAs: scheduled) }) {
                    planKeys.insert(key)
                }
            } else if let wd = routine.weekday, weekISO.contains(wd) {
                for d in weekDates where CalendarHelpers.isoWeekday(for: d, calendar: calendar) == wd {
                    planKeys.insert(dayKey(d))
                }
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
                hasWorkout: workoutDays.contains(key),
                hasPlan: planKeys.contains(key)
            )
        }
    }

    private func dayDot(_ day: DayCell) -> Color {
        if day.hasWorkout { return OG.accent }
        if day.hasPlan { return OG.label3 }
        return .clear
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
}
