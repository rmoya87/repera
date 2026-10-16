import Foundation

/// Búsqueda flexible de ejercicios con ranking por pesos (tokens, sin acentos, sin «de/el/ejercicio…»).
public enum ExerciseSearch {
    private static let stopWords: Set<String> = [
        "de", "del", "la", "el", "los", "las", "un", "una", "unos", "unas",
        "y", "o", "en", "con", "para", "por", "a", "al",
        "ejercicio", "ejercicios", "movimiento", "movimientos",
        "exercise", "exercises", "workout", "training",
    ]

    /// Sinónimos / aliases → grupos musculares (no meter aquí tokens de movimiento como «banca»).
    private static let muscleAliases: [String: [String]] = [
        "pecho": ["pecho", "pectoral", "pectorales", "chest"],
        "espalda": ["espalda", "dorsal", "dorsales", "back", "lats", "lat"],
        "piernas": ["piernas", "pierna", "cuadriceps", "cuádriceps", "quads", "legs", "leg"],
        "isquios": ["isquios", "isquiotibiales", "hamstring", "hamstrings"],
        "hombros": ["hombros", "hombro", "deltoides", "shoulders", "shoulder"],
        "biceps": ["biceps", "bíceps", "bicep"],
        "triceps": ["triceps", "tríceps", "tricep"],
        "core": ["core", "abdomen", "abs", "abdominales"],
        "gluteos": ["gluteos", "glúteos", "gluteo", "glúteo", "glutes"],
        "gemelos": ["gemelos", "pantorrilla", "pantorrillas", "calves", "calf"],
        "antebrazos": ["antebrazos", "antebrazo", "forearm", "forearms", "grip"],
        "cardio": ["cardio", "aerobico", "aeróbico", "running", "bike"],
    ]

    /// Aliases EN → tokens ES de nombre (p. ej. bench → banca).
    private static let tokenAliases: [String: String] = [
        "bench": "banca",
        "benchpress": "banca",
        "chestpress": "banca",
    ]

    // MARK: - Pesos (mayor = más relevante)

    private enum Weight {
        static let exactName = 10_000
        static let namePrefixPhrase = 9_000
        static let nameContainsPhrase = 8_000
        static let allTokensInNameOrdered = 7_000
        static let allTokensInName = 6_000
        static let perTokenInName = 450
        static let perTokenInMeta = 120
        static let muscleOnlyIntent = 200
        static let lengthPenaltyPerChar = 2
        static let coverageScale = 500
    }

    /// Campos ya normalizados (una vez al abrir / al cambiar catálogo).
    public struct Document: Sendable, Hashable {
        public let exercise: Exercise
        public let name: String
        public let muscle: String
        public let meta: String

        public init(exercise: Exercise) {
            self.exercise = exercise
            let name = ExerciseSearch.normalize(exercise.name)
            let muscle = ExerciseSearch.normalize(exercise.muscleGroup)
            let sport = ExerciseSearch.normalize(exercise.sportTag ?? "")
            let equipment = ExerciseSearch.normalize(exercise.equipment ?? "")
            let target = ExerciseSearch.normalize(exercise.targetMuscle ?? "")
            let body = ExerciseSearch.normalize(exercise.bodyPart ?? "")
            self.name = name
            self.muscle = muscle
            self.meta = [muscle, sport, equipment, target, body].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }

    public static func makeIndex(_ exercises: [Exercise]) -> [Document] {
        exercises.map(Document.init)
    }

