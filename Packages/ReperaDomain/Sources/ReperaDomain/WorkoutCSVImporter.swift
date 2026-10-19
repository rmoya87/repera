import Foundation

public enum CSVImportSource: String, Sendable {
    case strong
    case hevy
    case unknown
}

public struct CSVImportResult: Sendable {
    public var source: CSVImportSource
    public var workouts: [WorkoutSession]
    public var createdExercises: [Exercise]
    public var matchedSets: Int
    public var skippedRows: Int

    public init(
        source: CSVImportSource,
        workouts: [WorkoutSession],
        createdExercises: [Exercise],
        matchedSets: Int,
        skippedRows: Int
    ) {
        self.source = source
        self.workouts = workouts
        self.createdExercises = createdExercises
        self.matchedSets = matchedSets
        self.skippedRows = skippedRows
    }
}

public enum WorkoutCSVImporter {
    public static func detectSource(_ headerLine: String) -> CSVImportSource {
        let h = headerLine.lowercased().replacingOccurrences(of: "_", with: " ")
        if h.contains("exercise title") && h.contains("set index") { return .hevy }
        if h.contains("exercise name") && h.contains("set order") { return .strong }
        return .unknown
    }

    public static func parse(
        csv: String,
        existingExercises: [Exercise]
    ) -> CSVImportResult {
        let rows = parseRows(csv)
        guard let header = rows.first else {
            return CSVImportResult(source: .unknown, workouts: [], createdExercises: [], matchedSets: 0, skippedRows: 0)
        }
        let source = detectSource(header.joined(separator: ","))
        let map = columnMap(header: header, source: source)

        var exercises = existingExercises
        var created: [Exercise] = []
        var buckets: [String: (title: String, date: Date, items: [String: SessionExercise])] = [:]
        var matched = 0
        var skipped = 0

        for row in rows.dropFirst() {
            guard row.count >= header.count / 2 else {
                skipped += 1
                continue
            }
            func col(_ key: String) -> String {
                guard let idx = map[key], idx < row.count else { return "" }
                return row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let name = col("exercise")
            guard !name.isEmpty else {
                skipped += 1
                continue
            }

            let reps = Int(Double(col("reps").replacingOccurrences(of: ",", with: ".")) ?? 0)
            let weightRaw = Double(col("weight").replacingOccurrences(of: ",", with: "."))
            let seconds = Int(Double(col("seconds").replacingOccurrences(of: ",", with: ".")) ?? 0)
            if reps <= 0 && seconds <= 0 {
                skipped += 1
                continue
            }

            let when = parseDate(col("date")) ?? Date()
            let title = col("workout").isEmpty ? "Importado" : col("workout")
            let sessionKey = "\(title)|\(Int(when.timeIntervalSince1970))"

            let exercise = matchOrCreate(name: name, in: &exercises, created: &created)
            let weight = weightRaw.flatMap { $0 > 0 ? $0 : nil }
            let logged = LoggedSet(
                reps: reps > 0 ? reps : max(seconds, 1),
                weightKg: weight,
                completedAt: when
            )

            var bucket = buckets[sessionKey] ?? (title, when, [:])
            var sessionExercise = bucket.items[exercise.id.uuidString]
                ?? SessionExercise(exercise: exercise, plannedSets: [], loggedSets: [], isCompleted: true)
            sessionExercise.loggedSets.append(logged)
            sessionExercise.completedReps += logged.reps
            sessionExercise.isCompleted = true
            bucket.items[exercise.id.uuidString] = sessionExercise
            buckets[sessionKey] = bucket
            matched += 1
        }

        let workouts: [WorkoutSession] = buckets.values.map { bucket in
            WorkoutSession(
                title: bucket.title,
                exercises: Array(bucket.items.values),
                phase: .finished,
                startedAt: bucket.date,
                finishedAt: bucket.date
            )
        }
        .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }

        return CSVImportResult(
            source: source,
            workouts: workouts,
            createdExercises: created,
            matchedSets: matched,
            skippedRows: skipped
        )
    }

    // MARK: - Matching

