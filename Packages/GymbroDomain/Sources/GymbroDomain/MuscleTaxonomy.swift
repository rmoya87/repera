import Foundation

/// Músculos dibujables en el BodyMap (orden cabeza → pies), alineados con openGym.
public enum MuscleTaxonomy {
    public static let muscles: [String] = [
        "trapezius", "deltoids", "chest", "upper-back", "serratus",
        "biceps", "triceps", "forearm",
        "abs", "obliques", "lower-back",
        "gluteal", "quadriceps", "hamstring", "adductors", "hip-flexors",
        "calves", "tibialis",
    ]

    public static let displayNameES: [String: String] = [
        "trapezius": "Trapecio",
        "deltoids": "Hombros",
        "chest": "Pecho",
        "upper-back": "Espalda alta",
        "serratus": "Serrato",
        "biceps": "Bíceps",
        "triceps": "Tríceps",
        "forearm": "Antebrazos",
        "abs": "Abdomen",
        "obliques": "Oblicuos",
        "lower-back": "Lumbar",
        "gluteal": "Glúteos",
        "quadriceps": "Cuádriceps",
        "hamstring": "Isquios",
        "adductors": "Aductores",
        "hip-flexors": "Flexores de cadera",
        "calves": "Gemelos",
        "tibialis": "Tibial",
    ]

    /// Partes inertes del SVG (silueta, sin color de carga).
    public static let inert: [String] = [
        "head", "hair", "neck", "hands", "feet", "knees", "ankles",
    ]

    /// Primario = 1.0. Secundarios: el primero ~0.55, el resto ~0.35 (más realista que un 0.4 plano).
    private static let secondaryPrimaryWeight: Double = 0.55
    private static let secondaryWeight: Double = 0.35

    /// bodyPart genéricos de Open API que no deben pintar el BodyMap a peso 1.
    private static let nonMuscleBodyParts: Set<String> = [
        "full body", "upper arms", "upper legs", "lower legs", "waist", "cardio", "shoulders",
    ]

    private static let alias: [String: String?] = [
        "abs": "abs", "abdominals": "abs", "core": "abs", "lower abs": "abs", "abdomen": "abs",
        "pectorals": "chest", "chest": "chest", "pecho": "chest", "upper chest": "chest",
        "biceps": "biceps", "bíceps": "biceps", "brachialis": "biceps",
        "triceps": "triceps", "tríceps": "triceps",
        "glutes": "gluteal", "gluteal": "gluteal", "glúteos": "gluteal", "abductors": "gluteal",
        "delts": "deltoids", "deltoids": "deltoids", "shoulders": "deltoids", "hombros": "deltoids",
        "rear deltoids": "deltoids", "rotator cuff": "deltoids",
        "upper back": "upper-back", "upper-back": "upper-back", "lats": "upper-back",
        "latissimus dorsi": "upper-back", "rhomboids": "upper-back", "back": "upper-back", "espalda": "upper-back",
        "calves": "calves", "gemelos": "calves", "soleus": "calves",
        "quads": "quadriceps", "quadriceps": "quadriceps", "piernas": "quadriceps",
        "forearms": "forearm", "forearm": "forearm", "wrists": "forearm", "antebrazos": "forearm",
        "grip": "forearm", "grip muscles": "forearm",
        "hamstrings": "hamstring", "hamstring": "hamstring", "isquios": "hamstring",
        "spine": "lower-back", "lower back": "lower-back", "lower-back": "lower-back", "lumbar": "lower-back",
        "traps": "trapezius", "trapezius": "trapezius", "trapecio": "trapezius", "levator scapulae": "trapezius",
        "adductors": "adductors", "aductores": "adductors", "groin": "adductors", "inner thighs": "adductors",
        "serratus anterior": "serratus", "serratus": "serratus",
        "hip flexors": "hip-flexors", "hip-flexors": "hip-flexors",
        "obliques": "obliques", "oblicuos": "obliques",
        "shins": "tibialis", "tibialis": "tibialis",
        "legs": "quadriceps",
        "ankles": nil, "feet": nil, "hands": nil, "ankle stabilizers": nil,
        "cardiovascular system": nil, "cardio": nil,
        "full body": nil, "upper arms": nil, "upper legs": nil, "lower legs": nil, "waist": nil,
    ]

