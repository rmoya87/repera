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
        picker.sourceType = .camera
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
            Task { @MainActor in
                parent.dismiss()
            }
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
            Task { @MainActor in
                parent.image = chosen
                parent.dismiss()
            }
        }
    }
}

/// Galería nativa (`PHPickerViewController`) en fullScreenCover — no usa
/// `.photosPicker`, que redimensiona mal los sheets fitted al cerrar.
struct LibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LibraryPicker
        init(_ parent: LibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                BoardScanLog.info("LibraryPicker: cancel")
                Task { @MainActor in parent.dismiss() }
                return
            }
            BoardScanLog.step("photos.load", "PHPicker start")
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error {
                        BoardScanLog.error("LibraryPicker: \(error.localizedDescription)")
                    }
                    let image = object as? UIImage
                    if let image {
                        BoardScanLog.image(image, step: "photos.ready")
                    } else {
                        BoardScanLog.error("LibraryPicker: sin UIImage")
                    }
                    Task { @MainActor in
                        self.parent.image = image
                        self.parent.dismiss()
                    }
                }
            } else {
                BoardScanLog.error("LibraryPicker: provider no soporta UIImage")
                Task { @MainActor in parent.dismiss() }
            }
        }
    }
}
