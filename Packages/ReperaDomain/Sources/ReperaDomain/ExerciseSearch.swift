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

    /// Resolución EN/abreviatura → etiqueta de catálogo para el escáner de pizarra.
    /// Comparte la misma tabla que la búsqueda (`bilingualPhrases`).
    public static func scannerCatalogName(forNormalizedQuery key: String) -> String? {
        guard let hit = bilingualPhrases[key], !hit.isEmpty else { return nil }
        if let glossary = CrossFitGlossary.aliases.first(where: { CrossFitGlossary.normalize($0.value) == CrossFitGlossary.normalize(hit) })?.value {
            return glossary
        }
        return hit
    }

    /// Traducciones de frases completas: se prueban además del texto original.
    /// No sustituyen los nombres reales; una búsqueda exacta sigue siendo prioritaria.
    private static let bilingualPhrases: [String: String] = [
        "rowing": "remo maquina",
        "rowerg": "remo maquina",
        "ski erg": "skierg",
        "ski ergometer": "skierg",
        "farmers carry": "farmer carry",
        "burpee broad jumps": "burpee broad jump",
        "sandbag lunge": "sandbag lunges",
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
        "walking lunge": "walking lunge",
        "zancadas caminando": "walking lunge",
        "lunges": "zancadas",
        "lunge": "zancadas",
        "zancadas": "lunges",
        // Sin equipo → zancadas genéricas; con barra/rack → ficha concreta.
        "reverse lunges": "zancadas",
        "reverse lunge": "zancadas",
        "barbell reverse lunges": "zancadas inversas con barra",
        "back rack r lunges": "zancadas inversas con barra",
        "zancadas inversas con barra": "back rack reverse lunge",
        "front rack lunge": "front rack lunge",
        "front rack lunges": "front rack lunge",
        "pull ups": "dominadas",
        "pull up": "dominadas",
        "pull-up": "dominadas",
        "pull-ups": "dominadas",
        "dominadas": "pull ups",
        // Chin-up = agarre supino (no confundir con pull-up / Dominadas).
        "chin up": "dominadas supinas",
        "chin ups": "dominadas supinas",
        "chin-up": "dominadas supinas",
        "chin-ups": "dominadas supinas",
        "chinup": "dominadas supinas",
        "chinups": "dominadas supinas",
        "underhand pull up": "dominadas supinas",
        "supinated pull up": "dominadas supinas",
        "dominadas supinas": "chin ups",
        "strict pull up": "dominadas estrictas",
        "strict pull-up": "dominadas estrictas",
        "strict pull ups": "dominadas estrictas",
        "kipping pull up": "dominadas kipping",
        "kipping pull-up": "dominadas kipping",
        "butterfly pull up": "dominadas butterfly",
        "butterfly pull-up": "dominadas butterfly",
        "overhead squat": "overhead squat",
        "ohs": "overhead squat",
        "ohsq": "overhead squat",
        "air squat": "air squat",
        "goblet squat": "goblet squat",
        "pistol squat": "pistol squat",
        // Gimnasio (catálogo ES ↔ búsqueda EN)
        "back squats": "sentadilla",
        "barbell back squat": "sentadilla",
        "barbell squat": "sentadilla",
        "front squats": "sentadilla frontal",
        "barbell front squat": "sentadilla frontal",
        "pullup": "dominadas",
        "pullups": "dominadas",
        "ring pull up": "dominadas en anillas",
        "ring pull-up": "dominadas en anillas",
        "chest to bar": "chest to bar",
        "c2b": "chest to bar",
        "ctb": "chest to bar",
        "lat pulldowns": "jalon al pecho",
        "pulldown": "jalon al pecho",
        "power clean": "cargada de potencia",
        "hang clean": "cargada colgante",
        "hang snatch": "arrancada colgante",
        "hang squat clean": "cargada colgante completa",
        "db thruster": "thruster mancuernas",
        "dumbbell thruster": "thruster mancuernas",
        "kb thruster": "thruster kettlebell",
        "kettlebell thruster": "thruster kettlebell",
        "db snatch": "snatch mancuerna",
        "dumbbell snatch": "snatch mancuerna",
        "kb snatch": "snatch kettlebell",
        "bar muscle up": "muscle-up barra",
        "ring muscle up": "muscle-up anillas",
        "deficit hspu": "hspu deficit",
        "hip thrusts": "hip thrust",
        "hip thrust": "hip thrust",
        "face pulls": "face pull",
        "farmer carries": "farmer walk",
        "farmers walk": "farmer walk",
        "hack squats": "hack squat",
        "ab wheel rollout": "ab wheel",
        "arnold press": "press arnold",
        "french press": "press frances",
        "cable crunch": "crunch",
        "hanging leg raise": "elevacion de piernas",
        "lying leg curl": "curl femoral",
        "seated leg curl": "curl femoral",
        "quad extension": "extension de cuadriceps",
        "military press": "press militar",
        "db press": "press mancuernas",
        "db row": "remo mancuerna",
        "bb row": "remo con barra",
        "bb squat": "sentadilla",
        "bb bench": "press banca",
        "bb deadlift": "peso muerto",
        "rdls": "peso muerto rumano",
        "sumo dl": "peso muerto sumo",
        "cable crossover": "cruce de poleas",
        "cable cross over": "cruce de poleas",
        "pec deck": "aperturas",
        "chest press": "press banca",
        "incline press": "press banca inclinada",
        "decline press": "press banca declinado",
        "tricep extension": "extension triceps polea",
        "triceps extension": "extension triceps polea",
        "skullcrushers": "press frances",
        "ez bar curl": "curl barra",
        "concentration curl": "curl mancuernas",
        "side lateral raise": "elevaciones laterales",
        "front raise": "elevaciones frontales",
        "rear delt": "pajaros",
        "reverse fly": "pajaros",
        "good mornings": "buenos dias",
        "upright rows": "remo al menton",
        "inverted rows": "remo invertido",
        "australian pull up": "remo invertido",
        "split squat": "sentadilla bulgara",
        "rear foot elevated split squat": "sentadilla bulgara",
        "rfess": "sentadilla bulgara",
        "walking lunges": "walking lunge",
        "jumping lunge": "jumping lunge",
        "jumping lunges": "jumping lunge",
        "stationary bike": "bici estatica",
        "assault bike": "bici estatica",
        "echo bike": "bici estatica",
        "rower": "remo maquina",
        "erg": "remo maquina",
        "run": "cinta carrera",
        "running": "cinta carrera",
        "jog": "cinta carrera",
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
        "press": "press", "row": "remo", "remo": "row",
        "curl": "curl", "pullup": "dominadas", "pulldown": "jalon",
        "bench": "banca", "banca": "bench",
        // «back» solo = músculo espalda; en «back squat» la frase manda.
        "barbell": "barra", "dumbbell": "mancuerna", "kettlebell": "kettlebell",
    ]

    /// EN (y abreviaturas) → nombre de catálogo, para indexar en cada `Document`.
    private static let englishAliasesByCatalogName: [String: [String]] = {
        var map: [String: Set<String>] = [:]
        func add(_ catalogName: String, _ english: String) {
            let key = normalize(catalogName)
            guard !key.isEmpty else { return }
            let en = normalize(english)
            guard !en.isEmpty, en != key else { return }
            map[key, default: []].insert(en)
        }
        for (en, es) in bilingualPhrases {
            add(es, en)
        }
        for (es, aliases) in CatalogMovilidad.englishAliasesByName {
            for english in aliases { add(es, english) }
        }
        for (en, canonical) in CrossFitGlossary.aliases {
            add(canonical, en)
        }
        // Inversas explícitas de frases ES → EN.
        add("Sentadilla", "back squat")
        add("Sentadilla", "back squats")
        add("Sentadilla", "barbell squat")
        add("Sentadilla frontal", "front squat")
        add("Dominadas", "pull ups")
        add("Dominadas", "pull-ups")
        add("Dominadas", "pull up")
        add("Dominadas supinas", "chin up")
        add("Dominadas supinas", "chin-up")
        add("Dominadas supinas", "chin ups")
        add("Dominadas estrictas", "strict pull up")
        add("Dominadas kipping", "kipping pull up")
        add("Dominadas butterfly", "butterfly pull up")
        add("Dominadas en anillas", "ring pull up")
        add("Chest to bar", "chest to bar")
        add("Walking lunge", "walking lunge")
        add("Walking lunge", "walking lunges")
        add("Front rack lunge", "front rack lunge")
        add("Overhead squat", "overhead squat")
        add("Thruster mancuernas", "db thruster")
        add("Thruster kettlebell", "kb thruster")
        add("Snatch mancuerna", "db snatch")
        add("Snatch kettlebell", "kb snatch")
        add("Clean mancuerna", "db clean")
        add("Clean kettlebell", "kb clean")
        add("Muscle-up barra", "bar muscle up")
        add("Muscle-up anillas", "ring muscle up")
        add("Arrancada colgante", "hang snatch")
        add("Cargada de potencia", "power clean")
        add("Cargada colgante", "hang clean")
        add("Peso muerto", "deadlift")
        add("Peso muerto rumano", "rdl")
        add("Peso muerto sumo", "sumo deadlift")
        add("Press banca", "bench press")
        add("Press banca inclinada", "incline bench press")
        add("Press banca declinado", "decline bench press")
        add("Sentadilla frontal", "front squat")
        add("Sentadilla búlgara", "bulgarian split squat")
        return map.mapValues { Array($0).sorted() }
    }()

    private struct QueryVariant: Equatable {
        var tokens: [String]
        /// Frase para exact/contains (puede conservar «de» del nombre de catálogo).
        var phrase: String
        /// Traducción / alias: no puede superar un match literal del query original.
        var isAlias: Bool
    }

    private static func queryCandidates(_ raw: String) -> [QueryVariant] {
        let original = tokens(from: raw)
        guard !original.isEmpty else { return [] }
        var variants: [QueryVariant] = [
            QueryVariant(tokens: original, phrase: original.joined(separator: " "), isAlias: false)
        ]
        let key = normalize(raw)
        if let alias = SportExerciseNames.englishAlias(forSpanish: raw) ?? CatalogMovilidad.spanishName(forEnglish: raw) ?? bilingualPhrases[key] ?? CrossFitGlossary.aliases[key] {
            let synonym = tokens(from: alias)
            let full = normalize(alias)
            if !synonym.isEmpty {
                let v = QueryVariant(tokens: synonym, phrase: full, isAlias: true)
                if !variants.contains(v) { variants.append(v) }
            }
        }
        let translated = original.map { bilingualTokens[$0] ?? $0 }
        if translated != original {
            let v = QueryVariant(
                tokens: translated,
                phrase: translated.joined(separator: " "),
                isAlias: true
            )
            if !variants.contains(v) { variants.append(v) }
        }
        // «back squat» → quitar token muscular «back» y dejar movimiento traducido.
        if original.contains("back"), original.contains(where: { $0 == "squat" || $0 == "squats" }) {
            let onlySquat = tokens(from: "sentadilla")
            if !onlySquat.isEmpty {
                let v = QueryVariant(
                    tokens: onlySquat,
                    phrase: onlySquat.joined(separator: " "),
                    isAlias: true
                )
                if !variants.contains(v) { variants.append(v) }
            }
        }
        return variants
    }

    private static func searchScore(_ document: Document, variants: [QueryVariant]) -> Int {
        // Una coincidencia literal exacta tiene prioridad sobre una traducción.
        guard let first = variants.first else { return 0 }
        var best = score(document, tokens: first.tokens, phrase: first.phrase)
        if best == Weight.exactName { return best }
        for variant in variants.dropFirst() {
            let translated = score(document, tokens: variant.tokens, phrase: variant.phrase)
            let capped = variant.isAlias
                ? min(translated, Weight.namePrefixPhrase - 1)
                : translated
            best = max(best, capped)
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
        public let disciplineTags: [String]
        public let equipment: String?

        public init(exercise: Exercise) {
            self.id = exercise.id
            self.displayName = exercise.name
            let name = ExerciseSearch.normalize(exercise.name)
            let muscle = ExerciseSearch.normalize(exercise.muscleGroup)
            let sport = ExerciseSearch.normalize(exercise.disciplineTags.joined(separator: " "))
            let equipmentNorm = ExerciseSearch.normalize(exercise.equipment ?? "")
            let target = ExerciseSearch.normalize(exercise.targetMuscle ?? "")
            let body = ExerciseSearch.normalize(exercise.bodyPart ?? "")
            let spanishLabel = SportExerciseNames.spanishAlias(for: exercise.name) ?? ""
            let spanishAlias = ExerciseSearch.normalize(spanishLabel)
            // La búsqueda omite "de/con/del": indexar también el alias sin
            // conectores para que esas frases sigan apareciendo completas.
            let spanishSearchPhrase = ExerciseSearch.tokens(from: spanishLabel).joined(separator: " ")
            // Conservar abreviaturas y variantes EN de los nombres ES antiguos
            // (OCR/pizarra) incluso tras renombrar la entrada principal.
            let aliases = (
                ExerciseSearch.englishAliasesByCatalogName[name]
                ?? ExerciseSearch.englishAliasesByCatalogName[spanishAlias]
                ?? []
            ).joined(separator: " ")
            self.name = name
            self.muscle = muscle
            // Aliases EN en meta: «back squat» encuentra Sentadilla aunque la frase no se traduzca.
            self.meta = [muscle, sport, equipmentNorm, target, body, aliases, spanishAlias, spanishSearchPhrase]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            self.isFavorite = exercise.isFavorite
            self.muscleGroup = exercise.muscleGroup
            self.sportTag = exercise.sportTag
            self.disciplineTags = exercise.disciplineTags
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
                // Cached, diacritic-folded sort key avoids expensive Foundation
                // localized collations for every tie while typing a search query.
                if lhs.doc.name != rhs.doc.name { return lhs.doc.name < rhs.doc.name }
                return lhs.doc.displayName < rhs.doc.displayName
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
            let prefixScore = Weight.namePrefixPhrase - name.count * Weight.lengthPenaltyPerChar
            // Prefix outranks the strongest token/contained-phrase match for
            // ordinary exercise names; skip repeated Unicode scans entirely.
            if prefixScore >= Weight.nameContainsPhrase + Weight.coverageScale {
                return prefixScore
            }
            best = prefixScore
        }
        // Frase completa en nombre o en aliases EN («back squat» en meta de Sentadilla).
        if name.contains(phrase) || meta.contains(phrase) {
            let coverage = Int((Double(phrase.count) / Double(max(name.count, 1))) * Double(Weight.coverageScale))
            let phraseScore = Weight.nameContainsPhrase - name.count * Weight.lengthPenaltyPerChar + coverage
            // Ordered-token score cannot exceed 7_000 + 500. When phrase
            // dominates, computing all token matches is redundant.
            if phraseScore >= Weight.allTokensInNameOrdered + Weight.coverageScale {
                return max(best, phraseScore)
            }
            best = max(best, phraseScore)
        }

        // Tokens sueltos solo contra el nombre (no aliases): evita que
        // «press + banca» pegue en «dumbbell bench press» → Press mancuernas.
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
