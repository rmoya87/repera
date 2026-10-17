import GymbroDomain
import SwiftUI

/// Inicio: semana seleccionable + métricas del día + registros.
struct HomeView: View {
    @Environment(GymbroStore.self) private var store
    @Environment(HealthKitStore.self) private var health
    var onOpenWorkout: () -> Void
    var onStart: () -> Void
    /// Abre el preview / inicio de un entreno concreto (p. ej. suelto del viernes).
    var onStartRoutine: (Routine) -> Void = { _ in }
    var onGoPlan: () -> Void
    var onOpenStartHub: () -> Void

    @State private var weekOffset = 0
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var dayHealth = HealthKitStore.DayMetrics()
    @State private var healthActivities: [HealthKitStore.ExternalActivity] = []
    @State private var healthActiveDayKeys: Set<String> = []
    @State private var showCreatePlanForDay = false
    @State private var workoutPendingDelete: WorkoutSession?
    @State private var healthPendingDelete: HealthKitStore.ExternalActivity?
    @State private var openWorkoutId: UUID?
    @State private var openHealthActivityId: UUID?

    private var calendar: Calendar { Calendar.current }

    private var selectedISOWeekday: Int {
        CalendarHelpers.isoWeekday(for: selectedDay)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    weekAndDayCard
                    streakCard
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 0)
                .padding(.bottom, 28)
            }
            .background(OG.bg)
            .ogFixedTopBar("gymbro", subtitle: SpanishDate.long(selectedDay)) {
                NavigationLink {
                    SettingsView()
                } label: {
                    iCloudAvatar
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ajustes y cuenta iCloud")
            }
            .task(id: "\(weekOffset)-\(dayKey(selectedDay))") {
                await refreshHealthForVisibleRange()
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
                    }
                )
                .preferredColorScheme(.dark)
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
                        Task { await refreshHealthForVisibleRange() }
                    },
                    onCancel: { workoutPendingDelete = nil }
                )
            }
            .sheet(item: $healthPendingDelete) { activity in
                OGConfirmSheet(
                    title: "¿Eliminar registro?",
                    message: "Se borrará «\(activity.title)» de este día. No se puede deshacer.",
                    onConfirm: {
                        let id = activity.id
                        healthPendingDelete = nil
                        healthActivities.removeAll { $0.id == id }
                        healthActiveDayKeys.remove(dayKey(activity.start))
                        Task {
                            _ = await health.deleteExternalWorkout(id: id)
                            await refreshHealthForVisibleRange()
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
        // Sin glassEffect: el halo liquid glass sobresalía por encima de «gymbro».
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
        let exerciseCount = workouts.reduce(0) { $0 + $1.exercises.filter(\.isCompleted).count }

        return OGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button { weekOffset -= 1 } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .frame(width: 30, height: 30)
                    }
                    Spacer()
                    Text(visibleWeekMonthTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(OG.label2)
                    Spacer()
                    Button { weekOffset += 1 } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OG.label2)
                            .frame(width: 30, height: 30)
                    }
                }

                HStack(alignment: .top, spacing: 2) {
                    ForEach(weekDays, id: \.iso) { day in
                        Button {
                            selectedDay = day.date
                        } label: {
                            dayColumn(day)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }

                dayEntrenoStack(workouts: workouts)

                HStack(spacing: 10) {
                    metricTile(title: "Kcal", value: kcal.map { "\(Int($0.rounded()))" } ?? "—", icon: "flame.fill", tint: OG.orange)
                    metricTile(title: "Tiempo", value: durationMin > 0 ? "\(Int(durationMin.rounded()))′" : "—", icon: "clock.fill", tint: OG.blue)
                    metricTile(title: "Ejercicios", value: exerciseCount > 0 ? "\(exerciseCount)" : "—", icon: "dumbbell.fill", tint: OG.accent)
                }
            }
        }
    }

    /// Entreno del día: sesión hecha (swipe eliminar), Salud (swipe eliminar), o descanso / plan.
    @ViewBuilder
    private func dayEntrenoStack(workouts: [WorkoutSession]) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let hasActive = isToday && store.state.activeSession != nil
        let hasCompletedActivity = !workouts.isEmpty || !healthActivities.isEmpty

        VStack(spacing: 10) {
            if hasActive {
                Button(action: onStart) {
                    dayActionRowContent
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        store.endActiveSession(save: false)
                    } label: {
                        Label("Descartar", systemImage: "trash")
                    }
                    .accessibilityLabel("Descartar entreno en curso")
                }
            } else if !workouts.isEmpty {
                ForEach(workouts) { session in
                    Button {
                        openWorkoutId = session.id
                    } label: {
                        dayWorkoutCard(session)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Toca para ver el detalle del entreno")
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            workoutPendingDelete = session
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .accessibilityLabel("Eliminar registro de entreno")
                    }
                }
            } else if !hasCompletedActivity {
                // Sin registros → plan o día de descanso.
                dayActionRow
            }

            ForEach(healthActivities) { activity in
                Button {
                    openHealthActivityId = activity.id
                } label: {
                    healthActivityCard(activity)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Toca para ver el detalle de la actividad")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        healthPendingDelete = activity
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    .accessibilityLabel("Eliminar registro de Salud")
                }
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

    private func dayWorkoutCard(_ session: WorkoutSession) -> some View {
        let minutes = sessionMinutes(session)
        let logged = session.exercises.filter { !$0.loggedSets.isEmpty }
        let kcal = session.appleActiveEnergyKcal
        let isToday = calendar.isDateInToday(selectedDay)
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(OG.accent.opacity(0.22))
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.accent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(isToday ? "ENTRENO" : dayHeaderLabel.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(session.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    if let start = session.startedAt {
                        Text(SpanishDate.time(start))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(OG.label2)
                    }
                }

                HStack(spacing: 6) {
                    if minutes > 0 {
                        registerChip("\(Int(minutes.rounded())) min", icon: "timer")
                    }
                    if let kcal, kcal > 0 {
                        registerChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                    }
                    if !logged.isEmpty {
                        registerChip("\(logged.count) ej.", icon: "list.bullet")
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func healthActivityCard(_ activity: HealthKitStore.ExternalActivity) -> some View {
        let isToday = calendar.isDateInToday(selectedDay)
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(OG.red.opacity(0.22))
                Image(systemName: activity.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(OG.red)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(isToday ? "ENTRENO" : dayHeaderLabel.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(activity.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    Text(SpanishDate.time(activity.start))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(OG.label2)
                }

                HStack(spacing: 6) {
                    registerChip("Salud", icon: "heart.fill")
                    if activity.durationMinutes > 0 {
                        registerChip("\(Int(activity.durationMinutes.rounded())) min", icon: "timer")
                    }
                    if let kcal = activity.activeEnergyKcal, kcal > 0 {
                        registerChip("\(Int(kcal.rounded())) kcal", icon: "flame.fill")
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func refreshHealthForVisibleRange() async {
        guard health.isAuthorized else {
            healthActivities = []
            healthActiveDayKeys = []
            dayHealth = HealthKitStore.DayMetrics()
            return
        }
        if calendar.isDateInToday(selectedDay) {
            await health.refreshToday()
        }
        dayHealth = await health.dayMetrics(for: selectedDay)

        let linked = Set(store.state.workouts.compactMap(\.healthKitWorkoutUUID))
        await health.refreshRecentExternalActivities(
            excludingUUIDs: linked,
            overlappingSessions: store.state.workouts
        )
        let recent = health.recentExternalActivities
        healthActivities = recent.filter { calendar.isDate($0.start, inSameDayAs: selectedDay) }
        healthActiveDayKeys = Set(recent.map { dayKey($0.start) })
    }

    private func registerChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(OG.label2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(OG.surface3.opacity(0.65), in: Capsule())
    }

    private func startPlannedDayIfPossible() {
        if calendar.isDateInToday(selectedDay), store.state.activeSession != nil {
            onStart()
            return
        }
        if let planned = plannedRoutineForSelectedDay {
            onStartRoutine(planned)
            return
        }
        showCreatePlanForDay = true
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

    private var dayActionRow: some View {
        let isToday = calendar.isDateInToday(selectedDay)
        let planned = plannedRoutineForSelectedDay
        return Button {
            if isToday, store.state.activeSession != nil {
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
                Text(isToday ? "ENTRENO" : dayHeaderLabel.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OG.label3)
                    .tracking(0.3)
                Text(selectedDayTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(OG.label)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if isToday, store.state.activeSession != nil {
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
        let healthWeek = health.recentExternalActivities.filter {
            $0.start >= (calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        }.count
        let weekDone = StatsEngine.workoutCount(from: store.state.workouts, days: 7) + healthWeek
        let planned = store.state.routines.filter { $0.weekday != nil }.count
        let total = store.state.workouts.count + health.recentExternalActivities.count
        return NavigationLink {
            HistoryView()
        } label: {
            OGCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(OG.orange)
                            Text(streakTitle)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(OG.label)
                                .tracking(-0.4)
                        }
                        Text(streakSubtitle(weekDone: weekDone, planned: planned, total: total))
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
        store.state.workouts.filter { w in
            guard let d = w.finishedAt else { return false }
            return calendar.isDate(d, inSameDayAs: selectedDay)
        }
        .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
    }

    private var plannedRoutineForSelectedDay: Routine? {
        store.routineForDay(selectedDay)
    }

    private var plannedTitleForSelectedDay: String? {
        plannedRoutineForSelectedDay?.title
    }

    /// Hay algo completado ese día (Gymbro o Salud visible).
    private var hasCompletedActivityOnSelectedDay: Bool {
        !workoutsOnSelectedDay.isEmpty || !healthActivities.isEmpty
    }

    private var selectedDayTitle: String {
        if calendar.isDateInToday(selectedDay), let active = store.state.activeSession {
            return "\(active.title) (en curso)"
        }
        if let done = workoutsOnSelectedDay.first {
            if let start = done.startedAt {
                return "\(done.title) · \(SpanishDate.time(start))"
            }
            return done.title
        }
        // Actividad de Apple Salud = día trabajado, no descanso.
        if let health = healthActivities.first {
            return "\(health.title) · \(SpanishDate.time(health.start))"
        }
        // Plan solo si aún no hay registro completado.
        if let planned = plannedRoutineForSelectedDay {
            if let minutes = planned.normalizedScheduledTimeMinutes {
                return "\(planned.title) · \(SpanishDate.time(minutesFromMidnight: minutes))"
            }
            return planned.title
        }
        return "Día de descanso"
    }

    private var dayHeaderLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f.string(from: selectedDay)
    }

    private var todayIconBg: Color {
        if calendar.isDateInToday(selectedDay), store.state.activeSession != nil { return OG.orange }
        if calendar.isDateInToday(selectedDay), store.routineForToday() != nil { return OG.accent }
        return OG.surface3
    }

    private var todayIconFg: Color {
        if calendar.isDateInToday(selectedDay),
           store.state.activeSession != nil || store.routineForToday() != nil {
            return Color.black
        }
        return OG.label2
    }

    private var todayIcon: String {
        if calendar.isDateInToday(selectedDay), store.state.activeSession != nil { return "play.fill" }
        if hasCompletedActivityOnSelectedDay { return "checkmark" }
        if plannedTitleForSelectedDay != nil { return "figure.strengthtraining.traditional" }
        return "moon.fill"
    }

    private func sessionMinutes(_ session: WorkoutSession) -> Double {
        session.durationMinutes
    }

    private func healthKcal(for workouts: [WorkoutSession], durationMin: Double) -> Double? {
        let fromSessions = workouts.compactMap(\.appleActiveEnergyKcal).reduce(0, +)
        if fromSessions > 0 { return fromSessions }
        if let hk = dayHealth.activeEnergyKcal, hk > 0 { return hk }
        if calendar.isDateInToday(selectedDay), let hk = health.activeEnergyTodayKcal, hk > 0 {
            return hk
        }
        guard durationMin > 0 else { return nil }
        let volume = workouts.reduce(0.0) { $0 + $1.totalVolumeKg }
        return durationMin * 7.5 + volume * 0.02
    }

    private var streakTitle: String {
        let weeks = consecutiveWeekStreak()
        if weeks == 0 { return "Sin racha todavía" }
        return weeks == 1 ? "Racha de 1 semana" : "Racha de \(weeks) semanas"
    }

    private func streakSubtitle(weekDone: Int, planned: Int, total: Int) -> String {
        if total == 0 { return "Cuando entrenes, verás aquí tu progreso" }
        if planned > 0 {
            return "\(weekDone) / \(planned) esta semana · \(total) entrenos en total"
        }
        return "\(weekDone) esta semana · \(total) entrenos en total"
    }

    /// Semanas consecutivas con al menos un entreno (Gymbro o Salud), como openGym `streakWeeks`.
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

    private var visibleWeekMonthTitle: String {
        guard let first = weekDays.first?.date, let last = weekDays.last?.date else { return "—" }
        return SpanishDate.monthHeadline(from: first, to: last, calendar: calendar)
    }

    private var weekDays: [DayCell] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOffset = store.state.settings.weekStartsOn == .monday
            ? (weekday == 1 ? -6 : 2 - weekday)
            : 1 - weekday
        guard var start = calendar.date(byAdding: .day, value: startOffset + weekOffset * 7, to: today) else {
            return []
        }
        start = calendar.startOfDay(for: start)
        let labels: [String] = store.state.settings.weekStartsOn == .monday
            ? ["LU", "MA", "MI", "JU", "VI", "SA", "DO"]
            : ["DO", "LU", "MA", "MI", "JU", "VI", "SA"]

        var workoutDays: Set<String> = Set(
            store.state.workouts.compactMap { w -> String? in
                guard let d = w.finishedAt ?? w.startedAt else { return nil }
                return dayKey(d)
            }
        )
        workoutDays.formUnion(healthActiveDayKeys)

        return (0..<7).compactMap { i in
            guard let d = calendar.date(byAdding: .day, value: i, to: start) else { return nil }
            let dayStart = calendar.startOfDay(for: d)
            return DayCell(
                iso: dayKey(d),
                date: dayStart,
                lbl: labels[i],
                num: calendar.component(.day, from: d),
                hasWorkout: workoutDays.contains(dayKey(d)),
                hasPlan: store.routineForDay(dayStart) != nil
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
