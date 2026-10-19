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

    /// Flat set for O(1) `isMuscleToken` (avoids scanning all alias arrays).
    private static let allMuscleTokens: Set<String> = {
        var set = Set(muscleAliases.keys)
        for aliases in muscleAliases.values {
            set.formUnion(aliases)
        }
        return set
    }()

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
    /// Does **not** embed the full `Exercise` (instructions/description) — keeps index cheap to copy.
    public struct Document: Sendable, Hashable {
        public let id: UUID
        public let displayName: String
        public let name: String
        public let muscle: String
        public let meta: String
        public let isFavorite: Bool
        public let muscleGroup: String
        public let sportTag: String?
        public let equipment: String?

        public init(exercise: Exercise) {
            self.id = exercise.id
            self.displayName = exercise.name
            let name = ExerciseSearch.normalize(exercise.name)
            let muscle = ExerciseSearch.normalize(exercise.muscleGroup)
            let sport = ExerciseSearch.normalize(exercise.sportTag ?? "")
            let equipmentNorm = ExerciseSearch.normalize(exercise.equipment ?? "")
            let target = ExerciseSearch.normalize(exercise.targetMuscle ?? "")
            let body = ExerciseSearch.normalize(exercise.bodyPart ?? "")
            self.name = name
            self.muscle = muscle
            self.meta = [muscle, sport, equipmentNorm, target, body].filter { !$0.isEmpty }.joined(separator: " ")
            self.isFavorite = exercise.isFavorite
            self.muscleGroup = exercise.muscleGroup
            self.sportTag = exercise.sportTag
            self.equipment = exercise.equipment
        }
    }

    public static func makeIndex(_ exercises: [Exercise]) -> [Document] {
        exercises.map(Document.init)
    }

    /// Normaliza sin `NSRegularExpression` (hot path de `makeIndex`).
    public static func normalize(_ raw: String) -> String {
        let folded = raw.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
        var out = ""
        out.reserveCapacity(folded.count)
        var lastWasSpace = true
        for ch in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(ch) {
                out.unicodeScalars.append(ch)
                lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" ")
                lastWasSpace = true
            }
        }
        if out.hasSuffix(" ") {
            out.removeLast()
        }
        return out
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
        let docs = rankedDocuments(makeIndex(exercises), query: query)
        let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        return docs.compactMap { byId[$0.id] }
    }

    public static func rankedDocuments(_ documents: [Document], query: String) -> [Document] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            return documents.sorted {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
        }
        let qTokens = tokens(from: q)
        guard !qTokens.isEmpty else { return [] }
        let phrase = qTokens.joined(separator: " ")
        // Una consulta puede estar en inglés aunque el nombre del catálogo sea español
        // (o viceversa). Mantener el ranking original y evaluar también su nombre canónico.
        let canonical = CrossFitGlossary.canonicalName(for: q)
        let resolvedTokens = canonical == q ? qTokens : tokens(from: canonical)
        // Stop words and aliases can produce an identical search despite different
        // raw strings (e.g. "press de banca" → "press banca"). Never score twice.
        let alternativeTokens = resolvedTokens == qTokens ? [] : resolvedTokens
        let alternativePhrase = alternativeTokens.joined(separator: " ")
        return documents
            .map { document -> (doc: Document, score: Int) in
                let direct = score(document, tokens: qTokens, phrase: phrase)
                let translated = alternativeTokens.isEmpty ? 0 :
                    score(document, tokens: alternativeTokens, phrase: alternativePhrase)
                return (document, max(direct, translated > 0 ? translated - 1 : 0))
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                // Cached, diacritic-folded sort key avoids expensive Foundation
                // localized collations for every tie while typing a search query.
                if lhs.doc.name != rhs.doc.name { return lhs.doc.name < rhs.doc.name }
                return lhs.doc.displayName < rhs.doc.displayName
            }
            .map(\.doc)
    }

    public static func score(_ document: Document, query: String) -> Int {
        let qTokens = tokens(from: query)
        guard !qTokens.isEmpty else { return 0 }
        let direct = score(document, tokens: qTokens, phrase: qTokens.joined(separator: " "))
        let canonical = CrossFitGlossary.canonicalName(for: query)
        let alt = canonical == query ? qTokens : tokens(from: canonical)
        guard !alt.isEmpty, alt != qTokens else { return direct }
        let translated = score(document, tokens: alt, phrase: alt.joined(separator: " "))
        return max(direct, translated > 0 ? translated - 1 : 0)
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
            let prefixScore = Weight.namePrefixPhrase - name.count * Weight.lengthPenaltyPerChar
            // Prefix outranks the strongest token/contained-phrase match for
            // ordinary exercise names; skip repeated Unicode scans entirely.
            if prefixScore >= Weight.nameContainsPhrase + Weight.coverageScale {
                return prefixScore
            }
            best = prefixScore
        }
        if name.contains(phrase) {
            let coverage = Int((Double(phrase.count) / Double(max(name.count, 1))) * Double(Weight.coverageScale))
            let phraseScore = Weight.nameContainsPhrase - name.count * Weight.lengthPenaltyPerChar + coverage
            // Ordered-token score cannot exceed 7_000 + 500. When phrase
            // dominates, computing all token matches is redundant.
            if phraseScore >= Weight.allTokensInNameOrdered + Weight.coverageScale {
                return max(best, phraseScore)
            }
            best = max(best, phraseScore)
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
        allMuscleTokens.contains(token)
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
