import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import UIKit
import Vision

enum BoardTextRecognizer {
    private static let maxPixelLongSide: CGFloat = 1400
    private static let ocrTimeoutSeconds: TimeInterval = 20

    enum RecognizerError: LocalizedError {
        case invalidImage
        case noText
        case timeout

        var errorDescription: String? {
            switch self {
            case .invalidImage: "No se pudo preparar la imagen para leerla."
            case .noText: "No detecté texto en la imagen. Prueba con más luz o más cerca."
            case .timeout: "La lectura de la imagen tardó demasiado. Prueba otra foto más cercana."
            }
        }
    }

    /// Prepara JPEG reducido. Preferir ImageIO; si falla, UIGraphics en MainActor.
    @MainActor
    static func preparedJPEGDataOnMainIfNeeded(from image: UIImage) -> Data? {
        if let data = imageIOJPEG(from: image) {
            BoardScanLog.step("jpeg.path", "ImageIO")
            return data
        }
        BoardScanLog.step("jpeg.path", "UIGraphics fallback")
        return rasterizedJPEG(from: image)
    }

    static func recognize(jpegData: Data) async throws -> String {
        BoardScanLog.step("vision.group", "timeout=\(Int(Self.ocrTimeoutSeconds))s")
        do {
            // Un solo detached (sin TaskGroup anidado — en dispositivo dejaba el runtime raro).
            let text = try await Task.detached(priority: .userInitiated) {
                try Self.recognizeSync(jpegData: jpegData)
            }.value
            return text
        } catch let error as RecognizerError {
            BoardScanLog.error("vision: \(error.localizedDescription)")
            throw error
        } catch {
            BoardScanLog.error("vision: \(error.localizedDescription)")
            throw error
        }
    }

    private static func recognizeSync(jpegData: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(jpegData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw RecognizerError.invalidImage
        }
        BoardScanLog.step("vision.cg", "\(cgImage.width)x\(cgImage.height)")

        let t0 = CFAbsoluteTimeGetCurrent()
        let fast = try performRecognition(on: cgImage, level: .fast)
        let fastMs = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        let fastLines = fast.components(separatedBy: .newlines).filter { !$0.isEmpty }
        BoardScanLog.step("vision.fast", "\(fastMs)ms lines=\(fastLines.count) chars=\(fast.count)")
        // En pizarras multi-bloque, «fast» suele leer todas las líneas pero
        // confunde abreviaturas críticas (HSQ, RFT, lunges, 40/25).
        // Priorizar «accurate» solo ahí; mantener la ruta rápida en fotos simples.
        let complexBoard = isMultiBlockBoard(fastLines)
        if fastLines.count >= 3 && !complexBoard {
            return fast
        }
        let t1 = CFAbsoluteTimeGetCurrent()
        let accurate = (try? performRecognition(on: cgImage, level: .accurate)) ?? fast
        let accMs = Int((CFAbsoluteTimeGetCurrent() - t1) * 1000)
        BoardScanLog.step("vision.accurate", "\(accMs)ms chars=\(accurate.count) complex=\(complexBoard)")
        guard !accurate.isEmpty else { throw RecognizerError.noText }
        // Nunca seleccionar OCR por la longitud del texto: más caracteres ≠
        // mayor precisión. En pizarras multi-bloque prevalece Vision accurate.
        return complexBoard ? accurate : (accurate.count >= fast.count ? accurate : fast)
    }

    private static func isMultiBlockBoard(_ lines: [String]) -> Bool {
        let count = lines.reduce(0) { total, line in
            let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let header = normalized.hasPrefix("EMOM")
                || normalized.hasPrefix("AMRAP")
                || normalized.hasPrefix("EVERY ")
                || normalized.hasPrefix("CADA ")
                || normalized.hasPrefix("FOR TIME")
                || normalized.hasPrefix("RFT")
                || normalized.range(of: #"^\\d+\\s*RFT\\b"#, options: .regularExpression) != nil
            return total + (header ? 1 : 0)
        }
        return count >= 2
    }

    private static func performRecognition(
        on cgImage: CGImage,
        level: VNRequestTextRecognitionLevel
    ) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = level
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

    private static func imageIOJPEG(from image: UIImage) -> Data? {
        guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            return nil
        }
        return downscaleJPEGData(data)
    }

    private static func downscaleJPEGData(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelLongSide),
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return data
        }
        let mutable = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            mutable, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return data }
        CGImageDestinationAddImage(
            dest,
            thumb,
            [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary
        )
        guard CGImageDestinationFinalize(dest) else { return data }
        return mutable as Data
    }

    @MainActor
    private static func rasterizedJPEG(from image: UIImage) -> Data? {
        let scale = max(image.scale, 1)
        var width = max(1, image.size.width * scale)
        var height = max(1, image.size.height * scale)
        if let cg = image.cgImage {
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
        let dark = dominantIsDark(image)
        let fill = dark ? UIColor.black : UIColor.white
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        let rendered = renderer.image { ctx in
            fill.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvas))
            image.draw(in: CGRect(origin: .zero, size: canvas))
        }
        return rendered.jpegData(compressionQuality: 0.85)
    }

    @MainActor
    private static func dominantIsDark(_ image: UIImage) -> Bool {
        let sample = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: sample, format: format)
        let tiny = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: sample))
        }
        guard let cg = tiny.cgImage,
              let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data)
        else { return true }
        let bpp = max(cg.bitsPerPixel / 8, 1)
        let total = cg.width * cg.height
        var sum: Double = 0
        for i in 0..<total {
            let o = i * bpp
            let r = Double(ptr[o])
            let g = Double(ptr[min(o + 1, CFDataGetLength(data) - 1)])
            let b = Double(ptr[min(o + 2, CFDataGetLength(data) - 1)])
            sum += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        }
        return (sum / Double(max(total, 1))) < 0.45
    }
}
