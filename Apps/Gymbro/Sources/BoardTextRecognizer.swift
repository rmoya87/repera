import UIKit
import Vision

enum BoardTextRecognizer {
    private static let maxPixelLongSide: CGFloat = 2400

    static func recognize(in image: UIImage) async throws -> String {
        BoardScanLog.image(image, step: "recognize.input")
        let cgImage = try normalizedCGImage(from: image)
        BoardScanLog.info("recognize.normalized: \(cgImage.width)x\(cgImage.height)")
        return try await Task.detached(priority: .userInitiated) {
            try Self.performRecognition(on: cgImage)
        }.value
    }

    enum RecognizerError: LocalizedError {
        case invalidImage
        case noText

        var errorDescription: String? {
            switch self {
            case .invalidImage: "No se pudo preparar la imagen para leerla."
            case .noText: "No detecté texto en la imagen. Prueba con más luz o más cerca."
            }
        }
    }

    private static func performRecognition(on cgImage: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.008
        if let langs = try? request.supportedRecognitionLanguages(), !langs.isEmpty {
            let preferred = ["es-ES", "en-US"].filter { langs.contains($0) }
            if !preferred.isEmpty {
                request.recognitionLanguages = preferred
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        let observations = (request.results) ?? []
        let sorted = observations.sorted { a, b in
            let ay = 1 - a.boundingBox.midY
            let by = 1 - b.boundingBox.midY
            if abs(ay - by) > 0.015 { return ay < by }
            return a.boundingBox.minX < b.boundingBox.minX
        }
        let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let text = lines.joined(separator: "\n")
        guard !text.isEmpty else { throw RecognizerError.noText }
        return text
    }

    /// Rasteriza siempre a un CGImage vertical (`.up`).
    private static func normalizedCGImage(from image: UIImage) throws -> CGImage {
        // Preferir tamaño en puntos orientados (UIKit ya contempla EXIF en `size`).
        let scale = max(image.scale, 1)
        var width = max(1, image.size.width * scale)
        var height = max(1, image.size.height * scale)

        // Si hay cgImage y la orientación no rota, usar píxeles reales.
        if let cg = image.cgImage, image.imageOrientation == .up || image.imageOrientation == .upMirrored {
            width = CGFloat(cg.width)
            height = CGFloat(cg.height)
        }

        let longSide = max(width, height)
        let shrink = longSide > maxPixelLongSide ? (maxPixelLongSide / longSide) : 1
        let canvas = CGSize(
            width: max(1, floor(width * shrink)),
            height: max(1, floor(height * shrink))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let rendered = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvas))
            image.draw(in: CGRect(origin: .zero, size: canvas))
        }

        if let cg = rendered.cgImage {
            return cg
        }
        throw RecognizerError.invalidImage
    }
}
