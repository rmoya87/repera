import ReperaDomain
import SwiftUI

enum StandaloneTimerMode: String, CaseIterable, Identifiable, Codable {
    case up
    case down
    case intervals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up: "Arriba"
        case .down: "Abajo"
        case .intervals: "Intervalos"
        }
    }
}

struct StandaloneTimerConfig: Equatable, Codable, Hashable {
    var mode: StandaloneTimerMode = .intervals
    var durationMinutes: Int = 40
    var durationSeconds: Int = 0
    var rounds: Int = 5
    var workMinutes: Int = 1
    var workSeconds: Int = 30
    var restMinutes: Int = 0
    var restSeconds: Int = 0
    var countdownBeforeStart: Bool = true

    var durationTotalSeconds: Int { max(1, durationMinutes * 60 + durationSeconds) }
    var workTotalSeconds: Int { max(1, workMinutes * 60 + workSeconds) }
    var restTotalSeconds: Int { max(0, restMinutes * 60 + restSeconds) }

    var shortLabel: String {
        switch mode {
        case .up:
            return "Arriba · \(timeLabel(durationMinutes, durationSeconds))"
        case .down:
            return "Abajo · \(timeLabel(durationMinutes, durationSeconds))"
        case .intervals:
            return "Intervalos · \(rounds)× \(timeLabel(workMinutes, workSeconds))/\(timeLabel(restMinutes, restSeconds))"
        }
    }

    private func timeLabel(_ m: Int, _ s: Int) -> String {
        String(format: "%d:%02d", m, s)
    }

    init(
        mode: StandaloneTimerMode = .intervals,
        durationMinutes: Int = 40,
        durationSeconds: Int = 0,
        rounds: Int = 5,
        workMinutes: Int = 1,
        workSeconds: Int = 30,
        restMinutes: Int = 0,
        restSeconds: Int = 0,
        countdownBeforeStart: Bool = true
    ) {
        self.mode = mode
        self.durationMinutes = durationMinutes
        self.durationSeconds = durationSeconds
        self.rounds = rounds
        self.workMinutes = workMinutes
        self.workSeconds = workSeconds
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.countdownBeforeStart = countdownBeforeStart
    }

    init(favorite: FavoriteTimer) {
        self.mode = StandaloneTimerMode(rawValue: favorite.modeRaw) ?? .intervals
        self.durationMinutes = favorite.durationMinutes
        self.durationSeconds = favorite.durationSeconds
        self.rounds = favorite.rounds
        self.workMinutes = favorite.workMinutes
        self.workSeconds = favorite.workSeconds
        self.restMinutes = favorite.restMinutes
        self.restSeconds = favorite.restSeconds
        self.countdownBeforeStart = favorite.countdownBeforeStart
    }

    func asFavorite(title: String, id: UUID = UUID()) -> FavoriteTimer {
        FavoriteTimer(
            id: id,
            title: title,
            modeRaw: mode.rawValue,
            durationMinutes: durationMinutes,
            durationSeconds: durationSeconds,
            rounds: rounds,
            workMinutes: workMinutes,
            workSeconds: workSeconds,
            restMinutes: restMinutes,
            restSeconds: restSeconds,
            countdownBeforeStart: countdownBeforeStart
        )
    }
}

/// Último resultado del reloj, local y ajeno a las sesiones HealthKit.
private struct StandaloneTimerCompletion: Codable {
    /// Stable record identifier: pressing Save twice cannot add two workouts.
    let id: UUID
    let startedAt: Date
    let finishedAt: Date
    let configuration: StandaloneTimerConfig
    var locationPin: WorkoutLocationPin?

    init(
        id: UUID = UUID(), startedAt: Date, finishedAt: Date,
        configuration: StandaloneTimerConfig, locationPin: WorkoutLocationPin?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.configuration = configuration
        self.locationPin = locationPin
    }

    private enum CodingKeys: String, CodingKey {
        case id, startedAt, finishedAt, configuration, locationPin
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let finished = try c.decode(Date.self, forKey: .finishedAt)
        let config = try c.decode(StandaloneTimerConfig.self, forKey: .configuration)
        let start = try c.decodeIfPresent(Date.self, forKey: .startedAt)
            ?? finished.addingTimeInterval(-TimeInterval(max(1, config.mode == .intervals
                ? config.rounds * config.workTotalSeconds
                    + max(0, config.rounds - 1) * config.restTotalSeconds
                : config.durationTotalSeconds)))
        self.init(
            id: try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            startedAt: start, finishedAt: finished, configuration: config,
            locationPin: try c.decodeIfPresent(WorkoutLocationPin.self, forKey: .locationPin)
        )
    }

