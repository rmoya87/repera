import ReperaDomain
import SwiftUI
import UIKit

private enum StartHubRoute: Hashable {
    case createWorkout
    case quickLog
    case favorites
    case timer
    case boardReview
}

/// Pestaña Crear: mismas transiciones push que el resto (sin sheet de abajo arriba).
struct StartHubSheet: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions

    var onGoPlan: () -> Void
    var onOpenedWorkout: () -> Void

    @State private var path = NavigationPath()
    @State private var showImageSourceSheet = false
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var captured: UIImage?
    @State private var reviewLines: [BoardImportLine] = []
    @State private var reviewOCR = ""
    @State private var reviewBlocks: [RoutineBlock] = []
    @State private var reviewSource: BoardImportPipeline.Source = .localRules
    @State private var isReading = false
    @State private var readingTask: Task<Void, Never>?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let session = store.state.activeSession {
                    Section {
                        Button {
                            onOpenedWorkout()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Continuar entrenamiento")
                                        .foregroundStyle(OG.label)
                                    Text(session.title)
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            } icon: {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(OG.orange)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            OGSwipeDeleteButton(accessibilityLabel: "Descartar entreno en curso") {
                                store.endActiveSession(save: false)
                            }
                        }
                    } footer: {
                        Text("Toca para continuar · desliza para eliminar (no se guarda)")
                    }
                }

                Section("Entrenamiento") {
                    NavigationLink(value: StartHubRoute.createWorkout) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Crear mi entreno")
                                    .foregroundStyle(OG.label)
                                Text("Bloques de fuerza y WODs — y empieza ya")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(OG.accent)
                        }
                    }

                    NavigationLink(value: StartHubRoute.quickLog) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apuntar series")
                                    .foregroundStyle(OG.label)
                                Text("Un ejercicio, sin montar rutina")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                                Image(systemName: "list.number")
                                .foregroundStyle(OG.yellow)
                        }
                    }

                    NavigationLink(value: StartHubRoute.favorites) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Favoritos")
                                    .foregroundStyle(OG.label)
                                Text(favoritesSubtitle)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundStyle(OG.yellow)
                        }
                    }

                    NavigationLink(value: StartHubRoute.timer) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Temporizador")
                                    .foregroundStyle(OG.label)
                                Text("Arriba, abajo o intervalos · reloj digital")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundStyle(OG.orange)
                        }
                    }

                    Button {
                        let decision = subscriptions.canStartBoardScan()
                        if decision.allowed {
                            showImageSourceSheet = true
                        } else {
                            subscriptions.presentPaywall(
                                decision.paywallContext,
                                feature: .unlimitedBoardScans
                            )
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Escanear pizarra o TV")
                                    .foregroundStyle(OG.label)
                                Text(subscriptions.policy.boardScanUsageCaption
                                      ?? "Cámara o galería · EMOM, ladder, fuerza…")
                                    .font(.caption)
                                    .foregroundStyle(OG.label2)
                            }
                        } icon: {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(OG.blue)
                        }
                    }
                    .disabled(isReading)
                }

                Section {
                    if store.plannedRoutines.isEmpty {
                        Button {
                            onGoPlan()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Crear plan de entreno")
                                        .foregroundStyle(OG.label)
                                    Text("Plan semanal en Diario")
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            } icon: {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundStyle(OG.accent)
                            }
                        }
                    } else {
                        ForEach(store.plannedRoutines) { routine in
                            Button {
                                store.startSession(from: routine)
                                onOpenedWorkout()
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(routine.title)
                                            .foregroundStyle(OG.label)
                                        Text(routine.weekday.map(CalendarHelpers.weekdayName).map { $0 } ?? "Sin día")
                                            .font(.caption)
                                            .foregroundStyle(OG.label2)
                                    }
                                } icon: {
                                    Image(systemName: "list.bullet.rectangle")
                                        .foregroundStyle(OG.blue)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                OGSwipeDeleteButton(systemImage: "xmark", tint: OG.label) {
                                    store.deleteRoutine(routine.id)
                                }
                            }
                        }
                        Button {
                            onGoPlan()
                        } label: {
                            Label("Editar plan de entreno", systemImage: "calendar")
                        }
                    }
                } header: {
                    Text("Entrenos por día")
                } footer: {
                    Text("Aquí ves lo asignado a cada día. El plan semanal se crea y edita en Diario.")
                }

                if isReading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Leyendo pizarra…")
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
                        }
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(OG.red)
                    }
                }
            }
            .ogListChrome()
            .ogFixedTopBar("Crear")
            .navigationDestination(for: StartHubRoute.self) { route in
                switch route {
                case .createWorkout:
                    DayEditorView(
                        routine: Routine(
                            title: "Mi entreno",
                            weekday: nil,
                            blocks: [.strength(title: "Bloque 1")],
                            progression: .off
                        ),
                        mode: .session,
                        onSessionStarted: onOpenedWorkout,
                        embedsNavigationStack: false
                    )
                case .quickLog:
                    QuickLogPickerView(onOpenedWorkout: onOpenedWorkout)
                case .favorites:
                    FavoritesHubView(onOpenedWorkout: onOpenedWorkout)
                case .timer:
                    StandaloneTimerView(embedsNavigation: false)
                case .boardReview:
                    BoardImportReviewView(
                        lines: reviewLines,
                        ocrText: reviewOCR,
                        detectedBlocks: reviewBlocks,
                        interpretSource: reviewSource,
                        allowsSaveToDay: false,
                        embedsNavigationStack: false
                    ) { started in
                        if started {
                            onOpenedWorkout()
                        } else if !path.isEmpty {
                            path.removeLast()
                        }
                    }
                }
            }
            .sheet(isPresented: $showImageSourceSheet) {
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
        }
    }

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

    /// Dispara OCR al cerrar cámara/galería (no usar onChange de UIImage: no es Equatable fiable).
    private func processCapturedImageIfNeeded() {
        guard let image = captured else {
            BoardScanLog.info("StartHub processCaptured: nil (dismiss sin foto)")
            return
        }
        guard !isReading else {
            BoardScanLog.info("StartHub processCaptured: skip (ya isReading)")
            return
        }
        let decision = subscriptions.canStartBoardScan()
        guard decision.allowed else {
            captured = nil
            subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedBoardScans)
            return
        }
        BoardScanLog.beginPass("StartHub")
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
            BoardScanLog.image(image, step: "StartHub.input")
            BoardScanLog.step("jpeg.prep", "start")
            guard let jpeg = BoardTextRecognizer.preparedJPEGDataOnMainIfNeeded(from: image) else {
                throw BoardTextRecognizer.RecognizerError.invalidImage
            }
            BoardScanLog.jpegPrepared(bytes: jpeg.count, path: "StartHub")
            try Task.checkCancellation()

            BoardScanLog.step("vision", "start")
            let text = try await BoardTextRecognizer.recognize(jpegData: jpeg)
            BoardScanLog.ocr(text)
            try Task.checkCancellation()

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
            reviewOCR = result.ocrText
            reviewBlocks = result.blocks
            reviewLines = result.lines
            reviewSource = result.source
            let attemptID = UUID().uuidString
            _ = subscriptions.consumeBoardScanIfNeeded(attemptID: attemptID)
            path.append(StartHubRoute.boardReview)
            BoardScanLog.endPass(ok: true, detail: result.source.rawValue)
        } catch is CancellationError {
            BoardScanLog.endPass(ok: false, detail: "cancelled")
        } catch {
            BoardScanLog.error("StartHub.scan: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            BoardScanLog.endPass(ok: false, detail: error.localizedDescription)
        }
    }
}
