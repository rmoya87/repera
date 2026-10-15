import GymbroDomain
import SwiftUI
import UIKit

/// Ilustraciones originales Gymbro (hero + pasos `_1`, `_2`… para carrusel).
enum ExerciseArt {
    static func imageName(for exercise: Exercise) -> String? {
        imageNames(for: exercise).first
    }

    static func imageName(forExerciseName name: String, muscleGroup: String) -> String? {
        if let exact = nameMap[name] { return exact }
        return muscleFallback[muscleGroup]
    }

    /// Pasos numerados si existen (`base_1`…); si no, secuencia de movimientos distintos; si no, hero.
    static func imageNames(for exercise: Exercise) -> [String] {
        guard let base = imageName(forExerciseName: exercise.name, muscleGroup: exercise.muscleGroup) else {
            return []
        }
        var numbered: [String] = []
        for i in 1...8 {
            let step = "\(base)_\(i)"
            guard uiImage(named: step) != nil else { break }
            numbered.append(step)
        }
        if numbered.count >= 2 { return numbered }

        if let frames = movementFrames[exercise.name] {
            var seen = Set<String>()
            let unique = frames.filter { name in
                guard uiImage(named: name) != nil else { return false }
                return seen.insert(name).inserted
            }
            if unique.count >= 2 { return unique }
        }

        if uiImage(named: base) != nil { return [base] }
        if let first = numbered.first { return [first] }
        return []
    }

    /// Secuencias de fotogramas distintos (mismo estilo) cuando no hay `base_1/_2/_3`.
    private static let movementFrames: [String: [String]] = [
        "Arrancada muscular": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_hl_muscle_snatch"],
        "Balance de arrancada": ["art_hl_snatch_bal", "art_cf_ohs", "art_hl_sots"],
        "Arrancada": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_cf_arrancada"],
        "Arrancada de potencia": ["art_hl_snatch_pull", "art_cf_power_snatch", "art_hl_tall_snatch"],
        "Arrancada colgante": ["art_hl_hang_snatch", "art_hl_snatch_pull", "art_hl_tall_snatch"],
        "Arrancada colgante completa": ["art_hl_hang_sq_snatch", "art_cf_ohs", "art_hl_sots"],
        "Drop snatch": ["art_hl_drop_snatch", "art_cf_ohs", "art_hl_sots"],
        "Tall snatch": ["art_hl_tall_snatch", "art_cf_ohs", "art_hl_sots"],
        "Arrancada en split": ["art_hl_snatch_pull", "art_hl_split_snatch", "art_hl_tall_snatch"],
        "Tirón de arrancada": ["art_hl_snatch_dl", "art_hl_snatch_pull", "art_hl_tall_snatch"],
        "Cargada muscular": ["art_hl_clean_pull", "art_hl_muscle_clean", "art_hl_tall_clean"],
        "Cargada": ["art_hl_clean_pull", "art_cf_cargada", "art_hl_tall_clean"],
        "Cargada de potencia": ["art_hl_clean_pull", "art_cf_power_clean", "art_hl_tall_clean"],
        "Cargada colgante": ["art_cf_hang_clean", "art_hl_clean_pull", "art_hl_tall_clean"],
        "Balance de envión": ["art_hl_jerk_bal", "art_hl_power_jerk", "art_cf_split_jerk"],
        "Power jerk": ["art_hl_jerk_bal", "art_hl_power_jerk", "art_cf_push_jerk"],
        "Push jerk": ["art_cf_push_press", "art_cf_push_jerk", "art_hl_power_jerk"],
        "Split jerk": ["art_cf_push_press", "art_cf_split_jerk", "art_hl_btn_jerk"],
    ]

    static func uiImage(named name: String) -> UIImage? {
        if let img = UIImage(named: name) { return img }
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.url(forResource: name, withExtension: "jpg", subdirectory: "ExerciseArt"),
            bundle.url(forResource: name, withExtension: "jpg"),
            bundle.resourceURL?.appendingPathComponent("ExerciseArt/\(name).jpg"),
            bundle.bundleURL.appendingPathComponent("ExerciseArt/\(name).jpg"),
        ]
        for url in candidates {
            guard let url, FileManager.default.fileExists(atPath: url.path),
                  let img = UIImage(contentsOfFile: url.path)
            else { continue }
            return img
        }
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

    private static let muscleFallback: [String: String] = [
        "Pecho": "art_press_banca",
        "Espalda": "art_remo_barra",
        "Piernas": "art_sentadilla",
        "Isquios": "art_rdl",
        "Hombros": "art_press_militar",
        "Bíceps": "art_curl_barra",
        "Tríceps": "art_triceps_polea",
        "Core": "art_plancha",
        "Glúteos": "art_hip_thrust",
        "Gemelos": "art_gemelos",
        "Cardio": "art_cardio",
        "CrossFit": "art_cf_thruster",
        "Halterofilia": "art_cf_cargada",
        "Gimnasia": "art_cf_mu_bar",
    ]
}

/// Miniatura reutilizable (lista, picker, plan).
struct ExerciseThumb: View {
    let exercise: Exercise
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(OG.surface2)
            if let name = ExerciseArt.imageName(for: exercise),
               let ui = ExerciseArt.uiImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(OG.label3)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }
}

/// Arte a ancho completo; carrusel por imágenes `_1`… o por pasos de técnica.
struct ExerciseArtView: View {
    let exercise: Exercise
    var height: CGFloat = 280
    var showBadge: Bool = false
    var showStepCaptions: Bool = true

    @State private var page = 0

    private var names: [String] { ExerciseArt.imageNames(for: exercise) }
    private var steps: [String] { ExerciseCopy.techniqueSteps(for: exercise) }

    /// Solo una página por imagen distinta (`_1`, `_2`…). Nunca repetir la misma foto por cada paso de texto.
    private var pageCount: Int { max(names.count, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: OG.radiusLG, style: .continuous))
            .clipped()

            if showStepCaptions, !steps.isEmpty {
                if names.count > 1 {
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
                    .padding(.horizontal, 4)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Técnica")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(OG.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(OG.accent, in: Capsule())
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
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private func fullBleed(_ name: String) -> some View {
        ZStack {
            OG.bg
            if let ui = ExerciseArt.uiImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
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
