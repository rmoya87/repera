import UniformTypeIdentifiers
import UIKit

/// System share sheet entry. Copies GPX / board photos into the App Group inbox,
/// then opens Repera. Never runs OCR, GPS or HealthKit in the extension process.
final class ShareViewController: UIViewController {
    private var didEnqueue = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .systemBackground
        Task { await ingest() }
    }

    private func ingest() async {
        guard !didEnqueue else { return }
        didEnqueue = true
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            await MainActor.run { extensionContext?.completeRequest(returningItems: nil) }
            return
        }
        for item in items {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if await enqueue(provider: provider) { break }
            }
        }
        await MainActor.run {
            openHostApp()
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func enqueue(provider: NSItemProvider) async -> Bool {
        let candidates: [(String, ReperaShareInbox.Kind)] = [
            ("com.topografixix.gpx", .gpx),
            (UTType.xml.identifier, .gpx),
            (UTType.data.identifier, .gpx),
            (UTType.image.identifier, .boardImage),
            (UTType.jpeg.identifier, .boardImage),
            (UTType.png.identifier, .boardImage),
            (UTType.heic.identifier, .boardImage)
        ]
        for (typeID, forcedKind) in candidates where provider.hasItemConformingToTypeIdentifier(typeID) {
            do {
                let data = try await loadData(provider: provider, typeIdentifier: typeID)
                let name = suggestedName(provider: provider, fallbackType: typeID, kind: forcedKind)
                let kind = ReperaShareInbox.kind(for: typeID, fileName: name) ?? forcedKind
                if kind == .gpx, !name.lowercased().hasSuffix(".gpx"), typeID == UTType.data.identifier {
                    continue
                }
                _ = try ReperaShareInbox.enqueue(data: data, kind: kind, fileName: name)
                return true
            } catch {
                continue
            }
        }
        return false
    }

    private func loadData(provider: NSItemProvider, typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "ReperaShare", code: 2))
                }
            }
        }
    }

    private func suggestedName(
        provider: NSItemProvider,
        fallbackType: String,
        kind: ReperaShareInbox.Kind
    ) -> String {
        if let name = provider.suggestedName, !name.isEmpty { return name }
        switch kind {
        case .gpx: return "import.gpx"
        case .boardImage:
            if fallbackType.contains("png") { return "board.png" }
            if fallbackType.contains("heic") { return "board.heic" }
            return "board.jpg"
        }
    }

    private func openHostApp() {
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selector) {
                _ = current.perform(selector, with: ReperaShareInbox.openAppURL as NSURL)
                return
            }
            responder = current.next
        }
    }
}
