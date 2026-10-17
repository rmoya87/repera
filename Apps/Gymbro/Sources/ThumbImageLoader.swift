import Foundation
import GymbroDomain
import UIKit
import os

/// Bounded concurrent decode of exercise thumbs. Deduplicates in-flight loads and supports cancel.
actor ThumbImageLoader {
    static let shared = ThumbImageLoader()

    private let maxConcurrent = 4
    private var running = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private var memory: [String: UIImage] = [:]
    private var memoryOrder: [String] = []
    private let memoryLimit = 120
    private let logger = Logger(subsystem: "app.gymbroapp.ios", category: "ThumbLoader")

    /// Disk path / existence manifest built once (bundle probe is expensive).
    private var manifestBuilt = false
    private var existingNames: Set<String> = []

    func cached(key: String) -> UIImage? {
        memory[key]
    }

    func load(
        named name: String,
        maxPixel: Int,
        priority: TaskPriority = .utility
    ) async -> UIImage? {
        let key = "\(name)#\(maxPixel)"
        if let hit = memory[key] { return hit }
        if let existing = inFlight[key] {
            return await existing.value
        }
        let task = Task(priority: priority) { () -> UIImage? in
            await self.withPermit {
                await self.decode(named: name, maxPixel: maxPixel)
            }
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            insertMemory(image, key: key)
        }
        return image
    }

    /// Cancel outstanding loads that are no longer needed (best-effort).
    func cancelAllInFlight() {
        for (_, task) in inFlight {
            task.cancel()
        }
        inFlight.removeAll()
    }

    func prefetch(names: [String], maxPixel: Int) async {
        await withTaskGroup(of: Void.self) { group in
            for name in names {
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

    // MARK: - Private

    private func withPermit<T: Sendable>(_ work: @Sendable () async -> T) async -> T {
        if running >= maxConcurrent {
            await withCheckedContinuation { cont in
                waiters.append(cont)
            }
        }
        running += 1
        defer {
            running -= 1
            if !waiters.isEmpty {
                let next = waiters.removeFirst()
                next.resume()
            }
        }
        return await work()
    }

    private func decode(named name: String, maxPixel: Int) async -> UIImage? {
        if Task.isCancelled { return nil }
        return await Task.detached(priority: .utility) {
            Self.loadAndDownscale(named: name, maxPixel: maxPixel)
        }.value
    }

    private func insertMemory(_ image: UIImage, key: String) {
        if memory[key] == nil {
            memoryOrder.append(key)
        }
        memory[key] = image
        while memoryOrder.count > memoryLimit {
            let old = memoryOrder.removeFirst()
            memory.removeValue(forKey: old)
        }
    }

    nonisolated private static func loadAndDownscale(named name: String, maxPixel: Int) -> UIImage? {
        if let pre = loadUIImageFromDisk(named: name, subdirectory: "ExerciseArt/thumbs") {
            if max(pre.size.width * pre.scale, pre.size.height * pre.scale) <= CGFloat(maxPixel) + 1 {
                return pre
            }
            return downscale(pre, maxPixel: maxPixel)
        }
        guard let full = loadUIImageFromDisk(named: name, subdirectory: "ExerciseArt") else { return nil }
        return downscale(full, maxPixel: maxPixel)
    }

    nonisolated private static func loadUIImageFromDisk(
        named name: String,
        subdirectory: String
    ) -> UIImage? {
        if subdirectory == "ExerciseArt", let img = UIImage(named: name) { return img }
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.resourceURL?.appendingPathComponent("\(subdirectory)/\(name).jpg"),
            bundle.bundleURL.appendingPathComponent("\(subdirectory)/\(name).jpg"),
            bundle.url(forResource: name, withExtension: "jpg", subdirectory: subdirectory),
            subdirectory == "ExerciseArt" ? bundle.url(forResource: name, withExtension: "jpg") : nil,
        ]
        for url in candidates {
            guard let url, FileManager.default.fileExists(atPath: url.path),
                  let img = UIImage(contentsOfFile: url.path)
            else { continue }
            return img
        }
        return nil
    }

    nonisolated private static func downscale(_ image: UIImage, maxPixel: Int) -> UIImage? {
        let maxSide = max(image.size.width * image.scale, image.size.height * image.scale)
        guard maxSide > CGFloat(maxPixel) else { return image }
        let scale = CGFloat(maxPixel) / maxSide
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
