import GymbroDomain
import SwiftUI

/// Silueta frente/espalda sombreada por fatiga / intensidad (verde → rojo).
struct BodyMapView: View {
    /// Series del periodo (barras / ranking). Si no hay `fatigueScores`, colorea por carga relativa.
    var load: [String: Double]
    /// Estímulo retenido (`MuscleMapEngine`) — color por fatiga absoluta.
    var fatigueScores: [String: Double]? = nil
    var selected: String? = nil
    var onSelect: ((String) -> Void)? = nil

    @State private var compiled: CompiledBodyPaths?
    @State private var loadFailed = false

    private var levels: [String: Int] {
        if let fatigueScores {
            return MuscleMapEngine.levels(ofScores: fatigueScores)
        }
        return MuscleLoadEngine.levels(of: load)
    }

    var body: some View {
        Group {
            if let compiled {
                GeometryReader { geo in
                    let half = geo.size.width / 2
                    HStack(spacing: 4) {
                        BodySilhouetteView(
                            view: compiled.front,
                            levels: levels,
                            selected: selected,
                            onSelect: onSelect
                        )
                        .frame(width: half - 2)
                        BodySilhouetteView(
                            view: compiled.back,
                            levels: levels,
                            selected: selected,
                            onSelect: onSelect
                        )
                        .frame(width: half - 2)
                    }
                }
                .frame(height: 220)
            } else if loadFailed {
                Text("No se pudo cargar el mapa corporal.")
                    .font(.system(size: 13))
                    .foregroundStyle(OG.label3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            } else {
                ProgressView()
                    .tint(OG.label3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            }
        }
        .task {
            guard compiled == nil, !loadFailed else { return }
            let result = await CompiledBodyPaths.shared()
            if let result {
                compiled = result
            } else {
                loadFailed = true
            }
        }
    }
}

struct BodyMapLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Recuperado")
                .font(.system(size: 11))
                .foregroundStyle(OG.label3)
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(BodyMapPalette.fill(level: level))
                    .frame(width: 12, height: 12)
            }
            Text("Fatigado")
                .font(.system(size: 11))
                .foregroundStyle(OG.label3)
        }
        .frame(maxWidth: .infinity)
    }
}

enum BodyMapPalette {
    /// 0 gris · 1 verde · 2 amarillo · 3 naranja · 4 rojo (más fatiga / trabajo retenido).
    static func fill(level: Int) -> Color {
        switch level {
        case 1: return OG.accent
        case 2: return OG.yellow
        case 3: return OG.orange
        case 4: return OG.red
        default: return Color(red: 0.23, green: 0.23, blue: 0.24)
        }
    }

    static var silhouette: Color {
        Color(red: 0.23, green: 0.23, blue: 0.24).opacity(0.55)
    }
}

private struct BodySilhouetteView: View {
    let view: CompiledBodyView
    let levels: [String: Int]
    var selected: String?
    var onSelect: ((String) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { context, canvasSize in
                draw(into: &context, size: canvasSize)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { value in
                    guard let onSelect, let hit = hitTest(at: value.location, in: size) else { return }
                    onSelect(hit)
                }
            )
        }
    }

    private func draw(into context: inout GraphicsContext, size: CGSize) {
        let vb = view.viewBox
        guard vb.width > 0, vb.height > 0 else { return }
        let scale = min(size.width / vb.width, size.height / vb.height)
        let dx = (size.width - vb.width * scale) / 2 - vb.minX * scale
        let dy = (size.height - vb.height * scale) / 2 - vb.minY * scale

        var ctx = context
        ctx.translateBy(x: dx, y: dy)
        ctx.scaleBy(x: scale, y: scale)

        for paths in view.inertPaths.values {
            for cg in paths {
                ctx.fill(Path(cg), with: .color(BodyMapPalette.silhouette))
            }
        }
        for slug in MuscleTaxonomy.muscles {
            let level = levels[slug] ?? 0
            let isSel = selected == slug
            for cg in view.musclePaths[slug] ?? [] {
                let p = Path(cg)
                ctx.fill(p, with: .color(BodyMapPalette.fill(level: level)))
                if isSel {
                    ctx.stroke(p, with: .color(.white), lineWidth: 1.5 / scale)
                }
            }
        }
    }

    private func hitTest(at point: CGPoint, in size: CGSize) -> String? {
        let vb = view.viewBox
        guard vb.width > 0, vb.height > 0 else { return nil }
        let scale = min(size.width / vb.width, size.height / vb.height)
        let dx = (size.width - vb.width * scale) / 2 - vb.minX * scale
        let dy = (size.height - vb.height * scale) / 2 - vb.minY * scale
        let p = CGPoint(x: (point.x - dx) / scale, y: (point.y - dy) / scale)
        for slug in MuscleTaxonomy.muscles.reversed() {
            for cg in view.musclePaths[slug] ?? [] where cg.contains(p) {
                return slug
            }
        }
        return nil
    }
}

