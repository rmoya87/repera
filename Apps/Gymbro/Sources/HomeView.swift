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
    @State private var showCreatePlanForDay = false

    private var calendar: Calendar { Calendar.current }

    private var selectedISOWeekday: Int {
        CalendarHelpers.isoWeekday(for: selectedDay)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    weekAndDayCard
                    streakCard
                }
                .padding(.horizontal, OG.pad)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(OG.bg)
            .toolbar(.hidden, for: .navigationBar)
            .task(id: selectedDay) {
                if health.isAuthorized {
                    if calendar.isDateInToday(selectedDay) {
                        await health.refreshToday()
                    }
                    dayHealth = await health.dayMetrics(for: selectedDay)
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
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("gymbro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(OG.label)
                    .tracking(-0.4)
                Text(SpanishDate.long(selectedDay))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(OG.label2)
            }
            Spacer()
            NavigationLink {
                SettingsView()
            } label: {
                iCloudAvatar
            }
            .accessibilityLabel("Ajustes y cuenta iCloud")
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var iCloudAvatar: some View {
        let synced = store.iCloudStatus == .available
        let photo = ProfileAvatar.uiImage(from: store.state.settings.profileAvatarJPEG)
        ZStack {
            Circle()
                .fill(synced || photo != nil ? OG.accent.opacity(0.25) : OG.surface2)
                .frame(width: 36, height: 36)
            if let img = photo {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: synced ? "person.crop.circle.fill" : "gearshape")
                    .font(.system(size: synced ? 22 : 17, weight: .regular))
                    .foregroundStyle(synced ? OG.accent : OG.label)
            }
        }
        .glassEffect(.regular.interactive(), in: .circle)
    }

    /// Semana + detalle del día en un solo bloque.
    private var weekAndDayCard: some View {
        let workouts = workoutsOnSelectedDay
        let durationMin = max(
            workouts.reduce(0.0) { $0 + sessionMinutes($1) },
            dayHealth.workoutMinutes ?? 0
        )
        let volume = workouts.reduce(0.0) { $0 + $1.totalVolumeKg }
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
                    Text(weekOffset == 0 ? "Esta semana" : "Semana")
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

                dayActionRow

                HStack(spacing: 10) {
                    metricTile(title: "Kcal", value: kcal.map { "\(Int($0.rounded()))" } ?? "—", icon: "flame.fill", tint: OG.orange)
                    metricTile(title: "Tiempo", value: durationMin > 0 ? "\(Int(durationMin.rounded()))′" : "—", icon: "clock.fill", tint: OG.blue)
                    metricTile(title: "Ejercicios", value: exerciseCount > 0 ? "\(exerciseCount)" : "—", icon: "dumbbell.fill", tint: OG.accent)
                }

                if volume > 0 {
                    Text("Volumen \(volume.formatted(.number.precision(.fractionLength(0)))) kg")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label3)
                }
                if let hk = displayedWeightKg {
                    Text("Peso · \(hk.formatted(.number.precision(.fractionLength(1)))) kg")
                        .font(.system(size: 12))
                        .foregroundStyle(OG.label3)
                }

                Divider().overlay(OG.surface3)

                // Historial = solo sesiones ya terminadas (no el plan / suelto del día).
                HStack {
                    Text(workouts.isEmpty ? "Sin registros este día" : "Registros del día")
                        .font(.system(size: 13))
                        .foregroundStyle(OG.label2)
                    Spacer()
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Text("Historial")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OG.accent)
                    }
                    .accessibilityHint("Sesiones terminadas")
                }

                if !workouts.isEmpty {
                    ForEach(workouts) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(OG.label)
                                Spacer()
                                Text(sessionMinutes(session) > 0
                                      ? "\(Int(sessionMinutes(session).rounded())) min"
                                      : "—")
                                    .font(.system(size: 13))
                                    .foregroundStyle(OG.label3)
                            }
                            if let notes = session.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                                Text(notes)
                                    .font(.system(size: 12))
                                    .foregroundStyle(OG.label2)
                                    .lineLimit(3)
                            }
                            ForEach(session.exercises.filter { !$0.loggedSets.isEmpty }) { ex in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.exercise.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(OG.label)
                                    Text(ex.loggedSets.map(setLine).joined(separator: " · "))
                                        .font(.system(size: 12))
                                        .foregroundStyle(OG.label3)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                        if session.id != workouts.last?.id {
                            Divider().overlay(OG.surface3)
                        }
                    }
                }
            }
        }
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

    private var displayedWeightKg: Double? {
        if let entry = store.state.bodyWeights.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDay) }) {
            return entry.weightKg
        }
        if calendar.isDateInToday(selectedDay) {
            return store.state.bodyWeights.first?.weightKg ?? health.latestWeightKg
        }
        return nil
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
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(todayIconBg)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: todayIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(todayIconFg)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "HOY" : dayHeaderLabel.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(OG.label3)
                        .tracking(0.3)
                    Text(selectedDayTitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(OG.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if planned != nil, store.state.activeSession == nil || !isToday {
                        Text("Toca para abrir y empezar")
                            .font(.system(size: 12))
                            .foregroundStyle(OG.label2)
                    } else if planned == nil {
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
        .buttonStyle(.plain)
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

    private var streakCard: some View {
        let weekDone = StatsEngine.workoutCount(from: store.state.workouts, days: 7)
        let planned = store.state.routines.filter { $0.weekday != nil }.count
        let total = store.state.workouts.count
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

    private var selectedDayTitle: String {
        if calendar.isDateInToday(selectedDay), let active = store.state.activeSession {
            return "\(active.title) (en curso)"
        }
        // El plan manda sobre un registro suelto (p. ej. escaneo a medias).
        if let planned = plannedTitleForSelectedDay {
            return planned
        }
        if let done = workoutsOnSelectedDay.first {
            return done.title
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
        if !workoutsOnSelectedDay.isEmpty { return "checkmark" }
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
        let weeks = activeWeeksLastMonths()
        if weeks == 0 { return "Sin racha todavía" }
        return weeks == 1 ? "1 semana con entreno" : "\(weeks) semanas con entreno"
    }

    private func streakSubtitle(weekDone: Int, planned: Int, total: Int) -> String {
        if total == 0 { return "Cuando entrenes, verás aquí tu progreso" }
        if planned > 0 {
            return "\(weekDone) / \(planned) esta semana · \(total) entrenos en total"
        }
        return "\(weekDone) esta semana · \(total) entrenos en total"
    }

    private func activeWeeksLastMonths() -> Int {
        var keys = Set<String>()
        for w in store.state.workouts {
            guard let d = w.finishedAt ?? w.startedAt else { continue }
            let week = calendar.component(.weekOfYear, from: d)
            let year = calendar.component(.yearForWeekOfYear, from: d)
            keys.insert("\(year)-\(week)")
        }
        return keys.count
    }

    private struct DayCell {
        var iso: String
        var date: Date
        var lbl: String
        var num: Int
        var hasWorkout: Bool
        var hasPlan: Bool
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

        let workoutDays: Set<String> = Set(
            store.state.workouts.compactMap { w -> String? in
                guard let d = w.finishedAt else { return nil }
                return dayKey(d)
            }
        )

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
