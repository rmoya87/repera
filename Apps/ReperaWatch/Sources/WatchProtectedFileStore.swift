import Foundation
import os

/// Estado offline y cola de entrenos del reloj: ficheros del contenedor con
/// protección de datos (`completeUntilFirstUserAuthentication`), no UserDefaults.
/// Debe seguir siendo legible con la pantalla bloqueada tras el primer desbloqueo
/// porque HealthKit puede terminar un entreno con el reloj en la muñeca bloqueado.
enum WatchProtectedFileStore {
    private static let logger = Logger(subsystem: "com.app.repera.watch", category: "Storage")

    static func directory(_ name: String = "State") -> URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return nil }
        var dir = base.appendingPathComponent("ReperaWatch", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            do {
                try fm.createDirectory(
                    at: dir, withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
                )
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try dir.setResourceValues(values)
            } catch {
                logger.error("Watch storage directory unavailable")
                return nil
            }
        }
        return dir
    }

    static func read(_ name: String) -> Data? {
        guard let url = directory()?.appendingPathComponent(name) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// `nil` borra el fichero.
    @discardableResult
    static func write(_ data: Data?, to name: String) -> Bool {
        guard let url = directory()?.appendingPathComponent(name) else { return false }
        guard let data else {
            try? FileManager.default.removeItem(at: url)
            return true
        }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            logger.error("Watch state write failed")
            return false
        }
    }

    /// Copia única desde la clave antigua de UserDefaults; la clave se borra
    /// solo cuando el fichero protegido se ha escrito correctamente.
    static func migrateDefaultsData(key: String, to name: String) {
        let defaults = UserDefaults.standard
        guard let legacy = defaults.data(forKey: key) else { return }
        if read(name) != nil || write(legacy, to: name) {
            defaults.removeObject(forKey: key)
        }
    }
}