    private static let aliases: [String: String] = [
        "bench press": "Press banca",
        "bench press (barbell)": "Press banca",
        "incline bench press": "Press banca inclinada",
        "dumbbell bench press": "Press mancuernas",
        "bent over row": "Remo con barra",
        "bent over row (barbell)": "Remo con barra",
        "pull up": "Dominadas",
        "pull-up": "Dominadas",
        "lat pulldown": "Jalón al pecho",
        "squat": "Sentadilla",
        "squat (barbell)": "Sentadilla",
        "deadlift": "Peso muerto",
        "romanian deadlift": "Peso muerto rumano",
        "overhead press": "Press militar",
        "military press": "Press militar",
        "lateral raise": "Elevaciones laterales",
        "lateral raise (dumbbell)": "Elevaciones laterales",
        "barbell curl": "Curl barra",
        "dumbbell curl": "Curl mancuernas",
        "triceps pushdown": "Extensión tríceps polea",
        "leg press": "Prensa",
        "plank": "Plancha",
        "hip thrust": "Hip thrust",
        "face pull": "Face pull",
        "running": "Cinta / carrera",
        "running (treadmill)": "Cinta / carrera",
    ]

    private static func matchOrCreate(
        name: String,
        in exercises: inout [Exercise],
        created: inout [Exercise]
    ) -> Exercise {
        let normalized = normalize(name)
        if let alias = aliases[normalized],
           let found = exercises.first(where: { $0.name.lowercased() == alias.lowercased() }) {
            return found
        }
        if let found = exercises.first(where: { normalize($0.name) == normalized }) {
            return found
        }
        if let found = exercises.first(where: { normalized.contains(normalize($0.name)) || normalize($0.name).contains(normalized) }) {
            return found
        }
        let muscle = guessMuscle(normalized)
        let exercise = Exercise(name: name, muscleGroup: muscle, equipment: nil, isCustom: true)
        exercises.append(exercise)
        created.append(exercise)
        return exercise
    }

    private static func normalize(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    private static func guessMuscle(_ normalized: String) -> String {
        if normalized.contains("bench") || normalized.contains("chest") || normalized.contains("fly") { return "Pecho" }
        if normalized.contains("row") || normalized.contains("pull") || normalized.contains("lat") || normalized.contains("deadlift") { return "Espalda" }
        if normalized.contains("squat") || normalized.contains("leg press") || normalized.contains("lunge") { return "Piernas" }
        if normalized.contains("curl") { return "Bíceps" }
        if normalized.contains("tricep") || normalized.contains("pushdown") || normalized.contains("extension") { return "Tríceps" }
        if normalized.contains("press") || normalized.contains("raise") || normalized.contains("shoulder") { return "Hombros" }
        if normalized.contains("plank") || normalized.contains("crunch") || normalized.contains("core") { return "Core" }
        if normalized.contains("run") || normalized.contains("bike") || normalized.contains("cardio") { return "Cardio" }
        return "Full body"
    }

    // MARK: - CSV helpers

    private static func columnMap(header: [String], source: CSVImportSource) -> [String: Int] {
        var map: [String: Int] = [:]
        for (idx, raw) in header.enumerated() {
            let h = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch source {
            case .strong:
                if h == "date" { map["date"] = idx }
                if h == "workout name" { map["workout"] = idx }
                if h == "exercise name" { map["exercise"] = idx }
                if h == "weight" { map["weight"] = idx }
                if h == "reps" { map["reps"] = idx }
                if h == "seconds" { map["seconds"] = idx }
            case .hevy:
                if h == "start_time" || h == "start time" { map["date"] = idx }
                if h == "title" { map["workout"] = idx }
                if h == "exercise_title" || h == "exercise title" { map["exercise"] = idx }
                if h == "weight_kg" || h == "weight kg" { map["weight"] = idx }
                if h == "reps" { map["reps"] = idx }
                if h == "duration_seconds" || h == "duration seconds" { map["seconds"] = idx }
            case .unknown:
                if h.contains("date") || h.contains("start") { map["date"] = idx }
                if h.contains("workout") || h == "title" { map["workout"] = idx }
                if h.contains("exercise") { map["exercise"] = idx }
                if h.contains("weight") { map["weight"] = idx }
                if h == "reps" { map["reps"] = idx }
                if h.contains("second") || h.contains("duration") { map["seconds"] = idx }
            }
        }
        return map
    }

    private static func parseRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false
        let chars = Array(csv)

        func pushField() {
            current.append(field)
            field = ""
        }
        func pushRow() {
            if !current.isEmpty { rows.append(current) }
            current = []
        }

        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",", ";":
                    pushField()
                case "\n":
                    pushField()
                    pushRow()
                case "\r":
                    break
                default:
                    field.append(c)
                }
            }
            i += 1
        }
        pushField()
        pushRow()
        return rows.filter { !$0.allSatisfy(\.isEmpty) }
    }

    private static func parseDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: trimmed) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: trimmed) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "dd/MM/yyyy HH:mm",
            "MM/dd/yyyy HH:mm",
        ] {
            df.dateFormat = format
            if let d = df.date(from: trimmed) { return d }
        }
        return nil
    }
}