// MARK: - Compiled asset (parse once, off main)

struct CompiledBodyView: @unchecked Sendable {
    var viewBox: CGRect
    var inertPaths: [String: [CGPath]]
    var musclePaths: [String: [CGPath]]
}

final class CompiledBodyPaths: @unchecked Sendable {
    let front: CompiledBodyView
    let back: CompiledBodyView

    private init(front: CompiledBodyView, back: CompiledBodyView) {
        self.front = front
        self.back = back
    }

    static func shared() async -> CompiledBodyPaths? {
        await BodyPathsLoader.shared.load()
    }

    fileprivate static func compileFromBundle() -> CompiledBodyPaths? {
        guard let url = Bundle.main.url(forResource: "BodyPaths", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let asset = try? JSONDecoder().decode(BodyPathsDTO.self, from: data)
        else { return nil }
        return CompiledBodyPaths(
            front: compile(asset.male.front),
            back: compile(asset.male.back)
        )
    }

    private static func compile(_ view: BodyPathsDTO.ViewPaths) -> CompiledBodyView {
        let parts = view.vb.split(separator: " ").compactMap { Double($0) }
        let vb: CGRect = parts.count == 4
            ? CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
            : .zero
        var inert: [String: [CGPath]] = [:]
        var muscles: [String: [CGPath]] = [:]
        for (slug, strings) in view.p {
            let paths = strings.compactMap { SVGPathParser.path(from: $0) }
            guard !paths.isEmpty else { continue }
            if MuscleTaxonomy.inert.contains(slug) {
                inert[slug] = paths
            } else if MuscleTaxonomy.muscles.contains(slug) {
                muscles[slug] = paths
            }
        }
        return CompiledBodyView(viewBox: vb, inertPaths: inert, musclePaths: muscles)
    }
}

private actor BodyPathsLoader {
    static let shared = BodyPathsLoader()
    /// Subir si cambia el parser (evita caché rota en sesiones de debug).
    private static let cacheVersion = 2
    private var cachedVersion = 0
    private var cache: CompiledBodyPaths?

    func load() async -> CompiledBodyPaths? {
        if let cache, cachedVersion == Self.cacheVersion { return cache }
        let compiled = await Task.detached(priority: .userInitiated) {
            CompiledBodyPaths.compileFromBundle()
        }.value
        cache = compiled
        cachedVersion = Self.cacheVersion
        return compiled
    }
}

private struct BodyPathsDTO: Decodable {
    struct ViewPaths: Decodable {
        var vb: String
        var p: [String: [String]]
    }
    struct SexPaths: Decodable {
        var front: ViewPaths
        var back: ViewPaths
    }
    var male: SexPaths
}

// MARK: - SVG path (M L H V C Q A Z + relative). Arcos `a` son críticos en BodyPaths.

enum SVGPathParser {
    static func path(from d: String) -> CGPath? {
        let tokens = tokenize(d)
        guard !tokens.isEmpty else { return nil }
        let path = CGMutablePath()
        var i = 0
        var current = CGPoint.zero
        var startSub = CGPoint.zero
        var lastCmd: Character = "M"

        func nextNumber() -> Double? {
            guard i < tokens.count, let v = Double(tokens[i]) else { return nil }
            i += 1
            return v
        }

        func nextPoint() -> CGPoint? {
            guard let x = nextNumber(), let y = nextNumber() else { return nil }
            return CGPoint(x: x, y: y)
        }

        func isCommand(_ s: String) -> Bool {
            s.count == 1 && s[s.startIndex].isLetter
        }

        /// Evita bucles infinitos si aparece un comando desconocido.
        func skipNumbers() {
            while i < tokens.count, !isCommand(tokens[i]) {
                i += 1
            }
        }

        while i < tokens.count {
            let cmd: Character
            if isCommand(tokens[i]) {
                cmd = tokens[i][tokens[i].startIndex]
                i += 1
                lastCmd = cmd
            } else {
                cmd = lastCmd == "M" ? "L" : (lastCmd == "m" ? "l" : lastCmd)
            }

            switch cmd {
            case "M", "m":
                guard let p = nextPoint() else { return path }
                let abs = cmd == "M" ? p : CGPoint(x: current.x + p.x, y: current.y + p.y)
                path.move(to: abs)
                current = abs
                startSub = abs
                while i < tokens.count, !isCommand(tokens[i]), let q = nextPoint() {
                    let a = cmd == "M" ? q : CGPoint(x: current.x + q.x, y: current.y + q.y)
                    path.addLine(to: a)
                    current = a
                    lastCmd = cmd == "M" ? "L" : "l"
                }
            case "L", "l":
                while i < tokens.count, !isCommand(tokens[i]), let p = nextPoint() {
                    let a = cmd == "L" ? p : CGPoint(x: current.x + p.x, y: current.y + p.y)
                    path.addLine(to: a)
                    current = a
                }
            case "H", "h":
                while i < tokens.count, !isCommand(tokens[i]), let x = nextNumber() {
                    let a = CGPoint(x: cmd == "H" ? x : current.x + x, y: current.y)
                    path.addLine(to: a)
                    current = a
                }
            case "V", "v":
                while i < tokens.count, !isCommand(tokens[i]), let y = nextNumber() {
                    let a = CGPoint(x: current.x, y: cmd == "V" ? y : current.y + y)
                    path.addLine(to: a)
                    current = a
                }
            case "C", "c":
                while i < tokens.count, !isCommand(tokens[i]),
                      let c1 = nextPoint(), let c2 = nextPoint(), let end = nextPoint() {
                    if cmd == "C" {
                        path.addCurve(to: end, control1: c1, control2: c2)
                        current = end
                    } else {
                        let a1 = CGPoint(x: current.x + c1.x, y: current.y + c1.y)
                        let a2 = CGPoint(x: current.x + c2.x, y: current.y + c2.y)
                        let ae = CGPoint(x: current.x + end.x, y: current.y + end.y)
                        path.addCurve(to: ae, control1: a1, control2: a2)
                        current = ae
                    }
                }
            case "Q", "q":
                while i < tokens.count, !isCommand(tokens[i]),
                      let c = nextPoint(), let end = nextPoint() {
                    if cmd == "Q" {
                        path.addQuadCurve(to: end, control: c)
                        current = end
                    } else {
                        let ac = CGPoint(x: current.x + c.x, y: current.y + c.y)
                        let ae = CGPoint(x: current.x + end.x, y: current.y + end.y)
                        path.addQuadCurve(to: ae, control: ac)
                        current = ae
                    }
                }
            case "A", "a":
                while i < tokens.count, !isCommand(tokens[i]) {
                    guard let rx = nextNumber(), let ry = nextNumber(),
                          let rotation = nextNumber(),
                          let large = nextNumber(), let sweep = nextNumber(),
                          let x = nextNumber(), let y = nextNumber()
                    else { break }
                    let end = cmd == "A"
                        ? CGPoint(x: x, y: y)
                        : CGPoint(x: current.x + x, y: current.y + y)
                    addArc(
                        to: path,
                        from: current,
                        to: end,
                        rx: abs(rx),
                        ry: abs(ry),
                        xAxisRotationDegrees: rotation,
                        largeArc: large != 0,
                        sweep: sweep != 0
                    )
                    current = end
                }
            case "Z", "z":
                path.closeSubpath()
                current = startSub
            default:
                skipNumbers()
            }
        }
        return path
    }

