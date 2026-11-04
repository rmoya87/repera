import Foundation

/// Límites del transporte WatchConnectivity compartidos por iPhone y Apple Watch.
/// Se comprueban ANTES de `JSONDecoder` para no decodificar payloads anómalos.
public enum WatchTransportLimits {
    /// Datos embebidos en applicationContext / userInfo / message.
    public static let maxPayloadBytes = 1_000_000
    /// Sesión terminada enviada como fichero (`WCSession.transferFile`).
    public static let maxFileBytes = 8_000_000
    /// Por encima de este tamaño la sesión terminada viaja como fichero y el
    /// userInfo lleva la misma sesión sin ruta (compatibilidad con builds antiguas).
    public static let inlineFinishedSessionBytes = 48_000

    public static func accepts(_ data: Data) -> Bool {
        data.count <= maxPayloadBytes
    }

    public static func acceptsFile(byteCount: Int) -> Bool {
        byteCount > 0 && byteCount <= maxFileBytes
    }
}

/// Simplificación de rutas GPS del reloj antes de enviarlas o persistirlas.
/// Conserva extremos, orden e IDs originales; nunca inventa puntos.
public enum WatchRouteSimplifier {
    /// Tramos independientes para acotar el peor caso O(n²) de Douglas-Peucker
    /// (p. ej. GPS en zigzag) en el procesador del reloj.
    static let chunkSize = 1_000

    /// Douglas-Peucker por tramos con tolerancia en metros; si aún supera
    /// `maxPoints`, muestrea uniformemente conservando los extremos.
    public static func simplify(
        _ points: [WorkoutRoutePoint],
        toleranceMeters: Double = 3,
        maxPoints: Int = 4_000
    ) -> [WorkoutRoutePoint] {
        let limit = max(2, maxPoints)
        guard points.count > 2 else { return points }
        let tolerance = max(0, toleranceMeters)
        var result: [WorkoutRoutePoint] = []
        result.reserveCapacity(min(points.count, limit))
        var start = 0
        while start < points.count - 1 {
            let end = min(points.count - 1, start + chunkSize)
            let chunk = douglasPeucker(Array(points[start...end]), tolerance: tolerance)
            result.append(contentsOf: start == 0 ? chunk[...] : chunk.dropFirst())
            start = end
        }
        return result.count > limit ? uniform(result, maxPoints: limit) : result
    }

    static func douglasPeucker(_ points: [WorkoutRoutePoint], tolerance: Double) -> [WorkoutRoutePoint] {
        guard points.count > 2 else { return points }
        // Proyección equirectangular local (suficiente para tramos de pocos km).
        let metersPerDegree = 111_320.0
        let originLat = points[0].latitude
        let originLon = points[0].longitude
        let cosLat = cos(originLat * .pi / 180)
        let xs = points.map { ($0.longitude - originLon) * metersPerDegree * cosLat }
        let ys = points.map { ($0.latitude - originLat) * metersPerDegree }
        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true
        var stack: [(Int, Int)] = [(0, points.count - 1)]
        while let (start, end) = stack.popLast() {
            guard end > start + 1 else { continue }
            let ax = xs[start], ay = ys[start]
            let bx = xs[end] - ax, by = ys[end] - ay
            let lengthSquared = bx * bx + by * by
            var maxDistance = 0.0
            var index = start
            for i in (start + 1)..<end {
                let px = xs[i] - ax, py = ys[i] - ay
                let t = lengthSquared > 0 ? max(0, min(1, (px * bx + py * by) / lengthSquared)) : 0
                let dx = px - t * bx, dy = py - t * by
                let d = dx * dx + dy * dy
                if d > maxDistance {
                    maxDistance = d
                    index = i
                }
            }
            maxDistance = maxDistance.squareRoot()
            if maxDistance > tolerance {
                keep[index] = true
                stack.append((start, index))
                stack.append((index, end))
            }
        }
        return points.indices.compactMap { keep[$0] ? points[$0] : nil }
    }

    static func uniform(_ points: [WorkoutRoutePoint], maxPoints: Int) -> [WorkoutRoutePoint] {
        guard points.count > maxPoints, maxPoints >= 2 else { return points }
        let step = Double(points.count - 1) / Double(maxPoints - 1)
        return (0..<maxPoints).map { points[min(points.count - 1, Int((Double($0) * step).rounded()))] }
    }
}

/// Cuándo puede el reloj retirar de su cola una sesión terminada tras el ACK del iPhone.
public enum WatchOutboxAckPolicy {
    /// - Parameters:
    ///   - localHealthKitUUID: HKWorkout que conoce el reloj para esa sesión (nil si
    ///     la sesión ya no está en el resumen local o Salud no devolvió UUID).
    ///   - acknowledgedHealthKitUUID: HKWorkout que el iPhone tiene persistido.
    ///   - awaitingHealthSave: Salud todavía está guardando una revisión más rica.
    public static func shouldClear(
        localHealthKitUUID: UUID?,
        acknowledgedHealthKitUUID: UUID?,
        awaitingHealthSave: Bool
    ) -> Bool {
        if awaitingHealthSave { return false }
        guard localHealthKitUUID != nil else { return true }
        // Solo se reenvía si el iPhone persistió una revisión sin el vínculo de Salud;
        // un UUID distinto (p. ej. un HKWorkout externo ya enlazado) no debe reenviarse sin fin.
        return acknowledgedHealthKitUUID != nil
    }
}
