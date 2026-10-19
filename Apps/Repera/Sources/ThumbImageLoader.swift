import Foundation
import ImageIO
import UIKit
import os

/// Process-wide thumb memory. Safe to read from MainActor without hopping into the loader actor.
final class ThumbMemoryCache: @unchecked Sendable {
    static let shared = ThumbMemoryCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 160
        // ~48×48@3x RGBA ≈ 27KB; budget ~40MB of decoded thumbs.
        cache.totalCostLimit = 40 * 1024 * 1024
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String, pixel: Int) {
        let cost = max(1, pixel * pixel * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}

/// Bounded concurrent decode of exercise thumbs. Sliding-window prefetch (no hundreds of waiters).
actor ThumbImageLoader {
    static let shared = ThumbImageLoader()

    private let maxConcurrent = 4
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let memory = ThumbMemoryCache.shared
    private let logger = Logger(subsystem: "com.app.repera", category: "ThumbLoader")

    private var manifestBuilt = false
    private var existingNames: Set<String> = []

    func cached(key: String) -> UIImage? {
        memory.image(for: key)
    }

    func load(
        named name: String,
        maxPixel: Int,
        priority: TaskPriority = .utility
    ) async -> UIImage? {
        let key = "\(name)#\(maxPixel)"
        if let hit = memory.image(for: key) { return hit }
        if Task.isCancelled { return nil }
        // Manifiesto: evita abrir ImageIO para nombres que no existen.
        if manifestBuilt, !existingNames.contains(name) {
            return nil
        }
        if let existing = inFlight[key] {
            return await existing.value
        }
        let task = Task(priority: priority) { () -> UIImage? in
            if Task.isCancelled { return nil }
            let image = Self.decodeWithImageIO(named: name, maxPixel: maxPixel)
            if Task.isCancelled { return nil }
            return image
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if Task.isCancelled { return nil }
        if let image {
            memory.store(image, for: key, pixel: maxPixel)
        }
        return image
    }

    func cancelAllInFlight() {
        for (_, task) in inFlight {
            task.cancel()
        }
        inFlight.removeAll()
    }

    /// Prefetch with a sliding window of at most `maxConcurrent` tasks — no N suspended waiters.
    func prefetch(names: [String], maxPixel: Int) async {
        let pending = names.filter { memory.image(for: "\($0)#\(maxPixel)") == nil }
        guard !pending.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            var next = 0
            let total = pending.count
            let initial = min(maxConcurrent, total)
            for _ in 0..<initial {
                let name = pending[next]
                next += 1
                group.addTask {
                    _ = await self.load(named: name, maxPixel: maxPixel)
                }
            }
            while await group.next() != nil {
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                guard next < total else { continue }
                let name = pending[next]
                next += 1
                group.addTask {
                    _ = await self.load(named: name, maxPixel: maxPixel)
                }
            }
        }
    }

    func ensureManifest() -> Set<String> {
        guard !manifestBuilt else { return existingNames }
        manifestBuilt = true
        let bundle = Bundle.main
        var found = Set<String>()
        let dirs = [
            bundle.resourceURL?.appendingPathComponent("ExerciseArt/thumbs", isDirectory: true),
            bundle.resourceURL?.appendingPathComponent("ExerciseArt", isDirectory: true),
        ].compactMap { $0 }
        for dir in dirs {
            guard let items = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            ) else { continue }
            for url in items where url.pathExtension.lowercased() == "jpg" {
                found.insert(url.deletingPathExtension().lastPathComponent)
            }
        }
        existingNames = found
        logger.info("ExerciseArt manifest entries=\(found.count, privacy: .public)")
        return existingNames
    }

    func manifestContains(_ name: String) -> Bool {
        ensureManifest().contains(name)
    }

    func snapshotManifest() -> Set<String> {
        ensureManifest()
    }

    // MARK: - ImageIO

    nonisolated private static func decodeWithImageIO(named name: String, maxPixel: Int) -> UIImage? {
        if Task.isCancelled { return nil }
        let urls = candidateURLs(named: name)
        for url in urls {
            if Task.isCancelled { return nil }
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { continue }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
            ]
            guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                continue
            }
            return UIImage(cgImage: cg, scale: 1, orientation: .up)
        }
        return nil
    }

    /// Sin `fileExists` en hot path — Bundle URL + ImageIO fallan barato si no hay archivo.
    nonisolated private static func candidateURLs(named name: String) -> [URL] {
        let bundle = Bundle.main
        if let thumbs = bundle.url(forResource: name, withExtension: "jpg", subdirectory: "ExerciseArt/thumbs") {
            return [thumbs]
        }
        if let full = bundle.url(forResource: name, withExtension: "jpg", subdirectory: "ExerciseArt") {
            return [full]
        }
        return [
            bundle.resourceURL?.appendingPathComponent("ExerciseArt/thumbs/\(name).jpg"),
            bundle.resourceURL?.appendingPathComponent("ExerciseArt/\(name).jpg"),
            bundle.bundleURL.appendingPathComponent("ExerciseArt/thumbs/\(name).jpg"),
            bundle.bundleURL.appendingPathComponent("ExerciseArt/\(name).jpg"),
        ].compactMap { $0 }
    }
}
