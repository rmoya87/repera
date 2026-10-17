import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Cámara nativa (`UIImagePickerController`). Galería: `PhotosPicker` en el caller.
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

/// Materializa `UIImage` desde `PhotosPicker` (bytes HEIC/JPEG antes que decode genérico).
enum BoardScanPhotoLoader {
    @MainActor
    static func loadUIImage(from item: PhotosPickerItem) async -> UIImage? {
        BoardScanLog.info("PhotosPicker: load start")
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            BoardScanLog.image(image, step: "PhotosPicker")
            return image
        }
        BoardScanLog.error("PhotosPicker: no se pudo materializar UIImage")
        return nil
    }
}
