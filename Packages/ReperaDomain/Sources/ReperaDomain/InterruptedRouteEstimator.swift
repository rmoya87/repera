import Foundation

/// Recuperación prudente de un hueco GPS tras un cierre imprevisto. Solo
/// interpolación EN LÍNEA RECTA, nunca un recorrido real ni una medida Salud.
public enum InterruptedRouteEstimator {
    public struct Estimate: Sendable {
        public var points: [WorkoutRoutePoint]
        public var distanceMeters: Double
        public var missingSeconds: TimeInterval
    }

    public static let maximumGapSeconds: TimeInterval = 30 * 60

    public static func bridge(
        from last: WorkoutRoutePoint,
        to first: WorkoutRoutePoint,
        maximumSpeedMps: Double
    ) -> Estimate? {
        let seconds = first.recordedAt.timeIntervalSince(last.recordedAt)
        guard seconds > 30, seconds <= maximumGapSeconds,
              last.latitude.isFinite, last.longitude.isFinite,
              first.latitude.isFinite, first.longitude.isFinite,
              (-90...90).contains(last.latitude), (-90...90).contains(first.latitude),
              (-180...180).contains(last.longitude), (-180...180).contains(first.longitude),
              maximumSpeedMps.isFinite, maximumSpeedMps > 0 else { return nil }

        let lat1 = last.latitude * .pi / 180
        let lat2 = first.latitude * .pi / 180
        let latDiff = (first.latitude - last.latitude) * .pi / 180
        let lonDiff = (first.longitude - last.longitude) * .pi / 180
        let half = pow(sin(latDiff / 2), 2)
            + cos(lat1) * cos(lat2) * pow(sin(lonDiff / 2), 2)
        let meters = 6_371_000.0 * 2 * asin(min(1, sqrt(max(0, half))))
        guard meters.isFinite, meters >= 5, meters / seconds <= maximumSpeedMps else {
            return nil
        }

        // Equiespaciados en el tiempo. Solo internos; extremos son lecturas reales.
        let intervals = max(2, min(120, Int(ceil(seconds / 15))))
        let speed = meters / seconds
        let points = (1..<intervals).map { index -> WorkoutRoutePoint in
            let fraction = Double(index) / Double(intervals)
            return WorkoutRoutePoint(
                id: 0,
                latitude: last.latitude + (first.latitude - last.latitude) * fraction,
                longitude: last.longitude + (first.longitude - last.longitude) * fraction,
                recordedAt: last.recordedAt.addingTimeInterval(seconds * fraction),
                speedMps: speed,
                isEstimated: true
            )
        }
        return Estimate(points: points, distanceMeters: meters, missingSeconds: seconds)
    }
}
