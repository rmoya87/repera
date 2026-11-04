import Foundation
import UIKit

/// Descarga JPG públicos de Storage (`exercise-art`) a Application Support.
/// No escribe historial ni JSON personal; solo arte editorial.
actor RemoteExerciseArtCache {
    static let shared = RemoteExerciseArtCache()

    private let directory: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appendingPathComponent("Repera/ExerciseArtRemote", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()

    private var inFlight: Set<String> = []

    nonisolated static func localFileURL(for stem: String) -> URL {
        let safe = stem
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
        return FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        .appendingPathComponent("Repera/ExerciseArtRemote", isDirectory: true)
        .appendingPathComponent("\(safe).jpg")
    }

    nonisolated static func hasCachedFile(for stem: String) -> Bool {
        FileManager.default.fileExists(atPath: localFileURL(for: stem).path)
    }

    nonisolated private static func bundleContains(stem: String) -> Bool {
        if UIImage(named: stem) != nil { return true }
        let bundle = Bundle.main
        if bundle.url(forResource: stem, withExtension: "jpg", subdirectory: "ExerciseArt") != nil {
            return true
        }
        return bundle.url(forResource: stem, withExtension: "jpg") != nil
    }

    /// Prefetch stems publicados que no están en el binario ni en disco.
    func prefetch(stems: [String], supabaseURL: URL) async {
        let unique = Array(Set(stems.filter { !$0.isEmpty })).sorted()
        for stem in unique {
            if Self.bundleContains(stem: stem) { continue }
            if Self.hasCachedFile(for: stem) { continue }
            guard !inFlight.contains(stem) else { continue }
            inFlight.insert(stem)
            defer { inFlight.remove(stem) }
            await download(stem: stem, supabaseURL: supabaseURL)
        }
    }

    private func download(stem: String, supabaseURL: URL) async {
        let safe = stem
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
        guard safe == stem else { return }
        let url = supabaseURL
            .appendingPathComponent("storage/v1/object/public/exercise-art")
            .appendingPathComponent("\(stem).jpg")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  !data.isEmpty
            else { return }
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )
            let dest = directory.appendingPathComponent("\(stem).jpg")
            let temp = dest.appendingPathExtension("tmp")
            try data.write(to: temp, options: .atomic)
            _ = try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: temp, to: dest)
        } catch {
            // Silencioso: el binario / placeholder siguen disponibles.
        }
    }
}
