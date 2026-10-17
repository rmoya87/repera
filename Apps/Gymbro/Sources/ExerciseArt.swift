import GymbroDomain
import SwiftUI
import UIKit

/// Ilustraciones originales Gymbro (hero + pasos `_1`, `_2`… para carrusel).
enum ExerciseArt {
    /// Nombre del hero para listas (sin sondear pasos `_1`…`_8`).
    static func imageName(for exercise: Exercise) -> String? {
        heroImageName(for: exercise)
    }

    static func imageName(forExerciseName name: String, muscleGroup: String) -> String? {
        // No reutilizar por músculo ni mostrar héroes visualmente incorrectos.
        guard let base = nameMap[name], !quarantinedHeroes.contains(base) else { return nil }
        return base
    }

    /// Solo cache hit (nunca decodifica). Usar en `body` para no bloquear el buscador.
    static func cachedThumb(for exercise: Exercise, pointSize: CGFloat = 48) -> UIImage? {
        guard let name = heroImageName(for: exercise) else { return nil }
        let pixel = max(1, Int((pointSize * 3).rounded()))
        return lookup.thumb(for: "\(name)#\(pixel)")
    }

    /// Decode + downscale fuera del main actor (concurrencia acotada + dedupe).
    static func loadThumb(for exercise: Exercise, pointSize: CGFloat = 48) async -> UIImage? {
        if let hit = cachedThumb(for: exercise, pointSize: pointSize) { return hit }
        guard let name = heroImageName(for: exercise) else { return nil }
        let pixel = max(1, Int((pointSize * 3).rounded()))
        let cacheKey = "\(name)#\(pixel)"
        if let hit = await ThumbImageLoader.shared.cached(key: cacheKey) {
            lookup.setThumb(hit, for: cacheKey)
            return hit
        }
        let t0 = CFAbsoluteTimeGetCurrent()
        let loaded = await ThumbImageLoader.shared.load(named: name, maxPixel: pixel)
        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        if ms > 8 {
            LibrarySearchLog.thumbMiss(name: name, ms: ms)
        }
        guard let loaded else { return nil }
        lookup.setThumb(loaded, for: cacheKey)
        return loaded
    }

    /// Precarga con límite de concurrencia. Llamar tras bootstrap / al abrir Ejercicios.
    static func prefetchThumbs(for exercises: [Exercise], pointSize: CGFloat = 48) {
        Task(priority: .utility) {
            let t0 = CFAbsoluteTimeGetCurrent()
            let pixel = max(1, Int((pointSize * 3).rounded()))
            let manifest = await ThumbImageLoader.shared.ensureManifest()
            lookup.installManifest(manifest)
            let names = Array(Set(exercises.compactMap { heroImageName(for: $0) }))
            await ThumbImageLoader.shared.prefetch(names: names, maxPixel: pixel)
            for exercise in exercises {
                _ = await loadThumb(for: exercise, pointSize: pointSize)
            }
            LibrarySearchLog.prefetch(
                count: exercises.count,
                ms: (CFAbsoluteTimeGetCurrent() - t0) * 1000
            )
        }
    }

    /// Warm JPG existence set so carousel probing avoids missing-file I/O.
    static func warmArtManifest() {
        Task(priority: .utility) {
            let manifest = await ThumbImageLoader.shared.ensureManifest()
            lookup.installManifest(manifest)
        }
    }

