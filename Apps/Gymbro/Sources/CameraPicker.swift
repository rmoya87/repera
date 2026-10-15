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

            let finish: (UIImage?) -> Void = { image in
                DispatchQueue.main.async {
                    if let image {
                        BoardScanLog.image(image, step: "PhotoLibraryPicker")
                    } else {
                        BoardScanLog.error("PhotoLibraryPicker: no se pudo materializar UIImage")
                    }
                    self.parent.image = image
                    self.parent.dismiss()
                }
            }

            // Preferir bytes (más fiable con HEIC que loadObject).
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let error {
                        BoardScanLog.error("loadDataRepresentation: \(error.localizedDescription)")
                    }
                    if let data, let image = UIImage(data: data) {
                        finish(image)
                        return
                    }
                    // Fallback UIImage
                    if provider.canLoadObject(ofClass: UIImage.self) {
                        provider.loadObject(ofClass: UIImage.self) { object, err in
                            if let err {
                                BoardScanLog.error("loadObject: \(err.localizedDescription)")
                            }
                            finish(object as? UIImage)
                        }
                    } else {
                        finish(nil)
                    }
                }
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error {
                        BoardScanLog.error("loadObject: \(error.localizedDescription)")
                    }
                    finish(object as? UIImage)
                }
                return
            }

            finish(nil)
        }
    }
}