    /// Conversión arco elíptico SVG → cúbicas (spec W3C).
    private static func addArc(
        to path: CGMutablePath,
        from start: CGPoint,
        to end: CGPoint,
        rx: Double,
        ry: Double,
        xAxisRotationDegrees: Double,
        largeArc: Bool,
        sweep: Bool
    ) {
        if rx == 0 || ry == 0 || start == end {
            path.addLine(to: end)
            return
        }

        let phi = xAxisRotationDegrees * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx = (start.x - end.x) / 2
        let dy = (start.y - end.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        var rx2 = rx
        var ry2 = ry
        let lambda = (x1p * x1p) / (rx2 * rx2) + (y1p * y1p) / (ry2 * ry2)
        if lambda > 1 {
            let s = sqrt(lambda)
            rx2 *= s
            ry2 *= s
        }

        let rxSq = rx2 * rx2
        let rySq = ry2 * ry2
        let x1pSq = x1p * x1p
        let y1pSq = y1p * y1p
        var sq = max(0, (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) / (rxSq * y1pSq + rySq * x1pSq))
        sq = sqrt(sq)
        if largeArc == sweep { sq = -sq }
        let cxp = sq * (rx2 * y1p) / ry2
        let cyp = sq * -(ry2 * x1p) / rx2

        let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let n = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            guard n > 0 else { return 0 }
            var a = acos(max(-1, min(1, (ux * vx + uy * vy) / n)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }

        let startVec = CGPoint(x: (x1p - cxp) / rx2, y: (y1p - cyp) / ry2)
        let endVec = CGPoint(x: (-x1p - cxp) / rx2, y: (-y1p - cyp) / ry2)
        let theta1 = angle(1, 0, startVec.x, startVec.y)
        var dTheta = angle(startVec.x, startVec.y, endVec.x, endVec.y)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let segments = max(1, Int(ceil(abs(dTheta) / (.pi / 2))))
        let delta = dTheta / Double(segments)
        let t = (4.0 / 3.0) * tan(delta / 4)

        var angle0 = theta1
        for _ in 0..<segments {
            let angle1 = angle0 + delta
            let cos0 = cos(angle0), sin0 = sin(angle0)
            let cos1 = cos(angle1), sin1 = sin(angle1)

            let e0 = CGPoint(
                x: cx + rx2 * cosPhi * cos0 - ry2 * sinPhi * sin0,
                y: cy + rx2 * sinPhi * cos0 + ry2 * cosPhi * sin0
            )
            let e1 = CGPoint(
                x: cx + rx2 * cosPhi * cos1 - ry2 * sinPhi * sin1,
                y: cy + rx2 * sinPhi * cos1 + ry2 * cosPhi * sin1
            )
            let c1 = CGPoint(
                x: e0.x + t * (-rx2 * cosPhi * sin0 - ry2 * sinPhi * cos0),
                y: e0.y + t * (-rx2 * sinPhi * sin0 + ry2 * cosPhi * cos0)
            )
            let c2 = CGPoint(
                x: e1.x + t * (rx2 * cosPhi * sin1 + ry2 * sinPhi * cos1),
                y: e1.y + t * (rx2 * sinPhi * sin1 - ry2 * cosPhi * cos1)
            )
            path.addCurve(to: e1, control1: c1, control2: c2)
            angle0 = angle1
        }
    }

    /// Tokeniza paths SVG; separa `37.02.75` → `37.02` + `.75` (muy frecuente en BodyPaths).
    private static func tokenize(_ d: String) -> [String] {
        var out: [String] = []
        var num = ""
        var sawDot = false
        var sawExp = false

        func flush() {
            if !num.isEmpty {
                out.append(num)
                num = ""
            }
            sawDot = false
            sawExp = false
        }

        for ch in d {
            if ch.isLetter && ch != "e" && ch != "E" {
                flush()
                out.append(String(ch))
            } else if ch == "," || ch.isWhitespace {
                flush()
            } else if (ch == "e" || ch == "E") && !num.isEmpty {
                num.append(ch)
                sawExp = true
            } else if ch == "-" || ch == "+" {
                // Signo: nuevo número, salvo exponente (`1e-3`).
                if num.isEmpty || sawExp && (num.last == "e" || num.last == "E") {
                    num.append(ch)
                    if sawExp { sawExp = false }
                } else {
                    flush()
                    num.append(ch)
                }
            } else if ch == "." {
                if sawDot {
                    // Segundo punto decimal → empieza otro número (p. ej. 37.02.75).
                    flush()
                    num.append(ch)
                    sawDot = true
                } else {
                    num.append(ch)
                    sawDot = true
                }
            } else if ch.isNumber {
                num.append(ch)
            } else {
                flush()
            }
        }
        flush()
        return out
    }
}
