import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Cámara nativa (`UIImagePickerController`).
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            BoardScanLog.info("CameraPicker: cancel")
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let chosen = (info[.originalImage] as? UIImage) ?? (info[.editedImage] as? UIImage)
            BoardScanLog.info("CameraPicker: picked=\(chosen != nil)")
            if let chosen {
                BoardScanLog.image(chosen, step: "CameraPicker")
            }
            DispatchQueue.main.async {
                self.parent.image = chosen
                self.parent.dismiss()
            }
        }
    }
}

/// Galería moderna (`PHPicker`). Carga por Data (HEIC/JPEG) para no perder el bitmap.
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                BoardScanLog.info("PhotoLibraryPicker: empty selection")
                parent.dismiss()
                return
            }

            BoardScanLog.info("PhotoLibraryPicker: types=\(provider.registeredTypeIdentifiers.joined(separator: ","))")

            // NSItemProvider no es Sendable; es seguro usarlo para carga desde colas de Photos.
            nonisolated(unsafe) let itemProvider = provider
            Task { [weak self] in
                let image = await Self.loadImage(from: itemProvider)
                await MainActor.run {
                    guard let self else { return }
                    if let image {
                        BoardScanLog.image(image, step: "PhotoLibraryPicker")
                    } else {
                        BoardScanLog.error("PhotoLibraryPicker: no se pudo materializar UIImage")
                    }
                    self.parent.image = image
                    self.parent.dismiss()
                }
            }
        }

        /// Preferir bytes (HEIC/JPEG); si falla, `loadObject` de `UIImage`.
        private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
            // Los completion handlers de NSItemProvider son @Sendable; el tipo no lo es.
            nonisolated(unsafe) let itemProvider = provider

            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let data = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
                    itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                        if let error {
                            BoardScanLog.error("loadDataRepresentation: \(error.localizedDescription)")
                        }
                        continuation.resume(returning: data)
                    }
                }
                if let data, let image = UIImage(data: data) {
                    return image
                }
            }

            guard itemProvider.canLoadObject(ofClass: UIImage.self) else { return nil }

            return await withCheckedContinuation { continuation in
                _ = itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error {
                        BoardScanLog.error("loadObject: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }
    }
}
