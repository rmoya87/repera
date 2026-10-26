import ReperaDomain
import SwiftUI
import UIKit

/// Resultado del escaneo para abrir la página «Añadir entreno» (fuera del sheet).
struct BoardScanReviewPayload: Identifiable, Hashable {
    let id: UUID
    var ocrText: String
    var lines: [BoardImportLine]
    var blocks: [RoutineBlock]
    var source: BoardImportPipeline.Source
    var targetDate: Date

    init(
        id: UUID = UUID(),
        ocrText: String,
        lines: [BoardImportLine],
        blocks: [RoutineBlock],
        source: BoardImportPipeline.Source,
        targetDate: Date
    ) {
        self.id = id
        self.ocrText = ocrText
        self.lines = lines
        self.blocks = blocks
        self.source = source
        self.targetDate = targetDate
    }
}

/// Menú para dar de alta un entreno de un día concreto (no el plan semanal).
struct DayPlusSheet: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    /// Día del calendario al que se asigna el entreno suelto.
    var targetDate: Date = Calendar.current.startOfDay(for: Date())
    /// Los destinos se abren como páginas nativas tras cerrar la modal.
    var onCreateWorkout: () -> Void = {}
    var onOpenFavorites: () -> Void = {}
    var onOpenTimer: () -> Void = {}
    /// Tras escanear: el caller cierra el sheet y abre la página de revisión.
    var onBoardReady: (BoardScanReviewPayload) -> Void = { _ in }

    @State private var showImageSourceDialog = false
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var captured: UIImage?
    @State private var isReading = false
    @State private var readingTask: Task<Void, Never>?
    @State private var errorMessage: String?
    private var dayStart: Date { Calendar.current.startOfDay(for: targetDate) }

    private var favoritesSubtitle: String {
        let workouts = store.favoriteRoutines.count
        let timers = store.state.favoriteTimers.count
        let total = workouts + timers
        if total == 0 { return "Entrenos y temporizadores habituales" }
        var parts: [String] = []
        if workouts > 0 { parts.append("\(workouts) entreno\(workouts == 1 ? "" : "s")") }
        if timers > 0 { parts.append("\(timers) tempo") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        // Esta vista ya no tiene rutas internas ni pantallas completas.
        menuContent
            .tint(OG.accent)
            .sheet(isPresented: $showImageSourceDialog) {
                BoardScanSourceSheet(
                    onCamera: { showCameraPicker = true },
                    onLibrary: { showLibraryPicker = true }
                )
            }
            .fullScreenCover(isPresented: $showCameraPicker, onDismiss: {
                processCapturedImageIfNeeded()
            }) {
                CameraPicker(image: $captured).ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showLibraryPicker, onDismiss: {
                processCapturedImageIfNeeded()
            }) {
                LibraryPicker(image: $captured).ignoresSafeArea()
            }
            // La sheet nativa entra desde abajo y sale hacia abajo.
            .ogFittedSheet(freezeHeight: showLibraryPicker || showCameraPicker)
    }

    /// Menú con tamaño intrínseco (sin List) para que el sheet ajuste el alto.
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Añadir entreno") {
                CloseToolbarButton(action: { dismiss() }, large: true)
            }

            VStack(spacing: 0) {
                Button(action: onCreateWorkout) {
                    menuLabel(
                        title: "Crear entreno",
                        subtitle: "Bloques de fuerza y WODs",
                        systemName: "plus.circle.fill",
                        tint: OG.accent
                    )
                }
                menuDivider
                Button(action: onOpenFavorites) {
                    menuLabel(
                        title: "Favoritos",
                        subtitle: favoritesSubtitle,
                        systemName: "star.fill",
                        tint: OG.yellow
                    )
                }
                menuDivider
                Button(action: onOpenTimer) {
                    menuLabel(
                        title: "Temporizador",
                        subtitle: "Arriba, abajo o intervalos · reloj digital",
                        systemName: "timer",
                        tint: OG.orange
                    )
                }
                menuDivider
                Button { requestBoardScan() } label: {
                    menuLabel(
                        title: "Escanear pizarra o TV",
                        subtitle: "Cámara o galería",
                        systemName: "camera.viewfinder",
                        tint: OG.blue
                    )
                }
                .disabled(isReading)
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            if let caption = subscriptions.policy.boardScanUsageCaption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(OG.label3)
                    .padding(.horizontal, 4)
            }

            if isReading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Leyendo ejercicios…")
                        .foregroundStyle(OG.label2)
                    Spacer(minLength: 0)
                    Button("Cancelar") {
                        readingTask?.cancel()
                        readingTask = nil
                        isReading = false
                        captured = nil
                        BoardScanLog.endPass(ok: false, detail: "cancel usuario")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OG.accent)
                }
                .padding(.horizontal, 4)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(OG.red)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
    }

    private var menuDivider: some View {
        Divider().opacity(0.35).padding(.leading, 52)
    }

    private func menuLabel(
        title: String,
        subtitle: String,
        systemName: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func requestBoardScan() {
        let decision = subscriptions.canStartBoardScan()
        guard decision.allowed else {
            subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedBoardScans)
            return
        }
        showImageSourceDialog = true
    }

    private func processCapturedImageIfNeeded() {
        guard let image = captured else {
            BoardScanLog.info("DayPlus processCaptured: nil (dismiss sin foto)")
            return
        }
        guard !isReading else {
            BoardScanLog.info("DayPlus processCaptured: skip (ya isReading)")
            return
        }
        let decision = subscriptions.canStartBoardScan()
        guard decision.allowed else {
            captured = nil
            subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedBoardScans)
            return
        }
        BoardScanLog.beginPass("DayPlus")
        readingTask?.cancel()
        let catalog = store.state.exercises.map { $0 }
        isReading = true
        errorMessage = nil
        readingTask = Task { @MainActor in
            await self.executeBoardScan(image: image, catalog: catalog)
            self.readingTask = nil
        }
    }

    @MainActor
    private func executeBoardScan(image: UIImage, catalog: [Exercise]) async {
        defer {
            isReading = false
            captured = nil
        }
        do {
            BoardScanLog.image(image, step: "DayPlus.input")
            BoardScanLog.step("jpeg.prep", "start")
            guard let jpeg = BoardTextRecognizer.preparedJPEGDataOnMainIfNeeded(from: image) else {
                throw BoardTextRecognizer.RecognizerError.invalidImage
            }
            BoardScanLog.jpegPrepared(bytes: jpeg.count, path: "DayPlus")
            try Task.checkCancellation()

            BoardScanLog.step("vision", "start")
            let text = try await BoardTextRecognizer.recognize(jpegData: jpeg)
            BoardScanLog.ocr(text)
            try Task.checkCancellation()

            // Parse LITE síncrono — sin BoardImportParser / hilos / IA.
            BoardScanLog.step("interpret", "start catalog=\(catalog.count)")
            let result = BoardImportPipeline.interpretSync(ocrText: text, catalog: catalog)
            BoardScanLog.step(
                "interpret.done",
                "blocks=\(result.blocks.count) lines=\(result.lines.count) source=\(result.source.rawValue)"
            )

            if result.blocks.isEmpty && result.lines.isEmpty {
                errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                BoardScanLog.endPass(ok: false, detail: "sin bloques ni líneas")
                return
            }
            // Cerrar modal y abrir página completa en Inicio («Añadir entreno»).
            let payload = BoardScanReviewPayload(
                ocrText: result.ocrText,
                lines: result.lines,
                blocks: result.blocks,
                source: result.source,
                targetDate: dayStart
            )
            // Consumo solo con revisión usable (bloques/líneas no vacíos).
            _ = subscriptions.consumeBoardScanIfNeeded(attemptID: payload.id.uuidString)
            BoardScanLog.step("nav.boardReview", "página (dismiss sheet)")
            BoardScanLog.endPass(ok: true, detail: result.source.rawValue)
            onBoardReady(payload)
            dismiss()
        } catch is CancellationError {
            BoardScanLog.endPass(ok: false, detail: "cancelled")
        } catch {
            BoardScanLog.error("DayPlus.scan: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            BoardScanLog.endPass(ok: false, detail: error.localizedDescription)
        }
    }
}