    private static let byBodyPartES: [String: [String: Double]] = [
        "Pecho": ["chest": 1],
        "Espalda": ["upper-back": 0.75, "lower-back": 0.25],
        "Hombros": ["deltoids": 1],
        "Bíceps": ["biceps": 1],
        "Tríceps": ["triceps": 1],
        "Piernas": ["quadriceps": 0.4, "hamstring": 0.35, "gluteal": 0.25],
        "Isquios": ["hamstring": 0.7, "gluteal": 0.3],
        "Glúteos": ["gluteal": 1],
        "Gemelos": ["calves": 0.8, "tibialis": 0.2],
        "Core": ["abs": 0.7, "obliques": 0.3],
        "Cardio": [:],
        "Antebrazos": ["forearm": 1],
        "Custom": ["chest": 0.2, "upper-back": 0.2, "gluteal": 0.2, "quadriceps": 0.2, "hamstring": 0.1, "abs": 0.1],
        "WOD": ["chest": 0.15, "upper-back": 0.15, "quadriceps": 0.2, "hamstring": 0.15, "gluteal": 0.15, "abs": 0.1, "deltoids": 0.1],
    ]

    /// Grupo de biblioteca (filtro ES) según el músculo que más carga el ejercicio.
    /// No usar deportes (CrossFit, Halterofilia…) como grupo: las métricas van al primario.
    public static func libraryMuscleGroup(primaries: [String], target: String?) -> String {
        let candidates = primaries + [target].compactMap { $0 }
        for raw in candidates {
            if let slug = canonical(raw), let group = filterGroupES[slug] {
                return group
            }
            if byBodyPartES[raw] != nil { return raw }
        }
        let t = (target ?? "").lowercased()
        if t.contains("cardio") { return "Cardio" }
        return "Custom"
    }

    private static let filterGroupES: [String: String] = [
        "chest": "Pecho",
        "upper-back": "Espalda",
        "lower-back": "Espalda",
        "serratus": "Espalda",
        "trapezius": "Espalda",
        "deltoids": "Hombros",
        "biceps": "Bíceps",
        "triceps": "Tríceps",
        "forearm": "Antebrazos",
        "quadriceps": "Piernas",
        "adductors": "Piernas",
        "hip-flexors": "Piernas",
        "hamstring": "Isquios",
        "gluteal": "Glúteos",
        "calves": "Gemelos",
        "tibialis": "Gemelos",
        "abs": "Core",
        "obliques": "Core",
    ]

    public static func canonical(_ value: String?) -> String? {
        guard let value else { return nil }
        let name = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if muscles.contains(name) { return name }
        if let mapped = alias[name] { return mapped }
        // Spanish display without accents already handled above; try display reverse.
        for (slug, label) in displayNameES where label.lowercased() == name {
            return slug
        }
        return nil
    }

    public static func displayName(_ slug: String) -> String {
        displayNameES[slug] ?? slug
    }

    /// Pesos 0…1 por músculo dibujable para un ejercicio del catálogo.
    public static func muscleWeights(for exercise: Exercise) -> [String: Double] {
        var out: [String: Double] = [:]
        func add(_ raw: String?, _ w: Double) {
            guard let slug = canonical(raw) else { return }
            out[slug] = max(out[slug] ?? 0, w)
        }
        func merge(_ weights: [String: Double], scale: Double = 1) {
            for (slug, w) in weights where w > 0 {
                out[slug] = max(out[slug] ?? 0, w * scale)
            }
        }

        if let target = exercise.targetMuscle, !target.isEmpty {
            add(target, 1)
        }
        for region in exercise.primaryRegions {
            add(region, 1)
        }
        for (idx, secondary) in exercise.secondaryMuscles.enumerated() {
            add(secondary, idx == 0 ? secondaryPrimaryWeight : secondaryWeight)
        }
        for (idx, region) in exercise.secondaryRegions.enumerated() {
            // secondaryRegions suelen ser más precisos (slugs BodyMap).
            add(region, idx == 0 ? secondaryPrimaryWeight : secondaryWeight)
        }
        // bodyPart genérico (upper arms, full body…) no debe pintar a peso 1.
        if let body = exercise.bodyPart?.lowercased(),
           !nonMuscleBodyParts.contains(body),
           canonical(body) != nil {
            add(body, out.isEmpty ? 1 : 0.25)
        }
        if out.isEmpty {
            add(exercise.muscleGroup, 1)
        } else {
            // Refuerzo suave del grupo de biblioteca si aún no hay carga ahí.
            add(exercise.muscleGroup, 0.2)
        }

        if out.isEmpty, let fallback = byBodyPartES[exercise.muscleGroup] {
            merge(fallback)
        }
        // Último recurso: grupo ES → distribución genérica.
        if out.isEmpty {
            merge(byBodyPartES["Custom"] ?? ["abs": 0.5, "upper-back": 0.5])
        }
        return out.filter { $0.value > 0 }
    }
}