    public static func normalize(_ raw: String) -> String {
        raw.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
            .replacingOccurrences(of: #"[:\-_/.,;+()¡!¿?]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func tokens(from raw: String) -> [String] {
        let n = normalize(raw)
        guard !n.isEmpty else { return [] }
        let parts = n.split(separator: " ").map(String.init)
        let filtered = parts.filter { $0.count >= 2 && !stopWords.contains($0) }
        let base = filtered.isEmpty ? parts.filter { !$0.isEmpty } : filtered
        return base.map { tokenAliases[$0] ?? $0 }
    }

    public static func matches(_ exercise: Exercise, query: String) -> Bool {
        score(Document(exercise: exercise), query: query) > 0
    }

    public static func score(_ exercise: Exercise, query: String) -> Int {
        score(Document(exercise: exercise), query: query)
    }

    /// Filtra y ordena por puntuación (desc); empate → nombre.
    public static func ranked(_ exercises: [Exercise], query: String) -> [Exercise] {
        ranked(makeIndex(exercises), query: query)
    }

    public static func ranked(_ documents: [Document], query: String) -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return documents
                .map(\.exercise)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        let qTokens = tokens(from: q)
        guard !qTokens.isEmpty else { return [] }
        let phrase = qTokens.joined(separator: " ")
        return documents
            .map { document -> (doc: Document, score: Int) in
                (document, score(document, tokens: qTokens, phrase: phrase))
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.doc.exercise.name.localizedStandardCompare(rhs.doc.exercise.name) == .orderedAscending
            }
            .map(\.doc.exercise)
    }

    public static func score(_ document: Document, query: String) -> Int {
        let qTokens = tokens(from: query)
        guard !qTokens.isEmpty else { return 0 }
        return score(document, tokens: qTokens, phrase: qTokens.joined(separator: " "))
    }

    // MARK: - Scoring

    private static func score(_ doc: Document, tokens qTokens: [String], phrase: String) -> Int {
        let name = doc.name
        let muscle = doc.muscle
        let meta = doc.meta

        if name == phrase {
            return Weight.exactName
        }

        var best = 0

        if name.hasPrefix(phrase) {
            best = max(best, Weight.namePrefixPhrase - name.count * Weight.lengthPenaltyPerChar)
        }
        if name.contains(phrase) {
            let coverage = Int((Double(phrase.count) / Double(max(name.count, 1))) * Double(Weight.coverageScale))
            best = max(
                best,
                Weight.nameContainsPhrase - name.count * Weight.lengthPenaltyPerChar + coverage
            )
        }

        let tokensInName = qTokens.filter { name.contains($0) }
        if tokensInName.count == qTokens.count {
            let ordered = tokensAppearInOrder(qTokens, in: name)
            var s = (ordered ? Weight.allTokensInNameOrdered : Weight.allTokensInName)
            s -= name.count * Weight.lengthPenaltyPerChar
            let coverage = Int((Double(phrase.count) / Double(max(name.count, 1))) * Double(Weight.coverageScale))
            s += coverage
            best = max(best, s)
        }

        if best == 0 {
            var partial = 0
            var nameHits = 0
            for token in qTokens {
                if name.contains(token) {
                    partial += Weight.perTokenInName
                    nameHits += 1
                } else if meta.contains(token) {
                    partial += Weight.perTokenInMeta
                }
            }
            if isMuscleOnlyQuery(qTokens) {
                if partial > 0 || matchesMuscleGroup(qTokens, muscleGroup: muscle) {
                    best = max(partial, Weight.muscleOnlyIntent)
                }
            } else if nameHits == qTokens.count {
                best = partial
            } else if qTokens.count == 1, nameHits == 1 {
                best = partial
            }
        }

        if best == 0, isMuscleOnlyQuery(qTokens), matchesMuscleGroup(qTokens, muscleGroup: muscle) {
            return Weight.muscleOnlyIntent
        }

        return max(best, 0)
    }

    // MARK: - Helpers

    private static func tokensAppearInOrder(_ tokens: [String], in haystack: String) -> Bool {
        var searchRange = haystack.startIndex..<haystack.endIndex
        for token in tokens {
            guard let range = haystack.range(of: token, range: searchRange) else { return false }
            searchRange = range.upperBound..<haystack.endIndex
        }
        return true
    }

    private static func isMuscleOnlyQuery(_ tokens: [String]) -> Bool {
        tokens.allSatisfy(isMuscleToken)
    }

    private static func isMuscleToken(_ token: String) -> Bool {
        if muscleAliases[token] != nil { return true }
        return muscleAliases.values.contains { $0.contains(token) }
    }

    private static func matchesMuscleGroup(_ tokens: [String], muscleGroup: String) -> Bool {
        for token in tokens {
            for (canonical, aliases) in muscleAliases {
                guard aliases.contains(token) || canonical == token else { continue }
                if muscleGroup.contains(canonical) { return true }
                if aliases.contains(where: { muscleGroup.contains($0) }) { return true }
            }
        }
        return false
    }
}