    nonisolated private static func loadAndDownscale(named name: String, maxPixel: Int) -> UIImage? {
        // Preferir JPG pregenerado en `ExerciseArt/thumbs/` (192px) → carga de lista rápida.
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
        subdirectory: String = "ExerciseArt"
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

    /// Pasos numerados si existen (`base_1`…); si no, secuencia de movimientos distintos; si no, hero.
    /// Solo para ficha / carrusel — no usar en filas de lista.
    static func imageNames(for exercise: Exercise) -> [String] {
        let cacheKey = exercise.name
        if let cached = lookup.names(for: cacheKey) { return cached }

        guard let base = imageName(forExerciseName: exercise.name, muscleGroup: exercise.muscleGroup) else {
            lookup.setNames([], for: cacheKey)
            return []
        }
        var numbered: [String] = []
        if !staticHoldExercises.contains(exercise.name),
           !quarantinedSequences.contains(base) {
            for i in 1...8 {
                let step = "\(base)_\(i)"
                if let known = lookup.manifestHas(step), !known { break }
                guard uiImage(named: step) != nil else { break }
                numbered.append(step)
            }
        }
        var resolved: [String]
        if numbered.count >= 2 {
            resolved = numbered
        } else if !staticHoldExercises.contains(exercise.name),
                  verifiedMovementFrameExercises.contains(exercise.name),
                  let frames = movementFrames[exercise.name] {
            var seen = Set<String>()
            let unique = frames.filter { name in
                guard uiImage(named: name) != nil else { return false }
                return seen.insert(name).inserted
            }
            if unique.count >= 2 {
                resolved = unique
            } else if uiImage(named: base) != nil {
                resolved = [base]
            } else if let first = numbered.first {
                resolved = [first]
            } else {
                resolved = []
            }
        } else if uiImage(named: base) != nil {
            resolved = [base]
        } else if let first = numbered.first {
            resolved = [first]
        } else {
            resolved = []
        }
        // Impedir subtítulos desplazados o repetidos si un seed cambia sus instrucciones.
        let captions = CatalogSpanish.instructions(forName: exercise.name) ?? exercise.instructions
        let captionCount = captions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        if resolved.count >= 2 && captionCount != resolved.count {
            resolved = uiImage(named: base) == nil ? [] : [base]
        }
        lookup.setNames(resolved, for: cacheKey)
        return resolved
    }

    /// Hero: solo mapa de nombres (sin FileManager / decode). Si el JPG falta, el thumb muestra SF Symbol.
    private static func heroImageName(for exercise: Exercise) -> String? {
        let key = exercise.name
        if let cached = lookup.heroName(for: key) {
            return cached.isEmpty ? nil : cached
        }
        let base = imageName(forExerciseName: exercise.name, muscleGroup: exercise.muscleGroup) ?? ""
        lookup.setHeroName(base, for: key)
        return base.isEmpty ? nil : base
    }

    nonisolated private static func downscale(_ image: UIImage, maxPixel: Int) -> UIImage {
        let w = image.size.width * image.scale
        let h = image.size.height * image.scale
        let longest = max(w, h)
        guard longest > CGFloat(maxPixel), longest > 0 else { return image }
        let ratio = CGFloat(maxPixel) / longest
        let size = CGSize(width: max(1, (w * ratio).rounded()), height: max(1, (h * ratio).rounded()))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Estos héroes incumplen el movimiento/equipo/estilo; mostrar MuscleImpactDiagram.
    /// Solo retirarlos tras regenerar full y thumb con verificación visual.
    private static let quarantinedHeroes: Set<String> = [
    ]

    /// Holds no dinámicos: una sola ilustración, aunque aparezcan pasos por error.
    private static let staticHoldExercises: Set<String> = [
        "Hollow hold", "Arch hold", "Handstand hold", "L-sit", "V-sit",
        "Front lever tuck", "Back lever tuck", "Planche tuck",
        "False grip hang", "German hang", "Soporte en anillas",
    ]

    /// Secuencias que se han revisado visualmente y fallan el criterio de producto.
    /// Se mantiene el hero hasta regenerar y exportar TODOS sus frames defectuosos.
    private static let quarantinedSequences: Set<String> = [
    ]

    /// Candidatos movementFrames siguen documentados abajo, pero ninguno ha
    /// superado todavía la auditoría de continuidad de equipo/persona/cámara.
    /// Añadir aquí SOLO ejercicios validados visualmente, nunca por nombre.
    private static let verifiedMovementFrameExercises: Set<String> = []

    /// Secuencias de fotogramas distintos (mismo estilo) cuando no hay `base_1/_2/_3`.
    /// Holds estáticos no van aquí. Preferir pasos propios `_1…N` cuando existan.
    private static let movementFrames: [String: [String]] = [
        // MARK: Halterofilia — arrancada / cargada / envión
        "Arrancada muscular": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_hl_muscle_snatch"],
        "Balance de arrancada": ["art_hl_snatch_bal", "art_cf_ohs", "art_hl_sots"],
        "Arrancada": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_cf_arrancada"],
        "Arrancada de potencia": ["art_hl_snatch_pull", "art_cf_power_snatch", "art_hl_tall_snatch"],
        "Arrancada colgante": ["art_hl_hang_snatch", "art_hl_snatch_pull", "art_hl_tall_snatch"],
        "Arrancada colgante completa": ["art_hl_hang_sq_snatch", "art_cf_ohs", "art_hl_sots"],
        "Hang power snatch": ["art_hl_hang_snatch", "art_hl_snatch_pull", "art_cf_hps"],
        "Arrancada desde bloques": ["art_hl_block_snatch", "art_hl_snatch_pull", "art_cf_power_snatch"],
        "Arrancada con pausa": ["art_hl_pause_snatch", "art_hl_snatch_pull", "art_cf_arrancada"],
        "Drop snatch": ["art_hl_drop_snatch", "art_cf_ohs", "art_hl_sots"],
        "Tall snatch": ["art_hl_tall_snatch", "art_cf_ohs", "art_hl_sots"],
        "Arrancada en split": ["art_hl_snatch_pull", "art_hl_split_snatch", "art_hl_tall_snatch"],
        "Tirón de arrancada": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_hl_tall_snatch"],
        "Peso muerto agarre arrancada": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_peso_muerto"],
        "Cargada muscular": ["art_hl_clean_pull", "art_hl_muscle_clean", "art_hl_tall_clean"],
        "Cargada": ["art_hl_clean_pull", "art_cf_cargada", "art_hl_tall_clean"],
        "Cargada de potencia": ["art_hl_clean_pull", "art_cf_power_clean", "art_hl_tall_clean"],
        // Preferir art_cf_hang_clean_1…3 (hang → extensión → rack) si existen
        "Cargada colgante": ["art_cf_hang_clean_1", "art_cf_hang_clean_2", "art_cf_hang_clean_3"],
        "Cargada colgante completa": ["art_hl_hang_sq_clean", "art_cf_hang_clean_2", "art_cf_hang_clean_3"],
        "Hang power clean": ["art_cf_hang_clean_1", "art_cf_hang_clean_2", "art_cf_hang_clean_3"],
        "Cargada desde bloques": ["art_hl_block_clean", "art_hl_clean_pull", "art_cf_power_clean"],
        "Cargada con pausa": ["art_hl_pause_clean", "art_hl_clean_pull", "art_cf_cargada"],
        "Tall clean": ["art_hl_tall_clean", "art_hl_muscle_clean", "art_sentadilla_frontal"],
        "Tirón de cargada": ["art_peso_muerto", "art_hl_clean_pull", "art_cf_power_clean"],
        "Cargada y press": ["art_cf_cargada", "art_hl_clean_press", "art_cf_strict_press"],
        "Cargada y envión": ["art_cf_cargada", "art_cf_push_jerk", "art_cf_cj"],
        "Balance de envión": ["art_hl_jerk_bal", "art_hl_power_jerk", "art_cf_split_jerk"],
        "Power jerk": ["art_hl_jerk_bal", "art_hl_power_jerk", "art_cf_push_jerk"],
        "Push jerk": ["art_cf_push_press", "art_cf_push_jerk", "art_hl_power_jerk"],
        "Split jerk": ["art_cf_push_press", "art_cf_split_jerk", "art_hl_btn_jerk"],
        "Push press": ["art_cf_strict_press", "art_cf_push_press", "art_hl_power_jerk"],
        "Strict press": ["art_press_militar", "art_cf_strict_press", "art_hl_btn_press"],
        "Press detrás de nuca": ["art_hl_btn_press", "art_cf_strict_press", "art_press_militar"],
        "Envión detrás de nuca": ["art_hl_btn_press", "art_hl_btn_jerk", "art_cf_split_jerk"],
        "Sots press": ["art_hl_sots", "art_cf_ohs", "art_hl_pause_fs"],
        "Overhead squat": ["art_cf_ohs", "art_hl_sots", "art_sentadilla_frontal"],
        "Front rack lunge": ["art_sentadilla_frontal", "art_cf_fr_lunge", "art_zancadas"],
        "Sentadilla frontal con pausa": ["art_sentadilla_frontal", "art_hl_pause_fs", "art_cf_ohs"],
        "Sumo high pull": ["art_sumo", "art_cf_sumo_hp", "art_remo_menton"],

        // MARK: CrossFit / skill — frames reutilizados (hasta pasos propios)
        "Thruster": ["art_sentadilla_frontal", "art_cf_thruster", "art_cf_push_press"],
        "Thruster mancuernas": ["art_press_mancuernas", "art_cf_thruster_db", "art_press_militar"],
        "Thruster kettlebell": ["art_cf_goblet", "art_cf_thruster_kb", "art_cf_kb_amer"],
        "Cluster": ["art_cf_cargada", "art_cf_cluster", "art_cf_thruster"],
        "Ground to overhead": ["art_peso_muerto", "art_cf_gto", "art_cf_push_press"],
        "Wall ball": ["art_cf_goblet", "art_cf_wall_ball", "art_cf_slam"],
        "Swing kettlebell": ["art_cf_kb_swing", "art_cf_kb_amer", "art_cf_kb_snatch"],
        "Swing americano": ["art_cf_kb_swing", "art_cf_kb_amer", "art_cf_kb_snatch"],
        "Snatch kettlebell": ["art_cf_kb_swing", "art_cf_kb_snatch", "art_cf_kb_amer"],
        "Clean kettlebell": ["art_cf_kb_swing", "art_cf_kb_clean", "art_cf_goblet"],
        "Clean mancuerna": ["art_cf_db_clean", "art_press_mancuernas", "art_cf_thruster_db"],
        "Snatch mancuerna": ["art_cf_db_snatch", "art_cf_db_clean", "art_press_militar"],
        "Turkish get-up": ["art_cf_tgu", "art_cf_kb_amer", "art_press_militar"],
        "Devil press": ["art_cf_devil", "art_cf_db_snatch", "art_cf_burpee"],
        "Burpee pull-up": ["art_cf_burpee", "art_cf_burpee_pu", "art_dominadas"],
        "Burpee al cajón": ["art_cf_burpee", "art_cf_burpee_box", "art_cf_box_jump"],
        "Salto al cajón": ["art_gy_air_squat", "art_cf_box_jump", "art_gy_jump_squat"],
        "Step-up al cajón": ["art_zancadas", "art_cf_step_up", "art_gy_air_squat"],
        // Fallback si faltan art_cf_bjo_1…N (última NO debe ser broad jump)
        "Box jump over": ["art_cf_box_jump_1", "art_cf_bjo", "art_cf_bjo_3"],
        "Medball clean": ["art_cf_mb_clean", "art_cf_wall_ball", "art_cf_slam"],
        "Sandbag clean": ["art_cf_sb_clean", "art_cf_sb_os", "art_cf_cargada"],
        "Man maker": ["art_remo_mancuerna", "art_cf_manmaker", "art_press_mancuernas"],

        // MARK: Gimnasia dinámica — interim hasta pasos propios `_1…N`
        "Muscle-up barra": ["art_gy_strict_pu", "art_cf_mu_bar", "art_gy_pb_dip"],
        "Muscle-up anillas": ["art_gy_ring_pu", "art_cf_mu_rings", "art_cf_ring_dip"],
        "Muscle-up estricto barra": ["art_gy_strict_pu", "art_gy_strict_mubar", "art_gy_pb_dip"],
        "Muscle-up estricto anillas": ["art_gy_ring_pu", "art_gy_strict_muring", "art_cf_ring_dip"],
        "Toes to bar": ["art_gy_strict_pu", "art_cf_kte", "art_cf_ttb"],
        "Toes to bar estrictos": ["art_gy_strict_pu", "art_cf_kte", "art_gy_strict_ttb"],
        "Knees to elbows": ["art_gy_strict_pu", "art_cf_kte", "art_cf_ttb"],
        "Hip to bar": ["art_gy_strict_pu", "art_gy_htb", "art_cf_ttb"],
        // Fallback: hang → chin → pecho a barra (art_cf_ctb_1…3 propios)
        "Chest to bar": ["art_cf_ctb_1", "art_cf_ctb_2", "art_cf_ctb_3"],
        "Dominadas estrictas": ["art_gy_strict_pu", "art_dominadas", "art_cf_ctb"],
        "Dominadas kipping": ["art_gy_kip_swing", "art_gy_kip_pu", "art_dominadas"],
        "Dominadas butterfly": ["art_gy_kip_swing", "art_gy_bfly_pu", "art_dominadas"],
        "Dominadas supinas": ["art_gy_chinup", "art_dominadas", "art_cf_ctb"],
        "Dominadas en anillas": ["art_gy_ring_pu", "art_gy_ring_row", "art_cf_ring_dip"],
        "HSPU": ["art_gy_pike_pu", "art_cf_hspu", "art_gy_hs_hold"],
        "HSPU deficit": ["art_gy_pike_pu", "art_gy_hspu_def", "art_gy_hs_hold"],
        "HSPU libre": ["art_gy_hs_hold", "art_gy_hspu_free", "art_gy_press_hs"],
        "Pike push-up": ["art_gy_pike_pu", "art_cf_hspu", "art_gy_hs_hold"],
        "Wall walk": ["art_gy_pike_pu", "art_cf_wall_walk", "art_gy_hs_hold"],
        "Press to handstand": ["art_gy_press_hs", "art_gy_pike_pu", "art_gy_hs_hold"],
        "Handstand walk": ["art_gy_hs_hold", "art_cf_hsw", "art_cf_wall_walk"],
        "Pull-over barra": ["art_gy_strict_pu", "art_gy_pullover", "art_gy_pb_dip"],
        // Skin the cat: sin _2/_3 propios (fallaban); hang → base → back-lever tuck. Sin sombra en cuelgue.
        "Skin the cat": ["art_gy_skin_cat_1", "art_gy_skin_cat", "art_gy_back_lev"],
        // Kip: sin _1…N propios para no pisar arch → kip → hollow (pasos numerados malos override).
        "Kip swing": ["art_gy_arch", "art_gy_kip_swing", "art_gy_hollow_hold"],
        "Fondos en paralelas": ["art_gy_pb_dip", "art_fondos", "art_cf_ring_dip"],
        // Fallback: soporte → bottom → lockout (nunca art_fondos = paralelas)
        "Fondos en anillas": ["art_gy_ring_sup", "art_cf_ring_dip_2", "art_cf_ring_dip"],
        "Rope climb": ["art_cf_rope", "art_gy_rope_ll", "art_gy_strict_pu"],
        "Rope climb legless": ["art_gy_rope_ll", "art_cf_rope", "art_gy_strict_pu"],
        "Pistol squat": ["art_gy_air_squat", "art_cf_pistol", "art_gy_shrimp"],
        "Air squat": ["art_gy_air_squat", "art_sentadilla", "art_gy_jump_squat"],
        // Fallback: solo GHD real (no sit-up / V-up)
        "GHD sit-up": ["art_cf_ghd_1", "art_cf_ghd_2", "art_cf_ghd_3"],
        "V-up": ["art_cf_situp", "art_cf_vup", "art_cf_ttb"],

        // MARK: Gym clásico — fallback si no hay base_1…N propios
        // Con pasos dedicados en disco, imageNames prioriza esos; estas filas quedan de respaldo.
        "Fondos": ["art_fondos", "art_fondos_banco", "art_gy_pb_dip"],
        "Press militar": ["art_press_militar", "art_cf_strict_press", "art_cf_push_press"],
        "Press mancuernas": ["art_press_mancuernas", "art_aperturas", "art_press_banca"],
        "Press banca inclinada": ["art_press_inclinado", "art_press_banca", "art_press_mancuernas"],
        "Press cerrado": ["art_press_cerrado", "art_press_banca", "art_press_frances"],
        "Peso muerto rumano": ["art_rdl", "art_peso_muerto", "art_buenos_dias"],
        "Zancadas": ["art_zancadas", "art_cf_walk_lunge", "art_bulgara"],
        "Hip thrust": ["art_hip_thrust", "art_rdl", "art_buenos_dias"],
        "Remo con barra": ["art_remo_barra", "art_remo_mancuerna", "art_peso_muerto"],
        "Remo mancuerna": ["art_remo_mancuerna", "art_remo_barra", "art_jalon"],
        "Jalón al pecho": ["art_jalon", "art_dominadas", "art_remo_sentado"],
        "Sentadilla frontal": ["art_sentadilla_frontal", "art_sentadilla", "art_hl_pause_fs"],
        "Sentadilla búlgara": ["art_bulgara", "art_zancadas", "art_sentadilla"],
        "Curl barra": ["art_curl_barra", "art_curl_mancuernas", "art_curl_predicador"],
        "Press francés": ["art_press_frances", "art_press_cerrado", "art_fondos_banco"],
        "Pullover": ["art_pullover", "art_aperturas", "art_press_banca"],
    ]

    /// Cache thread-safe. Thumbs en `Dictionary` (no `NSCache`) para no perderlos al abrir el teclado.
    private final class ImageLookupCache: @unchecked Sendable {
        private let lock = NSLock()
        let images = NSCache<NSString, UIImage>()
        private var missing = Set<String>()
        private var thumbs: [String: UIImage] = [:]
        private var heroByExercise: [String: String] = [:]
        private var namesByExercise: [String: [String]] = [:]
        private var artDir: URL?
        /// Optional JPG stem set from ThumbImageLoader manifest.
        private var manifest: Set<String>?

        func installManifest(_ names: Set<String>) {
            lock.lock(); defer { lock.unlock() }
            manifest = names
        }

        func manifestHas(_ name: String) -> Bool? {
            lock.lock(); defer { lock.unlock() }
            guard let manifest else { return nil }
            return manifest.contains(name)
        }

        func thumb(for key: String) -> UIImage? {
            lock.lock(); defer { lock.unlock() }
            return thumbs[key]
        }

        func setThumb(_ image: UIImage, for key: String) {
            lock.lock(); defer { lock.unlock() }
            thumbs[key] = image
        }

        func heroName(for key: String) -> String? {
            lock.lock(); defer { lock.unlock() }
            return heroByExercise[key]
        }

        func setHeroName(_ name: String, for key: String) {
            lock.lock(); defer { lock.unlock() }
            heroByExercise[key] = name
        }

        func names(for key: String) -> [String]? {
            lock.lock(); defer { lock.unlock() }
            return namesByExercise[key]
        }

        func setNames(_ names: [String], for key: String) {
            lock.lock(); defer { lock.unlock() }
            namesByExercise[key] = names
        }

        func cachedFull(named name: String) -> UIImage? {
            lock.lock(); defer { lock.unlock() }
            if let img = images.object(forKey: name as NSString) { return img }
            if missing.contains(name) { return nil }
            return nil
        }

        func markMissing(_ name: String) {
            lock.lock(); defer { lock.unlock() }
            missing.insert(name)
        }

        func isMissing(_ name: String) -> Bool {
            lock.lock(); defer { lock.unlock() }
            return missing.contains(name)
        }

        func storeFull(_ image: UIImage, named name: String) {
            lock.lock(); defer { lock.unlock() }
            images.setObject(image, forKey: name as NSString)
        }

        func exerciseArtDirectory() -> URL? {
            lock.lock(); defer { lock.unlock() }
            if let artDir { return artDir }
            let bundle = Bundle.main
            if let url = bundle.resourceURL?.appendingPathComponent("ExerciseArt", isDirectory: true),
               FileManager.default.fileExists(atPath: url.path) {
                artDir = url
                return url
            }
            let nested = bundle.bundleURL.appendingPathComponent("ExerciseArt", isDirectory: true)
            if FileManager.default.fileExists(atPath: nested.path) {
                artDir = nested
                return nested
            }
            return nil
        }
    }

    private static let lookup = ImageLookupCache()

    static func uiImage(named name: String) -> UIImage? {
        if let cached = lookup.cachedFull(named: name) { return cached }
        if lookup.isMissing(name) { return nil }

        if let img = UIImage(named: name) {
            lookup.storeFull(img, named: name)
            return img
        }
        if let dir = lookup.exerciseArtDirectory() {
            let url = dir.appendingPathComponent("\(name).jpg")
            if let img = UIImage(contentsOfFile: url.path) {
                lookup.storeFull(img, named: name)
                return img
            }
        } else if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                  let img = UIImage(contentsOfFile: url.path) {
            lookup.storeFull(img, named: name)
            return img
        }
        lookup.markMissing(name)
        return nil
    }

    private static let nameMap: [String: String] = [
        "Press banca": "art_press_banca",
        "Press banca inclinada": "art_press_inclinado",
        "Press mancuernas": "art_press_mancuernas",
        "Press banca declinado": "art_press_declinado",
        "Press cerrado": "art_press_cerrado",
        "Aperturas": "art_aperturas",
        "Cruce de poleas": "art_cruce_poleas",
        "Pullover": "art_pullover",
        "Fondos": "art_fondos",
        "Fondos en banco": "art_fondos_banco",
        "Dominadas": "art_dominadas",
        "Remo invertido": "art_remo_invertido",
        "Jalón al pecho": "art_jalon",
        "Remo sentado": "art_remo_sentado",
        "Remo con barra": "art_remo_barra",
        "Remo mancuerna": "art_remo_mancuerna",
        "Peso muerto": "art_peso_muerto",
        "Peso muerto sumo": "art_sumo",
        "Peso muerto rumano": "art_rdl",
        "Buenos días": "art_buenos_dias",
        "Curl femoral": "art_curl_femoral",
        "Sentadilla": "art_sentadilla",
        "Sentadilla frontal": "art_sentadilla_frontal",
        "Hack squat": "art_hack_squat",
        "Prensa": "art_prensa",
        "Extensión de cuádriceps": "art_extension_cuad",
        "Zancadas": "art_zancadas",
        "Sentadilla búlgara": "art_bulgara",
        "Paso lateral con banda": "art_paso_banda",
        "Elevación de gemelos": "art_gemelos",
        "Press militar": "art_press_militar",
        "Remo al mentón": "art_remo_menton",
        "Elevaciones laterales": "art_elevaciones_laterales",
        "Elevaciones frontales": "art_elev_frontales",
        "Pájaros": "art_pajaros",
        "Face pull": "art_face_pull",
        "Curl barra": "art_curl_barra",
        "Curl mancuernas": "art_curl_mancuernas",
        "Curl martillo": "art_curl_martillo",
        "Curl predicador": "art_curl_predicador",
        "Extensión tríceps polea": "art_triceps_polea",
        "Press francés": "art_press_frances",
        "Plancha": "art_plancha",
        "Crunch": "art_crunch",
        "Elevación de piernas": "art_elev_piernas",
        "Hip thrust": "art_hip_thrust",
        "Cinta / carrera": "art_cardio",
        "Bici estática": "art_bici",
        "Remo máquina": "art_remo_erg",
        "Farmer walk": "art_farmer",
        "Ab wheel": "art_ab_wheel",
        "Press Arnold": "art_arnold",
        // CrossFit
        "Cargada": "art_cf_cargada",
        "Cargada de potencia": "art_cf_power_clean",
        "Cargada colgante": "art_cf_hang_clean",
        "Arrancada": "art_cf_arrancada",
        "Arrancada de potencia": "art_cf_power_snatch",
        "Cargada y envión": "art_cf_cj",
        "Push press": "art_cf_push_press",
        "Push jerk": "art_cf_push_jerk",
        "Split jerk": "art_cf_split_jerk",
        "Overhead squat": "art_cf_ohs",
        "Thruster": "art_cf_thruster",
        "Cluster": "art_cf_cluster",
        "Sumo high pull": "art_cf_sumo_hp",
        "Burpee": "art_cf_burpee",
        "Burpee al cajón": "art_cf_burpee_box",
        "Salto al cajón": "art_cf_box_jump",
        "Step-up al cajón": "art_cf_step_up",
        "Muscle-up barra": "art_cf_mu_bar",
        "Muscle-up anillas": "art_cf_mu_rings",
        "Toes to bar": "art_cf_ttb",
        "Knees to elbows": "art_cf_kte",
        "Chest to bar": "art_cf_ctb",
        "HSPU": "art_cf_hspu",
        "Handstand walk": "art_cf_hsw",
        "Wall walk": "art_cf_wall_walk",
        "Fondos en anillas": "art_cf_ring_dip",
        "Pistol squat": "art_cf_pistol",
        "Rope climb": "art_cf_rope",
        "Hollow rock": "art_cf_hollow",
        "GHD sit-up": "art_cf_ghd",
        "Sit-up": "art_cf_situp",
        "V-up": "art_cf_vup",
        "L-sit": "art_cf_lsit",
        "Swing kettlebell": "art_cf_kb_swing",
        "Swing americano": "art_cf_kb_amer",
        "Snatch kettlebell": "art_cf_kb_snatch",
        "Turkish get-up": "art_cf_tgu",
        "Wall ball": "art_cf_wall_ball",
        "Ball slam": "art_cf_slam",
        "Devil press": "art_cf_devil",
        "Man maker": "art_cf_manmaker",
        "Dobles de comba": "art_cf_du",
        "Simples de comba": "art_cf_su",
        "Air bike": "art_cf_airbike",
        "SkiErg": "art_cf_skierg",
        "Sled push": "art_cf_sled_push",
        "Sled pull": "art_cf_sled_pull",
        "Bear crawl": "art_cf_bear",
        "Broad jump": "art_cf_broad",
        "Walking lunge": "art_cf_walk_lunge",
        "Front rack lunge": "art_cf_fr_lunge",
        "Bar facing burpee": "art_cf_bfb",
        "Strict press": "art_cf_strict_press",
        "Hang power snatch": "art_cf_hps",
        "Hang power clean": "art_cf_hpc",
        "Arrancada colgante": "art_hl_hang_snatch",
        "Arrancada colgante completa": "art_hl_hang_sq_snatch",
        "Arrancada muscular": "art_hl_muscle_snatch",
        "Arrancada desde bloques": "art_hl_block_snatch",
        "Arrancada con pausa": "art_hl_pause_snatch",
        "Balance de arrancada": "art_hl_snatch_bal",
        "Drop snatch": "art_hl_drop_snatch",
        "Tall snatch": "art_hl_tall_snatch",
        "Arrancada en split": "art_hl_split_snatch",
        "Tirón de arrancada": "art_hl_snatch_pull",
        "Peso muerto agarre arrancada": "art_hl_snatch_dl",
        "Cargada colgante completa": "art_hl_hang_sq_clean",
        "Cargada muscular": "art_hl_muscle_clean",
        "Cargada desde bloques": "art_hl_block_clean",
        "Cargada con pausa": "art_hl_pause_clean",
        "Tall clean": "art_hl_tall_clean",
        "Tirón de cargada": "art_hl_clean_pull",
        "Cargada y press": "art_hl_clean_press",
        "Power jerk": "art_hl_power_jerk",
        "Balance de envión": "art_hl_jerk_bal",
        "Press detrás de nuca": "art_hl_btn_press",
        "Envión detrás de nuca": "art_hl_btn_jerk",
        "Sots press": "art_hl_sots",
        "Sentadilla frontal con pausa": "art_hl_pause_fs",
        "Dominadas estrictas": "art_gy_strict_pu",
        "Dominadas kipping": "art_gy_kip_pu",
        "Dominadas butterfly": "art_gy_bfly_pu",
        "Dominadas supinas": "art_gy_chinup",
        "Dominadas en anillas": "art_gy_ring_pu",
        "Remo en anillas": "art_gy_ring_row",
        "Archer pull-up": "art_gy_archer",
        "Muscle-up estricto barra": "art_gy_strict_mubar",
        "Muscle-up estricto anillas": "art_gy_strict_muring",
        "Pull-over barra": "art_gy_pullover",
        "Toes to bar estrictos": "art_gy_strict_ttb",
        "Toes to rings": "art_gy_ttr",
        "Hip to bar": "art_gy_htb",
        "Kip swing": "art_gy_kip_swing",
        "HSPU deficit": "art_gy_hspu_def",
        "HSPU libre": "art_gy_hspu_free",
        "Pike push-up": "art_gy_pike_pu",
        "Handstand hold": "art_gy_hs_hold",
        "Press to handstand": "art_gy_press_hs",
        "Fondos en paralelas": "art_gy_pb_dip",
        "Soporte en anillas": "art_gy_ring_sup",
        "False grip hang": "art_gy_false_grip",
        "Skin the cat": "art_gy_skin_cat",
        "German hang": "art_gy_german",
        "Front lever tuck": "art_gy_front_lev",
        "Back lever tuck": "art_gy_back_lev",
        "Planche tuck": "art_gy_planche",
        "V-sit": "art_gy_vsit",
        "Hollow hold": "art_gy_hollow_hold",
        "Arch hold": "art_gy_arch",
        "Candlestick": "art_gy_candle",
        "Shrimp squat": "art_gy_shrimp",
        "Cossack squat": "art_gy_cossack",
        "Air squat": "art_gy_air_squat",
        "Jumping squat": "art_gy_jump_squat",
        "Jumping lunge": "art_gy_jump_lunge",
        "GHD back extension": "art_gy_ghd_back",
        "Rope climb legless": "art_gy_rope_ll",
        "Pegboard": "art_gy_pegboard",
        "Thruster mancuernas": "art_cf_thruster_db",
        "Thruster kettlebell": "art_cf_thruster_kb",
        "Ground to overhead": "art_cf_gto",
        "Plate ground to overhead": "art_cf_plate_gto",
        "Burpee pull-up": "art_cf_burpee_pu",
        "Box jump over": "art_cf_bjo",
        "Clean kettlebell": "art_cf_kb_clean",
        "Goblet squat": "art_cf_goblet",
        "Snatch mancuerna": "art_cf_db_snatch",
        "Clean mancuerna": "art_cf_db_clean",
        "Medball clean": "art_cf_mb_clean",
        "Sandbag clean": "art_cf_sb_clean",
        "Sandbag over shoulder": "art_cf_sb_os",
        "Yoke carry": "art_cf_yoke",
        "Triples de comba": "art_cf_tu",
        "Echo bike": "art_cf_echo",
        "Shuttle run": "art_cf_shuttle",
        "Farmer carry": "art_cf_farmer_carry",
    ]

}

/// Miniatura reutilizable (lista, picker, plan). Prioriza cache síncrona (sin Task) para no trabar el teclado.
struct ExerciseThumb: View {
    let exercise: Exercise
    var size: CGFloat = 48
    @State private var fetched: UIImage?

    var body: some View {
        let cached = ExerciseArt.cachedThumb(for: exercise, pointSize: size)
        let shown = cached ?? fetched
        Group {
            if let shown {
                Image(uiImage: shown)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    OG.surface2
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: size * 0.35))
                        .foregroundStyle(OG.label3)
                }
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        .task(id: exercise.id) {
            // Solo decode si no hay cache (prefetch debería haber calentado la lista).
            guard ExerciseArt.cachedThumb(for: exercise, pointSize: size) == nil else { return }
            fetched = await ExerciseArt.loadThumb(for: exercise, pointSize: size)
        }
    }
}

/// Arte a ancho completo (edge-to-edge); alto según proporción de la imagen.
struct ExerciseArtView: View {
    let exercise: Exercise
    var showBadge: Bool = false
    var showStepCaptions: Bool = true
    /// Si false, el bloque de técnica no lleva padding horizontal (lo pone el padre).
    var captionsHorizontalPadding: CGFloat = OG.pad

