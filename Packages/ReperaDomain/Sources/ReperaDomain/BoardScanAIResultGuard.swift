import Foundation

/// Keeps optional on-device generative interpretation from overriding a
/// structurally sound local scan with fabricated exercises or lost timing.
/// Only checks consistency: it never rewrites a coach's original prescription.
public enum BoardScanAIResultGuard {
    public static func isConsistent(
        localBlocks: [RoutineBlock],
        proposedBlocks: [RoutineBlock]
    ) -> Bool {
        guard !proposedBlocks.isEmpty else { return false }

        for block in proposedBlocks {
            let names = block.movements.filter { !$0.isRest }.map(\.name)
            if names.contains(where: isInstructionNotExercise) { return false }
            if block.kind == .strength && block.exercises.isEmpty { return false }
            if block.kind == .wod && block.movements.isEmpty { return false }
        }

        // If local OCR identified a block structure, AI must preserve the
        // boundaries and prescriptions. Otherwise the deterministic result wins.
        guard !localBlocks.isEmpty else { return true }
        guard proposedBlocks.count == localBlocks.count else { return false }

        for (local, proposed) in zip(localBlocks, proposedBlocks) {
            guard local.kind == proposed.kind else { return false }
            guard local.wodFormat == proposed.wodFormat else { return false }
            if let cap = local.timeCapMinutes, proposed.timeCapMinutes != cap {
                return false
            }
            if local.rounds != proposed.rounds { return false }
            if local.wodFormat == .emom,
               local.emomIntervalSeconds != proposed.emomIntervalSeconds {
                return false
            }
            if local.kind == .strength {
                if local.exercises.count != proposed.exercises.count { return false }
            } else {
                let l = local.movements.filter { !$0.isRest }.count
                let p = proposed.movements.filter { !$0.isRest }.count
                if l != p { return false }
            }
        }
        return true
    }

    private static func isInstructionNotExercise(_ name: String) -> Bool {
        let upper = name.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if ["OF", "WARM UP", "WARMUP", "CALENTAMIENTO", "METCON",
            "STRENGTH", "ACCESSORY WORK", "BUY IN", "BUY OUT",
            "VIDEO", "VER VIDEO"].contains(upper) { return true }
        return upper.hasPrefix("HTTP:") || upper.hasPrefix("HTTPS:") ||
               upper.hasPrefix("WWW.") || upper.hasPrefix("▶") ||
               upper.hasPrefix("►") || upper.contains("YOUTUBE.COM") ||
               upper.contains("YOUTU.BE")
    }
}
