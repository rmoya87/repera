import Foundation

/// Rutas y prefetch de JPG públicos de Storage (`exercise-art`) → Application Support.
/// Enum (no actor de tipado) para que SourceKit/ExerciseArt resuelvan el símbolo con fiabilidad.
enum RemoteExerciseArtCache {
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

    static var shared: Prefetcher { Prefetcher.shared }

    /// Prefetch concurrente; no escribe historial ni JSON personal.
    actor Prefetcher {
        static let shared = Prefetcher()

        private let directory: URL = {
            let base = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0].appendingPathComponent("Repera/ExerciseArtRemote", isDirectory: true)
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            return base
        }()

        private var inFlight: Set<String> = []

        func prefetch(stems: [String], supabaseURL: URL) async {
            let unique = Array(Set(stems.filter { !$0.isEmpty })).sorted()
            for stem in unique {
                // Siempre preferir Supabase OTA: descargar aunque exista en el bundle
                // (el binario no debe bloquear miniaturas actualizadas en Storage).
                if RemoteExerciseArtCache.hasCachedFile(for: stem) { continue }
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
}
