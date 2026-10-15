import PhotosUI
import SwiftUI
import UIKit

enum ProfileAvatar {
    static func uiImage(from jpeg: Data?) -> UIImage? {
        guard let jpeg else { return nil }
        return UIImage(data: jpeg)
    }

    /// Compacta a JPEG ~256 px para no hinchar el JSON de iCloud.
    static func jpegData(from image: UIImage, maxSide: CGFloat = 256) -> Data? {
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}

struct ProfilePhotoPickerLabel: View {
    var hasPhoto: Bool

    var body: some View {
        Label(
            hasPhoto ? "Cambiar foto de perfil" : "Elegir foto de perfil",
            systemImage: "person.crop.circle.badge.plus"
        )
    }
}
