import ReperaDomain
import SwiftUI
import UIKit

/// Importa una pizarra como BLOQUES en el editor actual; nunca crea otro entreno
/// ni altera la duración, kcal, FC o HealthKit de una clase ya grabada.
struct BoardScanIntoRoutineView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss

    let onInsertBlocks: ([RoutineBlock]) -> Void

    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var captured: UIImage?
    @State private var reading = false
    @State private var failure: String?
    @State private var review: BoardScanReviewPayload?
    @State private var scanTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if let review {
                    BoardImportReviewView(
                        lines: review.lines,
                        ocrText: review.ocrText,
                        detectedBlocks: review.blocks,
                        interpretSource: review.source,
                        allowsSaveToDay: false,
                        embedsNavigationStack: false,
                        onInsertBlocks: { blocks in
                            onInsertBlocks(blocks.map { $0.duplicatingContent() })
                            dismiss()
                        },
                        onDone: { _ in }
                    )
                } else {
                    List {
                        Section {
                            Text("Escanea la pizarra de tu clase para añadir sus bloques al entreno que ya has registrado. Revisa las series y las marcas antes de guardarlas como realizadas.")
                                .font(.footnote)
                                .foregroundStyle(OG.label2)
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button("Tomar foto", systemImage: "camera.fill") {
                                    guard checkScanPermission() else { return }
                                    showCamera = true
                                }
                            }
                            Button("Elegir de la galería", systemImage: "photo.on.rectangle") {
                                guard checkScanPermission() else { return }
                                showLibrary = true
                            }
                        }
                        if reading {
                            Section {
                                HStack {
                                    ProgressView()
                                    Text("Leyendo pizarra…")
                                }
                            }
                        }
                        if let failure {
                            Section { Text(failure).foregroundStyle(OG.red) }
                        }
                    }
                    .ogListChrome()
                    .navigationTitle("Escanear pizarra")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") {
                                scanTask?.cancel()
                                dismiss()
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: processCapturedImage) {
                CameraPicker(image: $captured).ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showLibrary, onDismiss: processCapturedImage) {
                LibraryPicker(image: $captured).ignoresSafeArea()
            }
        }
    }

    private func checkScanPermission() -> Bool {
        let decision = subscriptions.canStartBoardScan()
        guard decision.allowed else {
            subscriptions.presentPaywall(decision.paywallContext, feature: .unlimitedBoardScans)
            return false
        }
        return true
    }

    private func processCapturedImage() {
        guard let image = captured, !reading else { return }
        captured = nil
        guard checkScanPermission() else { return }
        failure = nil
        reading = true
        let catalog = store.state.exercises
        scanTask?.cancel()
        scanTask = Task { @MainActor in
            defer { reading = false; scanTask = nil }
            do {
                guard let jpeg = BoardTextRecognizer.preparedJPEGDataOnMainIfNeeded(from: image) else {
                    throw BoardTextRecognizer.RecognizerError.invalidImage
                }
                let text = try await BoardTextRecognizer.recognize(jpegData: jpeg)
                try Task.checkCancellation()
                let proposal = BoardImportPipeline.interpretSync(ocrText: text, catalog: catalog)
                guard !proposal.blocks.isEmpty || !proposal.lines.isEmpty else {
                    failure = "No se han encontrado ejercicios. Prueba con otra foto."
                    return
                }
                let result = BoardScanReviewPayload(
                    ocrText: proposal.ocrText, lines: proposal.lines, blocks: proposal.blocks,
                    source: proposal.source, targetDate: Date()
                )
                _ = subscriptions.consumeBoardScanIfNeeded(attemptID: result.id.uuidString)
                review = result
            } catch is CancellationError {
                // Cerrar el editor no guarda nada.
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}
