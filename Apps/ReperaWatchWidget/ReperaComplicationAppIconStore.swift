import Foundation
import UIKit

/// Mismo patrón que Cafesito `WatchComplicationAppIconStore`:
/// PNG suelto en el .appex + imageset, sin GeometryReader.
enum ReperaComplicationAppIconStore {
    static let assetCatalogImageName = "ReperaComplicationIcon"

    private static let looseResourceNames = ["ReperaWatchAppIcon", "repera_complication"]
    private static let assetCatalogNames = ["ReperaComplicationIcon", "ReperaIcon"]

    static func loadUIImage(bundle: Bundle = .main) -> UIImage? {
        loadFromBundle(bundle: bundle)
    }

    /// Asegura que el PNG está resoluble antes de pedir timelines a Chrono.
    @discardableResult
    static func seedFromBundleIfNeeded(bundle: Bundle = .main) -> Bool {
        loadFromBundle(bundle: bundle) != nil
    }

    private static func loadFromBundle(bundle: Bundle) -> UIImage? {
        // watchOS: UIImage(named:in:compatibleWith:) no está disponible.
        for name in assetCatalogNames {
            if let image = UIImage(named: name) {
                return image
            }
        }
        for name in looseResourceNames {
            if let path = bundle.path(forResource: name, ofType: "png"),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}
