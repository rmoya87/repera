import GymbroDomain
import SwiftUI
import UIKit

private enum StartHubRoute: Hashable {
    case createWorkout
    case favorites
    case timer
    case boardReview
}

/// Pestaña Crear: mismas transiciones push que el resto (sin sheet de abajo arriba).
struct StartHubSheet: View {
    @Environment(GymbroStore.self) private var store

    var onGoPlan: () -> Void
    var onOpenedWorkout: () -> Void

    @State private var path = NavigationPath()
    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var captured: UIImage?
    @State private var reviewLines: [BoardImportLine] = []
    @State private var reviewOCR = ""
    @State private var reviewBlocks: [RoutineBlock] = []
    @State private var isReading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    OGPageHeader(title: "Crear")
                        .ogListPageHeaderRow()
                }

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
                            Button(role: .destructive) {
                                store.endActiveSession(save: false)
                            } label: {
                                Label("Cancelar", systemImage: "xmark")
                            }
                            .tint(OG.red)
                        }
                    } footer: {
                        Text("Toca para continuar · desliza para cancelar")
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

                    Menu {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("Tomar foto", systemImage: "camera") {
                                showCameraPicker = true
                            }
                        }
                        Button("Elegir de la galería", systemImage: "photo.on.rectangle") {
                            showLibraryPicker = true
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Escanear pizarra o TV")
                                    .foregroundStyle(OG.label)
                                Text("Cámara o galería · EMOM, ladder, fuerza…")
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
                                Button(role: .destructive) {
                                    store.deleteRoutine(routine.id)
                                } label: {
                                    Label("Eliminar", systemImage: "xmark")
                                }
                                .tint(OG.red)
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
            .ogContentTitleNav()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: StartHubRoute.self) { route in
                switch route {
                case .createWorkout:
                    DayEditorView(
                        routine: Routine(
                            title: "Mi entreno",
                            weekday: nil,
                            blocks: [.strength(title: "Bloque")],
                            progression: .off
                        ),
                        mode: .session,
                        onSessionStarted: onOpenedWorkout,
                        embedsNavigationStack: false
                    )
                case .favorites:
                    FavoritesHubView(onOpenedWorkout: onOpenedWorkout)
                case .timer:
                    StandaloneTimerView(embedsNavigation: false)
                case .boardReview:
                    BoardImportReviewView(
                        lines: reviewLines,
                        ocrText: reviewOCR,
                        detectedBlocks: reviewBlocks,
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
        }
        .preferredColorScheme(.dark)
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
            BoardScanLog.info("processCaptured: captured=nil tras dismiss")
            return
        }
        guard !isReading else {
            BoardScanLog.info("processCaptured: ya leyendo, skip")
            return
        }
        Task { await runOCR(image) }
    }

    private func runOCR(_ image: UIImage) async {
        isReading = true
        errorMessage = nil
        BoardScanLog.image(image, step: "runOCR.start")
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
                BoardScanLog.error("OCR/parser vacío tras leer \(text.count) chars")
                errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                return
            }
            reviewOCR = text
            reviewBlocks = blocks
            reviewLines = lines
            BoardScanLog.info("Navegando a revisión")
            path.append(StartHubRoute.boardReview)
        } catch {
            BoardScanLog.error("runOCR: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