    @State private var page = 0

    private var names: [String] { ExerciseArt.imageNames(for: exercise) }
    private var steps: [String] { ExerciseCopy.techniqueSteps(for: exercise) }

    /// Ancho/alto de la imagen actual (o la primera); fallback 4:3.
    private var artAspect: CGFloat {
        let name = names.indices.contains(page) ? names[page] : names.first
        if let name, let ui = ExerciseArt.uiImage(named: name), ui.size.height > 0 {
            return ui.size.width / ui.size.height
        }
        return 4.0 / 3.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if names.isEmpty {
                    fallbackDiagram
                } else if names.count == 1 {
                    fullBleed(names[0])
                } else {
                    TabView(selection: $page) {
                        ForEach(Array(names.enumerated()), id: \.offset) { idx, name in
                            fullBleed(name)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(artAspect, contentMode: .fit)
            .clipped()

            if showStepCaptions, !steps.isEmpty {
                Group {
                    if names.count > 1 {
                        OGCard {
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(page + 1)/\(names.count)")
                                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                                    .foregroundStyle(OG.onAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(OG.accent, in: Capsule())
                                Text(caption(for: page))
                                    .font(.system(size: 15))
                                    .foregroundStyle(OG.label)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            OGCardSectionTitle(title: "Técnica")
                            OGCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(idx + 1).")
                                                .font(.system(size: 14, weight: .bold).monospacedDigit())
                                                .foregroundStyle(OG.accent)
                                            Text(step)
                                                .font(.system(size: 15))
                                                .foregroundStyle(OG.label)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, captionsHorizontalPadding)
            }
        }
    }

    private func fullBleed(_ name: String) -> some View {
        ZStack {
            OG.bg
            if let ui = ExerciseArt.uiImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var fallbackDiagram: some View {
        ZStack {
            OG.surface2
            MuscleImpactDiagram(
                primaries: exercise.primaryRegions.isEmpty ? [exercise.muscleGroup] : exercise.primaryRegions,
                secondaries: exercise.secondaryRegions.isEmpty ? exercise.secondaryMuscles : exercise.secondaryRegions
            )
            .padding(24)
        }
    }

    private func caption(for index: Int) -> String {
        if steps.indices.contains(index) { return steps[index] }
        if let last = steps.last { return last }
        return "Paso \(index + 1)"
    }
}