    var configuredSeconds: Int {
        switch configuration.mode {
        case .up, .down: return configuration.durationTotalSeconds
        case .intervals:
            return configuration.rounds * configuration.workTotalSeconds
                + max(0, configuration.rounds - 1) * configuration.restTotalSeconds
        }
    }
}

/// Última configuración del temporizador, independiente de los favoritos.
private enum StandaloneTimerConfigurationStore {
    private static let key = "repera.timer.lastConfiguration.v1"

    static func load() -> StandaloneTimerConfig? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StandaloneTimerConfig.self, from: data)
    }

    static func save(_ configuration: StandaloneTimerConfig) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private enum StandaloneTimerCompletionStore {
    // v2 guarda solo resultados pendientes de decisión; no reabre los resúmenes
    // antiguos de solo lectura como si todavía esperasen Guardar/Descartar.
    private static let key = "repera.timer.pendingCompletion.v2"
    static func load() -> StandaloneTimerCompletion? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StandaloneTimerCompletion.self, from: data)
    }
    static func save(_ completion: StandaloneTimerCompletion) {
        guard let data = try? JSONEncoder().encode(completion) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

/// Entrada con el mismo teclado numérico de Repera que la tabla de series.
/// Campo numérico compartido entre el temporizador libre y su configuración en Play.
struct TimerNumericInput: View {
    @Binding private var value: Int
    let range: ClosedRange<Int>
    let label: String
    @State private var draft: String

    init(label: String, value: Binding<Int>, range: ClosedRange<Int>) {
        self.label = label
        self.range = range
        _value = value
        _draft = State(initialValue: String(value.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(OG.label3)
            OGNumericTextField(
                text: Binding(
                    get: { draft },
                    set: { input in
                        draft = input
                        if let parsed = Int(input), range.contains(parsed) {
                            value = parsed
                        }
                    }
                ),
                allowsDecimal: false,
                autoFocus: false,
                onFocusLost: { commit() },
                // El componente UIKit debe ofrecer 48 pt a la negociación
                // del tamaño antes de que el sheet calcule su detent.
                compactIntrinsicHeight: 48,
                onCommit: { commit() }
            )
            // El alto debe coincidir con el formulario Temporizador (48 pt).
            // 'minHeight' dejaba crecer el UIViewRepresentable al recibir
            // toda la propuesta vertical del sheet de altura adaptable.
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            // Mismo fondo que el campo Reps del entrenamiento.
            // El sheet mantiene Liquid Glass, pero no cada input numérico.
            .background(OG.surface2, in: RoundedRectangle(cornerRadius: 11))
            .accessibilityLabel(label)
        }
        // Incluye etiqueta y campo dentro de la misma geometría cerrada:
        // ni el VStack ni la superficie glass pueden expandirse con el sheet.
        .frame(height: 64, alignment: .top)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func commit() {
        if let parsed = Int(draft) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
        draft = String(value)
    }
}

/// Temporizador libre (Crear): configuración + reloj LED.
struct StandaloneTimerView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @State private var config: StandaloneTimerConfig
    private let usesLastConfiguration: Bool
    @State private var showClock = false
    @State private var isRunning = false
    @State private var displaySeconds = 0
    @State private var roundNumber = 1
    @State private var phaseIsWork = true
    @State private var preCountdown = 0
    @State private var timer: Timer?
    /// Wall-clock anchors — display is derived from Date, not tick accumulation.
    @State private var preCountdownEnd: Date?
    @State private var phaseEndDate: Date?
    @State private var phaseStartDate: Date?
    @State private var pausedDisplaySeconds: Int?
    @State private var showSaveAlert = false
    @State private var saveTitle = ""
    @State private var editingFavoriteId: UUID?
    @State private var locationPin: WorkoutLocationPin?
    @State private var completedSummary: StandaloneTimerCompletion?
    @State private var timerStartedAt: Date?
    @State private var showDiscardCompletedTimer = false

    var embedsNavigation = true

    init(
        embedsNavigation: Bool = true,
        config: StandaloneTimerConfig? = nil,
        editingFavoriteId: UUID? = nil
    ) {
        self.embedsNavigation = embedsNavigation
        // Una configuración enviada por Favoritos tiene prioridad sobre
        // la última usada; sin preset, recuperar los ajustes anteriores.
        usesLastConfiguration = config == nil
        _config = State(initialValue:
            config ?? StandaloneTimerConfigurationStore.load() ?? StandaloneTimerConfig()
        )
        _editingFavoriteId = State(initialValue: editingFavoriteId)
        _saveTitle = State(initialValue: "")
    }

    var body: some View {
        Group {
            if embedsNavigation {
                NavigationStack { content }
            } else {
                content
            }
        }
        .fullScreenCover(isPresented: $showClock) {
            if completedSummary != nil { timerSummaryScreen } else { clockScreen }
        }
        .alert("Guardar en favoritos", isPresented: $showSaveAlert) {
            TextField("Nombre", text: $saveTitle)
            Button("Guardar") { persistFavorite() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se guardará esta configuración para reutilizarla desde Favoritos.")
        }
        .onAppear {
            if completedSummary == nil { completedSummary = StandaloneTimerCompletionStore.load() }
            if usesLastConfiguration, !showClock, !isRunning,
               completedSummary == nil,
               let lastUsed = StandaloneTimerConfigurationStore.load() {
                config = lastUsed
            }
            TimerScreenAwake.setRunning(isRunning || pausedDisplaySeconds != nil, for: .standalone)
        }
        .onChange(of: config) { _, updated in
            StandaloneTimerConfigurationStore.save(updated)
        }
        .onChange(of: isRunning) { _, _ in
            // Mantener el iPhone despierto durante ejecución Y pausa.
            // Solo finalizar o cerrar el reloj restaura el autobloqueo.
            TimerScreenAwake.setRunning(isRunning || pausedDisplaySeconds != nil, for: .standalone)
        }
        .onChange(of: pausedDisplaySeconds) { _, _ in
            TimerScreenAwake.setRunning(isRunning || pausedDisplaySeconds != nil, for: .standalone)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, isRunning {
                // El reloj usa fechas reales: recuperarse de una suspensión
                // sin perder el final ni mantener la pantalla despierta
                // cuando el temporizador ya terminó.
                syncFromWallClock()
            }
        }
        .onChange(of: showClock) { _, visible in
            if !visible { stopTimer() }
        }
        .onDisappear {
            // Una fullScreenCover mantiene vivo el owner del reloj;
            // abandonar de verdad el editor detiene el temporizador.
            if !showClock { stopTimer() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OGScrollablePageTitle("Temporizador")
                // Mismo selector Liquid Glass nativo que Entreno / Actividad / Recuperación.
                Picker("Tipo de temporizador", selection: $config.mode) {
                    ForEach(StandaloneTimerMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .glassEffect(.regular, in: .capsule)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .ogReadableColumn()

                VStack(alignment: .leading, spacing: 0) {
                    switch config.mode {
                    case .up, .down:
                        compactTimeRow(
                            title: "Duración",
                            minutes: $config.durationMinutes,
                            seconds: $config.durationSeconds,
                            maxMinutes: 180,
                            topPadding: 0
                        )
                    case .intervals:
                        compactIntRow(title: "Rondas", value: $config.rounds, range: 1...99)
                        Divider().overlay(OG.surface3)
                        compactTimeRow(
                            title: "Trabajar",
                            minutes: $config.workMinutes,
                            seconds: $config.workSeconds,
                            maxMinutes: 60
                        )
                        Divider().overlay(OG.surface3)
                        compactTimeRow(
                            title: "Descansar",
                            minutes: $config.restMinutes,
                            seconds: $config.restSeconds,
                            maxMinutes: 30
                        )
                    }

                    Divider().overlay(OG.surface3)
                    Toggle(isOn: $config.countdownBeforeStart) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cuenta atrás")
                                .foregroundStyle(OG.label)
                            Text("Antes de que comience el temporizador")
                                .font(.system(size: 13))
                                .foregroundStyle(OG.label3)
                        }
                    }
                    .tint(OG.accent)
                    .padding(.vertical, 10)
                }
                .padding(14)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lugar").font(.system(size: 14, weight: .semibold)).foregroundStyle(OG.label2)
                    WorkoutPlacePickerRow(pin: $locationPin)
                }
                .padding(14)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))

                Button {
                    prepareAndShowClock()
                } label: {
                    Text("Abrir reloj")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(OG.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(OG.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                if let completedSummary {
                    Button {
                        locationPin = completedSummary.locationPin
                        showClock = true
                    } label: {
                        Label("Temporizador pendiente", systemImage: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(OG.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(OG.bg.ignoresSafeArea())
        // ScrollView independiente: no usar el margen de listas agrupadas
        // durante la transición tras cerrar "Añadir entreno".
        .ogScrollingTitleNav(usesGroupedList: false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                OGToolbarGlassButton(
                    systemName: editingFavoriteId == nil ? "star" : "star.fill",
                    accessibilityLabel: editingFavoriteId == nil ? "Guardar en favoritos" : "Actualizar favorito",
                    tint: OG.yellow
                ) {
                    saveTitle = editingFavoriteId.flatMap { id in
                        store.state.favoriteTimers.first { $0.id == id }?.title
                    } ?? defaultFavoriteTitle
                    showSaveAlert = true
                }
            }
        }
    }

    private var defaultFavoriteTitle: String {
        switch config.mode {
        case .up: return "Cronómetro \(String(format: "%d:%02d", config.durationMinutes, config.durationSeconds))"
        case .down: return "Cuenta atrás \(String(format: "%d:%02d", config.durationMinutes, config.durationSeconds))"
        case .intervals: return "Intervalos \(config.rounds)×"
        }
    }

    /// Campos numéricos compartidos con ejercicios: sin stepper +/-.
    private func compactIntRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(OG.label)
            Spacer(minLength: 8)
            TimerNumericInput(label: "RONDAS", value: value, range: range)
                .frame(width: 110)
        }
        // La primera fila comienza a 14 pt del borde superior de la tarjeta,
        // sin el espacio reservado para el antiguo encabezado.
        .padding(.bottom, 9)
    }

    private func compactTimeRow(
        title: String,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        maxMinutes: Int,
        topPadding: CGFloat = 9
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(OG.label)
            Spacer(minLength: 4)
            HStack(spacing: 8) {
                TimerNumericInput(label: "MIN", value: minutes, range: 0...maxMinutes)
                TimerNumericInput(label: "SEG", value: seconds, range: 0...59)
            }
            .frame(maxWidth: 210)
        }
        .padding(.top, topPadding)
        .padding(.bottom, 9)
    }

    private func persistFavorite() {
        let name = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = name.isEmpty ? defaultFavoriteTitle : name
        if let id = editingFavoriteId {
            store.saveFavoriteTimer(config.asFavorite(title: title, id: id))
        } else {
            let saved = store.saveFavoriteTimer(config.asFavorite(title: title))
            editingFavoriteId = saved.id
        }
    }

    /// Resultado del temporizador con la misma jerarquía visual que el detalle
    /// de un entreno terminado: título grande, fecha, métricas y secciones.
    private var timerSummaryScreen: some View {
        NavigationStack {
            List {
                OGScrollablePageTitle("Temporizador finalizado")
                    .ogScrollingTitleListRow()

                if let summary = completedSummary {
                    Section {
                        HStack(spacing: 10) {
                            WorkoutSummaryTile(
                                title: "Tiempo",
                                value: DurationText.format(summary.configuredSeconds),
                                icon: "clock.fill",
                                tint: OG.blue
                            )
                            .frame(maxWidth: .infinity)

                            WorkoutSummaryTile(
                                title: "Modalidad",
                                value: summary.configuration.mode.title,
                                icon: "timer",
                                tint: OG.accent
                            )
                            .frame(maxWidth: .infinity)

                            if summary.configuration.mode == .intervals {
                                WorkoutSummaryTile(
                                    title: "Rondas",
                                    value: "\(summary.configuration.rounds)",
                                    icon: "repeat",
                                    tint: OG.orange
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .ogCardListRow(top: 0, bottom: 2)
                    } header: {
                        Text(
                            summary.finishedAt.formatted(
                                Date.FormatStyle(date: .complete, time: .shortened)
                                    .locale(Locale(identifier: "es_ES"))
                            )
                        )
                        .font(.system(size: 15))
                        .foregroundStyle(OG.label2)
                        .textCase(nil)
                        .padding(.leading, 2)
                    }

                    Section {
                        if summary.configuration.mode == .intervals {
                            LabeledContent(
                                "Trabajo",
                                value: DurationText.format(summary.configuration.workTotalSeconds)
                            )
                            LabeledContent(
                                "Descanso",
                                value: DurationText.format(summary.configuration.restTotalSeconds)
                            )
                        } else {
                            LabeledContent(
                                "Duración programada",
                                value: DurationText.format(summary.configuredSeconds)
                            )
                        }
                        LabeledContent(
                            "Cuenta atrás",
                            value: summary.configuration.countdownBeforeStart ? "3 s" : "Desactivada"
                        )
                    } header: {
                        Text("Configuración").textCase(nil)
                    }

                    Section {
                        WorkoutPlacePickerRow(pin: Binding(
                            get: { completedSummary?.locationPin },
                            set: { updated in
                                guard var summary = completedSummary else { return }
                                summary.locationPin = updated
                                completedSummary = summary
                                locationPin = updated
                                StandaloneTimerCompletionStore.save(summary)
                            }
                        ))
                    } header: {
                        Text("Lugar").textCase(nil)
                    }

                    Section {
                        Button(action: saveCompletedTimer) {
                            Text("Guardar")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                .background(OG.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .ogCardListRow()
                    }
                    Section {
                        Button(role: .destructive) {
                            showDiscardCompletedTimer = true
                        } label: {
                            Text("Descartar")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(OG.red)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .confirmationDialog(
                "¿Descartar temporizador?",
                isPresented: $showDiscardCompletedTimer,
                titleVisibility: .visible
            ) {
                Button("Descartar", role: .destructive, action: discardCompletedTimer)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta sesión no aparecerá en Inicio ni en Historial.")
            }
            .ogListChrome()
            .listSectionSpacing(12)
            .ogScrollingTitleNav()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveCompletedTimer) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                            .frame(width: OG.toolbarGlassSize, height: OG.toolbarGlassSize)
                            .background(OG.accent, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Guardar temporizador")
                    .accessibilityHint("Guardar esta sesión en Inicio e Historial")
                }
            }
        }
    }

    /// Hasta elegir Guardar o Descartar, el resultado queda pendiente
    /// incluso si iOS cierra la app al regresar de segundo plano.
    private func recordTimerCompletion(finishedAt: Date = Date()) {
        guard completedSummary == nil else { return }
        let summary = StandaloneTimerCompletion(
            startedAt: min(timerStartedAt ?? finishedAt.addingTimeInterval(
                -TimeInterval(configuredDurationSeconds)
            ), finishedAt),
            finishedAt: finishedAt, configuration: config, locationPin: locationPin
        )
        completedSummary = summary
        StandaloneTimerCompletionStore.save(summary)
    }

    private var configuredDurationSeconds: Int {
        switch config.mode {
        case .up, .down: return config.durationTotalSeconds
        case .intervals:
            return config.rounds * config.workTotalSeconds
                + max(0, config.rounds - 1) * config.restTotalSeconds
        }
    }

    private func dismissCompletedTimer() {
        // Cerrar antes de limpiar el resumen evita que el fullScreenCover
        // pinte brevemente el reloj anterior durante la transición.
        showClock = false
        stopTimer()
        StandaloneTimerCompletionStore.clear()
        completedSummary = nil
        timerStartedAt = nil
    }

    private func discardCompletedTimer() {
        dismissCompletedTimer()
    }

    private func saveCompletedTimer() {
        guard let summary = completedSummary else { return }
        let details = TimerCompletionDetails(
            modeRaw: summary.configuration.mode.rawValue,
            configuredSeconds: summary.configuredSeconds,
            rounds: summary.configuration.mode == .intervals ? summary.configuration.rounds : 1,
            workSeconds: summary.configuration.workTotalSeconds,
            restSeconds: summary.configuration.restTotalSeconds,
            countdownSeconds: summary.configuration.countdownBeforeStart ? 3 : 0
        )
        // Persist in Repera's workout history, NOT in Apple Health. Keep
        // the stable id in case the user taps twice or a pending result reloads.
        if !store.state.workouts.contains(where: { $0.id == summary.id }) {
            let session = WorkoutSession(
                id: summary.id,
                title: "Temporizador · " + summary.configuration.mode.title,
                exercises: [],
                phase: .finished,
                startedAt: summary.startedAt,
                finishedAt: summary.finishedAt,
                locationPin: summary.locationPin,
                timerDetails: details
            )
            store.saveWorkout(session)
        }
        dismissCompletedTimer()
    }

    private var clockScreen: some View {
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let shown = liveDisplaySeconds(at: context.date)
            BlockTimerScreen(
                title: "Temporizador",
                subtitle: clockSubtitle,
                exercise: nil,
                roundNumber: config.mode == .intervals ? roundNumber : nil,
                totalRounds: config.mode == .intervals ? config.rounds : nil,
                displaySeconds: shown,
                isRunning: isRunning,
                isCountingUp: config.mode == .up && preCountdown == 0,
                primaryTitle: primaryButtonTitle,
                onPrimary: { toggleRun() },
                onClose: {
                    stopTimer()
                    showClock = false
                }
            )
        }
    }

    private func liveDisplaySeconds(at now: Date) -> Int {
        if let end = preCountdownEnd {
            return WallClockTimer.remainingSeconds(until: end, now: now)
        }
        if !isRunning, let paused = pausedDisplaySeconds {
            return paused
        }
        switch config.mode {
        case .up:
            guard let start = phaseStartDate else { return displaySeconds }
            return min(
                config.durationTotalSeconds,
                WallClockTimer.elapsedSeconds(since: start, now: now)
            )
        case .down, .intervals:
            guard let end = phaseEndDate else { return displaySeconds }
            return WallClockTimer.remainingSeconds(until: end, now: now)
        }
    }

    private var clockSubtitle: String {
        if preCountdown > 0 { return "Cuenta atrás" }
        switch config.mode {
        case .up: return "Arriba"
        case .down: return "Abajo"
        case .intervals:
            return phaseIsWork ? "Trabajar" : "Descansar"
        }
    }

    private var primaryButtonTitle: String {
        // Durante la cuenta previa ya se puede pausar; nunca mostrar «…».
        return isRunning ? "Pausar" : "Continuar"
    }

    private func prepareAndShowClock() {
        StandaloneTimerConfigurationStore.save(config)
        completedSummary = nil
        timerStartedAt = nil
        StandaloneTimerCompletionStore.clear()
        stopTimer()
        isRunning = false
        phaseIsWork = true
        roundNumber = 1
        switch config.mode {
        case .up:
            displaySeconds = 0
        case .down:
            displaySeconds = config.durationTotalSeconds
        case .intervals:
            displaySeconds = config.workTotalSeconds
        }
        preCountdown = config.countdownBeforeStart ? 3 : 0
        showClock = true
    }

    private func toggleRun() {
        if isRunning {
            pausedDisplaySeconds = liveDisplaySeconds(at: Date())
            if preCountdownEnd != nil {
                preCountdown = max(1, pausedDisplaySeconds ?? preCountdown)
            }
            displaySeconds = pausedDisplaySeconds ?? displaySeconds
            stopTimer(keepState: true)
            isRunning = false
            preCountdownEnd = nil
            phaseEndDate = nil
            phaseStartDate = nil
            TimerLiveActivityCoordinator.shared.pause(
                .standalone, value: displaySeconds, title: "Temporizador"
            )
        } else {
            isRunning = true
            pausedDisplaySeconds = nil
            if preCountdown == 0 && timerStartedAt == nil {
                timerStartedAt = Date()
            }
            armAnchorsForResume()
            publishLiveClockAndAlerts()
            // Emitir también el primer 3 inmediatamente. Los otros
            // dos pitidos llegan por el reloj (2, 1), igual que Comenzar.
            if preCountdown > 0, preCountdownEnd != nil {
                RestFeedback.tick(remaining: preCountdown, sound: true, haptic: true)
            }
            startTicking()
        }
    }

    private func armAnchorsForResume() {
        let now = Date()
        if preCountdown > 0 {
            preCountdownEnd = WallClockTimer.endDate(from: now, lasting: preCountdown)
            phaseEndDate = nil
            phaseStartDate = nil
            return
        }
        switch config.mode {
        case .up:
            let already = displaySeconds
            phaseStartDate = now.addingTimeInterval(TimeInterval(-already))
            phaseEndDate = nil
        case .down, .intervals:
            phaseEndDate = WallClockTimer.endDate(from: now, lasting: max(1, displaySeconds))
            phaseStartDate = nil
        }
        preCountdownEnd = nil
    }

    private func startTicking() {
        timer?.invalidate()
        // Feedback / phase transitions only — UI uses TimelineView + wall clock.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                syncFromWallClock()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func syncFromWallClock() {
        let now = Date()
        if let end = preCountdownEnd {
            let remaining = WallClockTimer.remainingSeconds(until: end, now: now)
            preCountdown = remaining
            RestFeedback.tick(remaining: remaining, sound: true, haptic: true)
            if remaining == 0 {
                // The pre-countdown is not training time.
                timerStartedAt = end
                preCountdownEnd = nil
                RestFeedback.restComplete(sound: true, haptic: true)
                // Arm work phase
                switch config.mode {
                case .up:
                    displaySeconds = 0
                    phaseStartDate = now
                    phaseEndDate = nil
                case .down:
                    displaySeconds = config.durationTotalSeconds
                    phaseEndDate = WallClockTimer.endDate(from: now, lasting: config.durationTotalSeconds)
                case .intervals:
                    displaySeconds = config.workTotalSeconds
                    phaseIsWork = true
                    phaseEndDate = WallClockTimer.endDate(from: now, lasting: config.workTotalSeconds)
                }
                publishLiveClockAndAlerts()
            }
            return
        }
        guard isRunning else { return }

        switch config.mode {
        case .up:
            let elapsed = liveDisplaySeconds(at: now)
            displaySeconds = elapsed
            RestFeedback.tick(remaining: config.durationTotalSeconds - elapsed, sound: true, haptic: true)
            if elapsed >= config.durationTotalSeconds {
                let endedAt = (phaseStartDate ?? now).addingTimeInterval(
                    TimeInterval(config.durationTotalSeconds)
                )
                displaySeconds = config.durationTotalSeconds
                isRunning = false
                stopTimer(keepState: true)
                finishLiveClock()
                recordTimerCompletion(finishedAt: endedAt)
                RestFeedback.restComplete(sound: true, haptic: true)
            }
        case .down:
            let remaining = liveDisplaySeconds(at: now)
            displaySeconds = remaining
            if remaining <= 0 {
                let endedAt = phaseEndDate ?? now
                displaySeconds = 0
                isRunning = false
                stopTimer(keepState: true)
                finishLiveClock()
                recordTimerCompletion(finishedAt: endedAt)
                RestFeedback.restComplete(sound: true, haptic: true)
            } else {
                RestFeedback.tick(remaining: remaining, sound: true, haptic: true)
            }
        case .intervals:
            catchUpIntervals(now: now)
        }
    }

    /// Skip as many work/rest phases as wall-clock overtime requires (not just one).
    private func catchUpIntervals(now: Date) {
        guard let end = phaseEndDate else { return }
        if now < end {
            let remaining = WallClockTimer.remainingSeconds(until: end, now: now)
            displaySeconds = remaining
            RestFeedback.tick(remaining: remaining, sound: true, haptic: true)
            return
        }
        var cursor = end
        var safety = 0
        while now >= cursor, safety < 500 {
            safety += 1
            if phaseIsWork {
                if config.restTotalSeconds > 0 {
                    phaseIsWork = false
                    cursor = cursor.addingTimeInterval(TimeInterval(config.restTotalSeconds))
                } else if !advanceRoundAnchor(from: &cursor) {
                    return
                }
            } else {
                if !advanceRoundAnchor(from: &cursor) {
                    return
                }
            }
        }
        // Land in the phase that contains `now`.
        let phaseLen = phaseIsWork ? config.workTotalSeconds : config.restTotalSeconds
        let phaseStart = cursor.addingTimeInterval(TimeInterval(-phaseLen))
        let elapsedInPhase = now.timeIntervalSince(phaseStart)
        let remaining = max(0, TimeInterval(phaseLen) - elapsedInPhase)
        displaySeconds = Int(ceil(remaining))
        phaseEndDate = now.addingTimeInterval(remaining)
        RestFeedback.intervalBeep(sound: true, haptic: true)
        publishLiveClockAndAlerts()
    }

    /// Returns false when the timer finished all rounds.
    private func advanceRoundAnchor(from cursor: inout Date) -> Bool {
        if roundNumber >= config.rounds {
            displaySeconds = 0
            isRunning = false
            stopTimer(keepState: true)
            finishLiveClock()
            recordTimerCompletion(finishedAt: cursor)
            RestFeedback.restComplete(sound: true, haptic: true)
            return false
        }
        roundNumber += 1
        phaseIsWork = true
        cursor = cursor.addingTimeInterval(TimeInterval(config.workTotalSeconds))
        return true
    }

    private func advanceInterval() {
        RestFeedback.restComplete(sound: true, haptic: true)
        let now = Date()
        if phaseIsWork {
            if config.restTotalSeconds > 0 {
                phaseIsWork = false
                displaySeconds = config.restTotalSeconds
                phaseEndDate = WallClockTimer.endDate(from: now, lasting: config.restTotalSeconds)
            } else {
                finishOrNextRound()
            }
        } else {
            finishOrNextRound()
        }
        if isRunning { publishLiveClockAndAlerts() }
    }

    private func finishOrNextRound() {
        if roundNumber >= config.rounds {
            let endedAt = phaseEndDate ?? Date()
            displaySeconds = 0
            isRunning = false
            stopTimer(keepState: true)
            finishLiveClock()
            recordTimerCompletion(finishedAt: endedAt)
            RestFeedback.restComplete(sound: true, haptic: true)
            return
        }
        roundNumber += 1
        phaseIsWork = true
        displaySeconds = config.workTotalSeconds
        phaseEndDate = WallClockTimer.endDate(from: Date(), lasting: config.workTotalSeconds)
    }

    private func skipInterval() {
        guard config.mode == .intervals else { return }
        advanceInterval()
    }


    /// Publish fixed wall-clock anchors, not one-second host-app updates.
    /// ActivityKit keeps the lock-screen text moving while the app is suspended.
    private func publishLiveClockAndAlerts() {
        guard isRunning, showClock else { return }
        let now = Date()
        if let preCountdownEnd {
            TimerLiveActivityCoordinator.shared.countdown(
                .standalone, endDate: preCountdownEnd,
                totalSeconds: max(1, preCountdown), title: "Temporizador"
            )
        } else if config.mode == .up, let anchor = phaseStartDate {
            TimerLiveActivityCoordinator.shared.countUp(
                .standalone, anchor: anchor, title: "Temporizador"
            )
        } else if let phaseEndDate {
            TimerLiveActivityCoordinator.shared.countdown(
                .standalone, endDate: phaseEndDate,
                totalSeconds: max(1, liveDisplaySeconds(at: now)), title: "Temporizador"
            )
        }
        var boundaries: [TimerBoundaryNotifier.Boundary] = []
        let pre = max(0, preCountdownEnd?.timeIntervalSince(now) ?? 0)
        if pre > 0.5 {
            boundaries.append(.init(afterSeconds: pre, title: "Comienza el entrenamiento"))
        }
        switch config.mode {
        case .up:
            let remaining = preCountdownEnd != nil ? config.durationTotalSeconds
                : max(0, config.durationTotalSeconds - displaySeconds)
            boundaries.append(.init(
                afterSeconds: pre + TimeInterval(remaining),
                title: "Temporizador finalizado"
            ))
        case .down:
            let remaining = preCountdownEnd != nil ? config.durationTotalSeconds
                : liveDisplaySeconds(at: now)
            boundaries.append(.init(
                afterSeconds: pre + TimeInterval(remaining),
                title: "Temporizador finalizado"
            ))
        case .intervals:
            var elapsed = pre
            let remainingRounds = max(0, config.rounds - roundNumber + 1)
            if remainingRounds > 0 {
                for offset in 0..<remainingRounds {
                    if offset == 0, !phaseIsWork, preCountdownEnd == nil {
                        elapsed += TimeInterval(max(0, liveDisplaySeconds(at: now)))
                        boundaries.append(.init(afterSeconds: elapsed, title: "Descanso finalizado"))
                    } else {
                        let workSeconds = offset == 0 && preCountdownEnd == nil
                            ? max(0, liveDisplaySeconds(at: now)) : config.workTotalSeconds
                        elapsed += TimeInterval(workSeconds)
                        boundaries.append(.init(afterSeconds: elapsed, title: "Serie finalizada"))
                        if config.restTotalSeconds > 0 {
                            elapsed += TimeInterval(config.restTotalSeconds)
                            boundaries.append(.init(afterSeconds: elapsed, title: "Descanso finalizado"))
                        }
                    }
                }
                if !boundaries.isEmpty {
                    boundaries[boundaries.count - 1] = .init(
                        afterSeconds: elapsed, title: "Temporizador finalizado"
                    )
                }
            }
        }
        TimerBoundaryNotifier.schedule(.standalone, boundaries: boundaries)
    }

    private func finishLiveClock() {
        TimerBoundaryNotifier.cancel(.standalone)
        TimerLiveActivityCoordinator.shared.end(.standalone)
    }

    private func stopTimer(keepState: Bool = false) {
        TimerBoundaryNotifier.cancel(.standalone)
        if !keepState { TimerLiveActivityCoordinator.shared.end(.standalone) }
        timer?.invalidate()
        timer = nil
        preCountdownEnd = nil
        phaseEndDate = nil
        phaseStartDate = nil
        if !keepState {
            isRunning = false
            pausedDisplaySeconds = nil
            preCountdown = 0
            TimerScreenAwake.setRunning(false, for: .standalone)
        }
    }
}
