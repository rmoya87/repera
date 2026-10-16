import GymbroDomain
import SwiftUI
import UIKit

private enum DayPlusRoute: Hashable {
    case favorites
    case timer
}

/// Menú para dar de alta un entreno de un día concreto (no el plan semanal).
struct DayPlusSheet: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Día del calendario al que se asigna el entreno suelto.
    var targetDate: Date = Calendar.current.startOfDay(for: Date())
    var onGoPlan: () -> Void = {}
    var onStartedWorkout: () -> Void

    @State private var showImageSourceDialog = false
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var captured: UIImage?
    @State private var reviewLines: [BoardImportLine] = []
    @State private var reviewOCR = ""
    @State private var reviewBlocks: [RoutineBlock] = []
    @State private var reviewSource: BoardImportPipeline.Source = .localRules
    @State private var showReview = false
    @State private var isReading = false
    @State private var errorMessage: String?
    @State private var showDayEditor = false
    @State private var path = NavigationPath()

    private var targetWeekday: Int { CalendarHelpers.isoWeekday(for: targetDate) }
    private var dayName: String { CalendarHelpers.weekdayName(targetWeekday) }
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

    private var isPushed: Bool { !path.isEmpty }

    var body: some View {
        NavigationStack(path: $path) {
            menuContent
                .tint(OG.accent)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: DayPlusRoute.self) { route in
                    switch route {
                    case .favorites:
                        FavoritesHubView(onOpenedWorkout: {
                            dismiss()
                            onStartedWorkout()
                        })
                    case .timer:
                        StandaloneTimerView(embedsNavigation: false)
                    }
                }
                .confirmationDialog("Escanear pizarra", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Tomar foto") { showCameraPicker = true }
                    }
                    Button("Elegir de la galería") { showLibraryPicker = true }
                    Button("Cancelar", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $showCameraPicker, onDismiss: {
                    processCapturedImageIfNeeded()
                }) {
                    CameraPicker(image: $captured).ignoresSafeArea()
                }
                .sheet(isPresented: $showLibraryPicker, onDismiss: {
                    processCapturedImageIfNeeded()
                }) {
                    PhotoLibraryPicker(image: $captured)
                        .ignoresSafeArea()
                }
                .sheet(isPresented: $showReview) {
                    BoardImportReviewView(
                        lines: reviewLines,
                        ocrText: reviewOCR,
                        detectedBlocks: reviewBlocks,
                        interpretSource: reviewSource,
                        preferredWeekday: targetWeekday,
                        preferredDate: dayStart
                    ) { started in
                        showReview = false
                        if started {
                            dismiss()
                            onStartedWorkout()
                        } else {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showDayEditor) {
                    DayEditorView(
                        routine: Routine(
                            title: "Entreno · \(dayName)",
                            weekday: nil,
                            scheduledDate: dayStart,
                            blocks: [.strength(title: "Bloque")],
                            progression: .off
                        ),
                        mode: .oneOff(isNew: true)
                    )
                    .onDisappear {
                        if store.routineForDay(dayStart)?.isOneOff == true {
                            dismiss()
                        }
                    }
                }
        }
        .preferredColorScheme(.dark)
        .ogFittedSheet(expanded: isPushed)
    }

    /// Menú con tamaño intrínseco (sin List) para que el sheet ajuste el alto.
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Añadir entreno", subtitle: dayName) {
                CloseToolbarButton(action: { dismiss() }, large: true)
            }
            .padding(.top, 4)

            Text("Entreno")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(OG.label2)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Button { showDayEditor = true } label: {
                    menuLabel(
                        title: "Crear entreno",
                        subtitle: "Bloques de fuerza y WODs",
                        systemName: "plus.circle.fill",
                        tint: OG.accent
                    )
                }
                menuDivider
                NavigationLink(value: DayPlusRoute.favorites) {
                    menuLabel(
                        title: "Favoritos",
                        subtitle: favoritesSubtitle,
                        systemName: "star.fill",
                        tint: OG.yellow
                    )
                }
                menuDivider
                NavigationLink(value: DayPlusRoute.timer) {
                    menuLabel(
                        title: "Temporizador",
                        subtitle: "Arriba, abajo o intervalos · reloj digital",
                        systemName: "timer",
                        tint: OG.orange
                    )
                }
                menuDivider
                Button { showImageSourceDialog = true } label: {
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

            if isReading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Leyendo ejercicios…")
                        .foregroundStyle(OG.label2)
                }
                .padding(.horizontal, 4)
            }

            if let errorMessage {
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

    private func processCapturedImageIfNeeded() {
        guard let image = captured else {
            BoardScanLog.info("DayPlus processCaptured: nil")
            return
        }
        guard !isReading else { return }
        Task { await runOCR(image) }
    }

    private func runOCR(_ image: UIImage) async {
        isReading = true
        errorMessage = nil
        BoardScanLog.image(image, step: "DayPlus.runOCR.start")
        defer {
            isReading = false
            captured = nil
        }
        do {
            let text = try await BoardTextRecognizer.recognize(in: image)
            BoardScanLog.ocr(text)
            let result = await BoardImportPipeline.interpret(
                ocrText: text,
                catalog: store.state.exercises
            )
            if result.blocks.isEmpty && result.lines.isEmpty {
                errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                return
            }
            reviewOCR = result.ocrText
            reviewBlocks = result.blocks
            reviewLines = result.lines
            reviewSource = result.source
            showReview = true
        } catch {
            BoardScanLog.error("DayPlus.runOCR: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}

struct BoardImportReviewView: View {
    @Environment(GymbroStore.self) private var store
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
    @State private var blocks: [RoutineBlock] = []
    @State private var didApplyPreferredDay = false

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack { reviewContent }
                    .preferredColorScheme(.dark)
            } else {
                reviewContent
            }
        }
    }

    private var reviewContent: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(blocks.isEmpty
                         ? "Revisa ejercicios detectados. Puedes quitar líneas o ajustar series/reps."
                         : "Se detectaron \(blocks.count) bloque(s). Revisa formato y movimientos.")
                        .font(.footnote)
                        .foregroundStyle(OG.label2)
                    Text(interpretSource == .appleIntelligence
                         ? "Interpretado con Apple Intelligence (en el dispositivo)."
                         : "Interpretado con análisis local (gratis · sin Apple Intelligence).")
                        .font(.caption2)
                        .foregroundStyle(OG.label3)
                }
                .listRowBackground(Color.clear)
            }

            if !blocks.isEmpty {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { idx, wod in
                    Section("Bloque \(idx + 1) · \(wod.headerLabel)") {
                        ForEach(wod.movements) { move in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(move.summaryLine)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(OG.label)
                                if let notes = move.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(OG.label3)
                                }
                            }
                        }
                    }
                }
            } else {
                Section("Ejercicios detectados") {
                    ForEach($lines) { $line in
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $line.isIncluded) {
                                Text(line.matchedName ?? line.raw)
                                    .foregroundStyle(OG.label)
                            }
                            .tint(OG.accent)
                            Text(line.raw)
                                .font(.caption)
                                .foregroundStyle(OG.label3)
                            HStack {
                                Stepper("\(line.sets) series", value: $line.sets, in: 1...10)
                                Stepper("\(line.reps) reps", value: $line.reps, in: 1...50)
                            }
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                        }
                        .padding(.vertical, 4)
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
                } footer: {
                    Text("Se guarda como entreno suelto de \(CalendarHelpers.weekdayName(targetWeekday)) (aparece en Inicio · Entreno del día). No forma parte del plan semanal de Diario ni del historial hasta que lo termines.")
                }
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("De la pizarra")
        .toolbar {
            if embedsNavigationStack {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                        onDone(false)
                    }
                }
            }
            ToolbarItemGroup(placement: .confirmationAction) {
                if allowsSaveToDay {
                    Button("Al \(CalendarHelpers.weekdayName(targetWeekday).prefix(3).lowercased())") {
                        let day = targetWeekday
                        let saveDate = resolvedSaveDate(for: day)
                        targetDate = saveDate
                        BoardScanLog.info("Review Al día weekday=\(day) date=\(saveDate)")
                        _ = store.saveBoardToDay(
                            weekday: day,
                            lines: lines,
                            ocrText: ocrText.isEmpty ? nil : ocrText,
                            blocks: blocks.isEmpty ? nil : blocks,
                            onDate: saveDate
                        )
                        if embedsNavigationStack { dismiss() }
                        onDone(false)
                    }
                    .disabled(!canConfirm)
                }
                Button("Empezar") {
                    let ok = store.startSessionFromBoard(
                        lines: lines,
                        ocrText: ocrText.isEmpty ? nil : ocrText
                    )
                    BoardScanLog.info("Review Empezar ok=\(ok)")
                    guard ok else { return }
                    if embedsNavigationStack { dismiss() }
                    onDone(true)
                }
                .fontWeight(.semibold)
                .disabled(!canConfirm)
            }
        }
        .onAppear {
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
            if !detectedBlocks.isEmpty {
                blocks = detectedBlocks
            } else {
                blocks = BoardImportParser.parseBlocks(
                    ocrText: ocrText.isEmpty ? lines.map(\.raw).joined(separator: "\n") : ocrText,
                    catalog: store.state.exercises
                )
            }
            let testedOneRMs: [UUID: Double] = Dictionary(
                uniqueKeysWithValues: store.state.exerciseLoadPrefs.compactMap { key, pref in
                    guard let tested = pref.testedOneRMKg, tested > 0,
                          let id = UUID(uuidString: key) else { return nil }
                    return (id, tested)
                }
            )
            blocks = LoadSuggestion.applyPercentLoads(
                to: blocks,
                workouts: store.state.workouts,
                catalog: store.state.exercises,
                incrementKg: store.state.settings.weightIncrementKg,
                testedOneRMByExerciseId: testedOneRMs
            )
            BoardScanLog.info(
                "Review onAppear: detectedBlocks=\(detectedBlocks.count) "
                    + "blocks=\(blocks.count) lines=\(lines.count) ocr=\(ocrText.count)c "
                    + "weekday=\(targetWeekday)"
            )
        }
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
        if !blocks.isEmpty { return true }
        return lines.contains(where: \.isIncluded)
    }
}