/// Estímulo externo (p. ej. Salud) ya resuelto a carga por músculo.
public struct ExternalMuscleStimulus: Sendable, Equatable {
    public var date: Date
    public var load: [String: Double]

    public init(date: Date, load: [String: Double]) {
        self.date = date
        self.load = load
    }
}

/// Contribución diaria agregada (Gymbro + Salud) para heatmap.
public struct DayActivityContribution: Sendable, Equatable, Identifiable {
    public var id: String { dayKey }
    public var dayKey: String
    public var date: Date
    public var minutes: Double
    public var volumeKg: Double
    public var sessionCount: Int

    public init(dayKey: String, date: Date, minutes: Double, volumeKg: Double, sessionCount: Int) {
        self.dayKey = dayKey
        self.date = date
        self.minutes = minutes
        self.volumeKg = volumeKg
        self.sessionCount = sessionCount
    }
}

public enum MuscleBalanceWindow: Int, Sendable, CaseIterable, Identifiable {
    case week = 7
    case days30 = 30
    case days90 = 90
    case all = 0

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .week: return "Semana"
        case .days30: return "30d"
        case .days90: return "90d"
        case .all: return "Todo"
        }
    }
}

public enum MuscleLoadEngine {
    /// Series efectivas por músculo en la ventana (entrenos Gymbro + estímulos Salud).
    public static func load(
        workouts: [WorkoutSession],
        external: [ExternalMuscleStimulus] = [],
        window: MuscleBalanceWindow,
        weekOffset: Int = 0,
        weekStartsOnMonday: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current,
        hardOnly: Bool = false
    ) -> [String: Double] {
        var cal = calendar
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1

        let inWindow = workouts.filter { workout in
            guard let day = workout.finishedAt ?? workout.startedAt else { return false }
            return dateInWindow(day, window: window, weekOffset: weekOffset, now: now, calendar: cal)
        }

        var load: [String: Double] = [:]
        for workout in inWindow {
            for entry in workout.exercises {
                let sets = entry.loggedSets.filter { set in
                    guard set.reps > 0, !set.isWarmup else { return false }
                    if hardOnly {
                        return Effort.isHard(rir: set.rir)
                    }
                    return true
                }.count
                guard sets > 0 else { continue }
                let weights = MuscleTaxonomy.muscleWeights(for: entry.exercise)
                for (slug, w) in weights {
                    load[slug, default: 0] += w * Double(sets)
                }
            }
        }

        for stimulus in external {
            guard dateInWindow(stimulus.date, window: window, weekOffset: weekOffset, now: now, calendar: cal) else {
                continue
            }
            for (slug, w) in stimulus.load {
                load[slug, default: 0] += w
            }
        }
        return load
    }

    public static func levels(of load: [String: Double]) -> [String: Int] {
        let maxLoad = MuscleTaxonomy.muscles.map { load[$0] ?? 0 }.max() ?? 0
        var out: [String: Int] = [:]
        for slug in MuscleTaxonomy.muscles {
            let v = load[slug] ?? 0
            if v <= 0 || maxLoad <= 0 {
                out[slug] = 0
            } else {
                out[slug] = max(1, min(4, Int(ceil(v / maxLoad * 4))))
            }
        }
        return out
    }

    public static func ranked(load: [String: Double]) -> (worked: [String], missed: [String]) {
        let worked = MuscleTaxonomy.muscles
            .filter { (load[$0] ?? 0) > 0 }
            .sorted { (load[$0] ?? 0) > (load[$1] ?? 0) }
        let missed = MuscleTaxonomy.muscles.filter { (load[$0] ?? 0) <= 0 }
        return (worked, missed)
    }

    private static func dateInWindow(
        _ date: Date,
        window: MuscleBalanceWindow,
        weekOffset: Int,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        switch window {
        case .all:
            return true
        case .week:
            guard let weekStart = startOfWeek(containing: now, calendar: calendar),
                  let selected = calendar.date(byAdding: .day, value: weekOffset * 7, to: weekStart),
                  let selectedEnd = calendar.date(byAdding: .day, value: 7, to: selected)
            else { return false }
            return date >= selected && date < selectedEnd
        case .days30, .days90:
            let days = window.rawValue
            guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return false }
            return date > cutoff
        }
    }

    public static func startOfWeek(containing date: Date, calendar: Calendar) -> Date? {
        let weekday = calendar.component(.weekday, from: date)
        let first = calendar.firstWeekday
        let delta = (weekday - first + 7) % 7
        return calendar.date(byAdding: .day, value: -delta, to: calendar.startOfDay(for: date))
    }
}
