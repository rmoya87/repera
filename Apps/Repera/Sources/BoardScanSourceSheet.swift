import ReperaDomain
import SwiftUI
import UIKit

/// Modal compacto para elegir cámara o galería (no Menu/popover).
struct BoardScanSourceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onCamera: () -> Void
    var onLibrary: () -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Escanear pizarra", subtitle: "Cámara o galería") {
                CloseToolbarButton(action: { dismiss() }, large: true)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                if cameraAvailable {
                    Button {
                        dismiss()
                        DispatchQueue.main.async {
                            onCamera()
                        }
                    } label: {
                        sourceRow(
                            title: "Tomar foto",
                            subtitle: "Abrir la cámara",
                            systemName: "camera.fill",
                            tint: OG.accent
                        )
                    }
                    Divider().opacity(0.35).padding(.leading, 52)
                }
                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onLibrary()
                    }
                } label: {
                    sourceRow(
                        title: "Elegir de la galería",
                        subtitle: "Foto de pizarra o TV",
                        systemName: "photo.on.rectangle",
                        tint: OG.blue
                    )
                }
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private func sourceRow(
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
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}


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
        Group {
            if let review {
                // El editor de la pizarra sí necesita navegación y espacio.
                // El menú inicial NO usa NavigationStack: su altura debe ser
                // intrínseca para que entre como sheet nativa desde abajo.
                NavigationStack {
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
                }
            } else {
                scanSourceMenu
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: processCapturedImage) {
            CameraPicker(image: $captured).ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showLibrary, onDismiss: processCapturedImage) {
            LibraryPicker(image: $captured).ignoresSafeArea()
        }
        .tint(OG.accent)
        // Esta vista se presenta desde una .sheet del editor: el sistema
        // realiza entrada desde abajo y salida hacia abajo al pulsar X o
        // deslizar. Al pasar a la revisión ampliamos la misma hoja.
        .ogFittedSheet(expanded: review != nil, freezeHeight: showCamera || showLibrary)
    }

    /// Hoja compacta, sin List: List y NavigationStack sin tamaño intrínseco
    /// expandían la selección de foto hasta ocupar toda la pantalla.
    private var scanSourceMenu: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Escanear pizarra") {
                CloseToolbarButton(action: {
                    scanTask?.cancel()
                    dismiss()
                }, large: true)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                Text("Escanea la pizarra de tu clase para añadir los ejercicios al entreno ya registrado. Después podrás revisar las series y las marcas.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                Divider().opacity(0.35).padding(.leading, 52)

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        guard checkScanPermission() else { return }
                        showCamera = true
                    } label: {
                        scanSourceRow("Tomar foto", symbol: "camera.fill", tint: OG.accent)
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.35).padding(.leading, 52)
                }

                Button {
                    guard checkScanPermission() else { return }
                    showLibrary = true
                } label: {
                    scanSourceRow("Elegir de la galería", symbol: "photo.on.rectangle", tint: OG.blue)
                }
                .buttonStyle(.plain)
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))

            if reading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Leyendo pizarra…").foregroundStyle(OG.label2)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)
            }
            if let failure {
                Text(failure)
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
        .toolbar(.hidden, for: .navigationBar)
    }

    private func scanSourceRow(_ title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
                .font(.body)
                // OG.label = negro en día, blanco en noche, igual que Inicio.
                .foregroundStyle(OG.label)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