struct BoardImportReviewView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var lines: [BoardImportLine]
    var ocrText: String
    var detectedBlocks: [RoutineBlock] = []
    var interpretSource: BoardImportPipeline.Source = .localRules
    /// Día ISO preferido al abrir (p. ej. viernes seleccionado). Si nil, hoy.
    var preferredWeekday: Int? = nil
    /// Fecha concreta para entreno suelto (Inicio).
    var preferredDate: Date? = nil
    /// Desde Diario / Inicio se puede guardar al día; desde Crear solo Empezar.
    var allowsSaveToDay: Bool = true
    var embedsNavigationStack: Bool = true
    var onDone: (_ started: Bool) -> Void

    @State private var targetWeekday: Int = CalendarHelpers.isoWeekday()
    @State private var targetDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var draftRoutine: Routine = Routine(title: "Añadir entreno", blocks: [])
    @State private var didApplyPreferredDay = false
    @State private var didSeedBlocks = false
    @State private var showEditor = false

    private var blocks: [RoutineBlock] { draftRoutine.blocks }

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { reviewContent }
            } else {
                reviewContent
            }
        }
    }

    private var reviewContent: some View {
        List {
            if !blocks.isEmpty {
                Section {
                    OGRoutineBlocksList(blocks: blocks, showsChevron: true) { _ in
                        showEditor = true
                    }
                }
            }

            if allowsSaveToDay {
                Section {
                    Picker("Día", selection: $targetWeekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(CalendarHelpers.weekdayName(day)).tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: targetWeekday) { _, day in
                        targetDate = resolvedSaveDate(for: day)
                    }
                } header: {
                    Text("Guardar entreno")
                }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Añadir entreno")
        .toolbar {
            if embedsNavigationStack {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                        onDone(false)
                    }
                }
            }
            if allowsSaveToDay {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let day = targetWeekday
                        let saveDate = resolvedSaveDate(for: day)
                        targetDate = saveDate
                        BoardScanLog.info("Review Guardar weekday=\(day) date=\(saveDate)")
                        _ = store.saveBoardToDay(
                            weekday: day,
                            lines: lines,
                            ocrText: ocrText.isEmpty ? nil : ocrText,
                            blocks: blocks.isEmpty ? nil : blocks,
                            onDate: saveDate
                        )
                        if embedsNavigationStack { dismiss() }
                        onDone(false)
                    } label: {
                        Label("Guardar", systemImage: "checkmark")
                    }
                    .tint(OG.label)
                    .disabled(!canConfirm)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    let ok = store.startSessionFromBoard(
                        lines: lines,
                        ocrText: ocrText.isEmpty ? nil : ocrText,
                        blocks: blocks.isEmpty ? nil : blocks
                    )
                    BoardScanLog.info("Review Empezar ok=\(ok)")
                    guard ok else { return }
                    if embedsNavigationStack { dismiss() }
                    onDone(true)
                } label: {
                    Label("Empezar", systemImage: "play.fill")
                }
                .fontWeight(.semibold)
                .tint(OG.accent)
                .disabled(!canConfirm)
            }
        }
        .navigationDestination(isPresented: $showEditor) {
            DayEditorView(
                routine: draftRoutine,
                mode: .session,
                onClose: { showEditor = false },
                onApplyDraft: { edited in
                    draftRoutine = edited
                    showEditor = false
                },
                embedsNavigationStack: false,
                usesPageCloseHeader: true
            )
            .id(draftRoutine.id)
        }
        .onAppear { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        if !didApplyPreferredDay {
            if let preferredDate {
                targetDate = Calendar.current.startOfDay(for: preferredDate)
                targetWeekday = CalendarHelpers.isoWeekday(for: targetDate)
            } else if let preferredWeekday, (1...7).contains(preferredWeekday) {
                targetWeekday = preferredWeekday
                targetDate = resolvedSaveDate(for: preferredWeekday)
            } else {
                targetDate = resolvedSaveDate(for: targetWeekday)
            }
            didApplyPreferredDay = true
        }
        guard !didSeedBlocks else {
            BoardScanLog.step("review.seed", "skip (ya sembrado)")
            return
        }
        didSeedBlocks = true
        BoardScanLog.step(
            "review.seed",
            "detected=\(detectedBlocks.count) lines=\(lines.count) ocrChars=\(ocrText.count)"
        )

        // Solo bloques del pipeline (lite). No re-parsear con BoardImportParser (cuelga en device).
        var seeded: [RoutineBlock]
        if !detectedBlocks.isEmpty {
            seeded = detectedBlocks
            BoardScanLog.step("review.seed", "usando detectedBlocks")
        } else if !ocrText.isEmpty {
            seeded = BoardScanLiteParser.parse(ocrText: ocrText).blocks
            BoardScanLog.step("review.seed", "lite re-parse blocks=\(seeded.count)")
        } else {
            seeded = []
            BoardScanLog.step("review.seed", "sin bloques ni OCR")
        }
        // Fallback: líneas tipadas → un bloque de fuerza (sin BoardImportParser).
        if seeded.isEmpty, lines.contains(where: \.isIncluded) {
            var exercises: [RoutineExercise] = []
            for line in lines where line.isIncluded {
                let exerciseId: UUID
                if let id = line.matchedExerciseId {
                    exerciseId = id
                } else {
                    let name = (line.matchedName ?? line.raw).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { continue }
                    let custom = Exercise(name: name, muscleGroup: "Custom", isCustom: true)
                    store.state.exercises.append(custom)
                    exerciseId = custom.id
                }
                let sets = (0..<max(1, line.sets)).map { _ in
                    PlannedSet(targetReps: max(1, line.reps), targetWeightKg: line.weightKg)
                }
                exercises.append(RoutineExercise(exerciseId: exerciseId, plannedSets: sets))
            }
            if !exercises.isEmpty {
                seeded = [.strength(title: "Fuerza", exercises: exercises)]
            }
            BoardScanLog.step("review.seed", "fallback lines→fuerza blocks=\(seeded.count)")
        }
        let testedOneRMs: [UUID: Double] = Dictionary(
            uniqueKeysWithValues: store.state.exerciseLoadPrefs.compactMap { key, pref in
                guard let tested = pref.testedOneRMKg, tested > 0,
                      let id = UUID(uuidString: key) else { return nil }
                return (id, tested)
            }
        )
        seeded = LoadSuggestion.applyPercentLoads(
            to: seeded,
            workouts: store.state.workouts,
            catalog: store.state.exercises,
            incrementKg: store.state.settings.weightIncrementKg,
            testedOneRMByExerciseId: testedOneRMs
        )
        for i in seeded.indices {
            seeded[i].deriveEmomRoundsIfNeeded()
        }
        draftRoutine = Routine(title: "Añadir entreno", blocks: seeded, progression: .off)
        BoardScanLog.blocksSummary(seeded, prefix: "review")
        BoardScanLog.step(
            "review.ready",
            "blocks=\(seeded.count) weekday=\(targetWeekday) source=\(interpretSource.rawValue)"
        )
    }

    /// Fecha del día elegido: respeta el día de Inicio si coincide; si no, el próximo ese weekday.
    private func resolvedSaveDate(for isoWeekday: Int) -> Date {
        let calendar = Calendar.current
        if let preferredDate {
            let preferred = calendar.startOfDay(for: preferredDate)
            if CalendarHelpers.isoWeekday(for: preferred) == isoWeekday {
                return preferred
            }
            return CalendarHelpers.nextDate(forISOWeekday: isoWeekday, from: preferred)
        }
        return CalendarHelpers.nextDate(forISOWeekday: isoWeekday)
    }

    private var canConfirm: Bool {
        blocks.contains { block in
            switch block.kind {
            case .strength: return !block.exercises.isEmpty
            case .wod: return !block.movements.filter { !$0.isRest }.isEmpty
            }
        } || lines.contains(where: \.isIncluded)
    }
}
