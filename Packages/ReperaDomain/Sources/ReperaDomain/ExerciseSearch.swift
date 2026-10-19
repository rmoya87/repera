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

    /// Traducciones de frases completas: se prueban además del texto original.
    /// No sustituyen los nombres reales; una búsqueda exacta sigue siendo prioritaria.
    private static let bilingualPhrases: [String: String] = [
        // Gimnasio: el catálogo es mayoritariamente español, pero usuarios
        // y pizarras suelen introducir su denominación técnica en inglés.
        "incline bench press": "press banca inclinada",
        "decline bench press": "press banca declinado",
        "dumbbell bench press": "press mancuernas",
        "dumbbell press": "press mancuernas",
        "chest fly": "aperturas",
        "chest flyes": "aperturas",
        "dips": "fondos",
        "lat pulldown": "jalon al pecho",
        "lat pull down": "jalon al pecho",
        "barbell row": "remo con barra",
        "bent over row": "remo con barra",
        "dumbbell row": "remo mancuerna",
        "romanian deadlift": "peso muerto rumano",
        "rdl": "peso muerto rumano",
        "sumo deadlift": "peso muerto sumo",
        "front squat": "sentadilla frontal",
        "leg press": "prensa",
        "leg extension": "extension de cuadriceps",
        "leg extensions": "extension de cuadriceps",
        "leg curl": "curl femoral",
        "hamstring curl": "curl femoral",
        "calf raises": "elevacion de gemelos",
        "calf raise": "elevacion de gemelos",
        "overhead press": "press militar",
        "shoulder press": "press militar",
        "lateral raises": "elevaciones laterales",
        "lateral raise": "elevaciones laterales",
        "rear delt fly": "pajaros",
        "barbell curl": "curl barra",
        "dumbbell curl": "curl mancuernas",
        "hammer curl": "curl martillo",
        "preacher curl": "curl predicador",
        "triceps pushdown": "extension triceps polea",
        "tricep pushdown": "extension triceps polea",
        "close grip bench press": "press cerrado",
        "plank": "plancha",
        "leg raises": "elevacion de piernas",
        "upright row": "remo al menton",
        "good morning": "buenos dias",
        "treadmill": "cinta carrera",
        "stationary bike": "bici estatica",
        "rowing machine": "remo maquina",
        "cable fly": "cruce de poleas",
        "seated row": "remo sentado",
        "bulgarian split squat": "sentadilla bulgara",
        "skull crusher": "press frances",
        "front raises": "elevaciones frontales",
        "band lateral walk": "paso lateral con banda",
        "inverted row": "remo invertido",
        "back squat": "sentadilla",
        "sentadilla trasera": "sentadilla",
        "sentadilla con barra": "sentadilla",
        "squat": "sentadilla",
        "squats": "sentadilla",
        "power snatch": "arrancada de potencia",
        "arrancada de potencia": "power snatch",
        "snatch": "arrancada",
        "arrancada": "snatch",
        "high hang squat snatch": "arrancada colgante completa",
        "high hsq snatch": "arrancada colgante completa",
        "deadlift": "peso muerto",
        "peso muerto": "deadlift",
        "bench press": "press banca",
        "press banca": "bench press",
        "walking lunge": "zancadas",
        "zancadas caminando": "walking lunge",
        "lunges": "zancadas",
        "lunge": "zancadas",
        "zancadas": "lunges",
        "reverse lunges": "zancadas",
        "barbell reverse lunges": "zancadas inversas con barra",
        "back rack r lunges": "zancadas inversas con barra",
        "zancadas inversas con barra": "back rack reverse lunges",
        "front rack lunge": "zancadas rack frontal",
        "zancadas rack frontal": "front rack lunge",
        "pull ups": "dominadas",
        "pull up": "dominadas",
        "dominadas": "pull ups",
        "overhead squat": "sentadilla overhead",
        "sentadilla overhead": "overhead squat",
    ]

    /// Traducción parcial para consultas largas que no coinciden con una frase.
    private static let bilingualTokens: [String: String] = [
        "squat": "sentadilla", "squats": "sentadilla",
        "lunges": "zancadas", "lunge": "zancadas",
        "snatch": "arrancada", "clean": "cargada",
        "deadlift": "peso muerto", "deadlifts": "peso muerto",
        "zancada": "lunges", "zancadas": "lunges",
        "sentadilla": "squat", "arrancada": "snatch",
        "cargada": "clean", "potencia": "power", "power": "potencia",
        "jump": "salto", "salto": "jump",
    ]

    private static func queryCandidates(_ raw: String) -> [[String]] {
        let original = tokens(from: raw)
        guard !original.isEmpty else { return [] }
        var variants = [original]
        let key = normalize(raw)
        if let alias = bilingualPhrases[key] ?? CrossFitGlossary.aliases[key] {
            let synonym = tokens(from: alias)
            if !synonym.isEmpty && !variants.contains(synonym) { variants.append(synonym) }
        }
        let translated = original.map { bilingualTokens[$0] ?? $0 }
        if translated != original && !variants.contains(translated) {
            variants.append(translated)
        }
        return variants
    }

    private static func searchScore(_ document: Document, variants: [[String]]) -> Int {
        // Una coincidencia literal exacta tiene prioridad sobre una traducción.
        guard let first = variants.first else { return 0 }
        var best = score(document, tokens: first, phrase: first.joined(separator: " "))
        if best == Weight.exactName { return best }
        for variant in variants.dropFirst() {
            let translated = score(document, tokens: variant, phrase: variant.joined(separator: " "))
            best = max(best, min(translated, Weight.namePrefixPhrase - 1))
        }
        return best
    }

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
        let variants = queryCandidates(q)
        guard !variants.isEmpty else { return [] }
        return documents
            .map { document -> (doc: Document, score: Int) in
                (document, searchScore(document, variants: variants))
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.doc.displayName.localizedStandardCompare(rhs.doc.displayName) == .orderedAscending
            }
            .map(\.doc)
    }

    public static func score(_ document: Document, query: String) -> Int {
        let variants = queryCandidates(query)
        return searchScore(document, variants: variants)
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
