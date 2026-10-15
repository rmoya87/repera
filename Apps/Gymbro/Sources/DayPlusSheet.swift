import GymbroDomain
import SwiftUI
import UIKit

/// Menú para dar de alta un entreno de un día (no el plan semanal).
struct DayPlusSheet: View {
    @Environment(GymbroStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Día ISO (1=lun … 7=dom) al que se asignará el entreno. Por defecto: hoy.
    var targetWeekday: Int = CalendarHelpers.isoWeekday()
    var onGoPlan: () -> Void
    var onStartedWorkout: () -> Void

    @State private var showImageSourceDialog = false
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var captured: UIImage?
    @State private var reviewLines: [BoardImportLine] = []
    @State private var reviewOCR = ""
    @State private var reviewBlocks: [RoutineBlock] = []
    @State private var showReview = false
    @State private var isReading = false
    @State private var errorMessage: String?
    @State private var showDayEditor = false

    private var dayName: String { CalendarHelpers.weekdayName(targetWeekday) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showDayEditor = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Crear entreno")
                                    .foregroundStyle(OG.label)
                                Text("Bloques de fuerza y WODs · \(dayName)")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(OG.accent)
                        }
                    }

                    Button {
                        showImageSourceDialog = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Escanear pizarra o TV")
                                    .foregroundStyle(OG.label)
                                Text("Entreno suelto para \(dayName)")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(OG.blue)
                        }
                    }
                    .disabled(isReading)
                } header: {
                    Text("Entreno · \(dayName)")
                } footer: {
                    Text("Esto es un entreno para este día, no tu plan semanal. El plan se gestiona en Diario.")
                }

                Section {
                    Button {
                        dismiss()
                        onGoPlan()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ir al plan de entreno")
                                    .foregroundStyle(OG.label)
                                Text("Plan semanal en Diario · días fijos")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(OG.orange)
                        }
                    }
                } header: {
                    Text("Plan de entreno")
                }

                if isReading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Leyendo ejercicios…")
                                .foregroundStyle(OG.label2)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(OG.red)
                    }
                }
            }
            .ogListChrome()
            .navigationTitle("Añadir entreno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
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
                    preferredWeekday: targetWeekday
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
                        title: dayName,
                        weekday: targetWeekday,
                        blocks: [.strength(title: "Bloque")],
                        progression: .linear
                    ),
                    mode: .plan(isNew: true)
                )
                .onDisappear {
                    if store.state.routines.contains(where: { $0.weekday == targetWeekday }) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
            let catalog = store.state.exercises
            let blocks = BoardImportParser.parseBlocks(ocrText: text, catalog: catalog)
            var lines = BoardImportParser.parse(ocrText: text, catalog: catalog)
            let movements = blocks.reduce(0) { $0 + $1.movements.filter { !$0.isRest }.count }
            BoardScanLog.parse(blocks: blocks.count, lines: lines.count, movements: movements)

            if lines.isEmpty, !blocks.isEmpty {
                lines = blocks.flatMap(\.movements).filter { !$0.isRest }.map {
                    BoardImportLine(raw: $0.summaryLine, matchedName: $0.name, sets: 1, reps: $0.reps ?? 1)
                }
            }
            if blocks.isEmpty && lines.isEmpty {
                errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                return
            }
            reviewOCR = text
            reviewBlocks = blocks
            reviewLines = lines
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
    /// Día ISO preferido al abrir (p. ej. viernes seleccionado). Si nil, hoy.
    var preferredWeekday: Int? = nil
    var embedsNavigationStack: Bool = true
    var onDone: (_ started: Bool) -> Void

    @State private var targetWeekday: Int = CalendarHelpers.isoWeekday()
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
                Text(blocks.isEmpty
                     ? "Revisa ejercicios detectados. Puedes quitar líneas o ajustar series/reps."
                     : "Se detectaron \(blocks.count) bloque(s). Revisa formato y movimientos (DU→dobles, OHSQ→overhead squat…).")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
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

            Section {
                Picker("Día", selection: $targetWeekday) {
                    ForEach(1...7, id: \.self) { day in
                        Text(CalendarHelpers.weekdayName(day)).tag(day)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Guardar entreno")
            } footer: {
                Text("Entreno suelto para \(CalendarHelpers.weekdayName(targetWeekday)). No crea tu plan semanal; eso se hace en Diario.")
            }
        }
        .ogListChrome()
        .navigationTitle("De la pizarra")
        .navigationBarTitleDisplayMode(.inline)
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
                Button("Al \(CalendarHelpers.weekdayName(targetWeekday).prefix(3).lowercased())") {
                    let day = targetWeekday
                    BoardScanLog.info("Review Al día weekday=\(day) (\(CalendarHelpers.weekdayName(day)))")
                    _ = store.saveBoardToDay(
                        weekday: day,
                        lines: lines,
                        ocrText: ocrText.isEmpty ? nil : ocrText,
                        blocks: blocks.isEmpty ? nil : blocks
                    )
                    if embedsNavigationStack { dismiss() }
                    onDone(false)
                }
                .disabled(!canConfirm)
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
            if !didApplyPreferredDay, let preferredWeekday, (1...7).contains(preferredWeekday) {
                targetWeekday = preferredWeekday
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
            BoardScanLog.info(
                "Review onAppear: detectedBlocks=\(detectedBlocks.count) "
                    + "blocks=\(blocks.count) lines=\(lines.count) ocr=\(ocrText.count)c "
                    + "weekday=\(targetWeekday)"
            )
        }
    }

    private var canConfirm: Bool {
        if !blocks.isEmpty { return true }
        return lines.contains(where: \.isIncluded)
    }
}
