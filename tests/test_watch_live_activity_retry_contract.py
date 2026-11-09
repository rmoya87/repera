"""Guard against losing Watch Live Activity after a failed ActivityKit request.

These source-level checks need paired-device runtime verification as well.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WatchLiveActivityRetryTests(unittest.TestCase):
    def test_missing_activity_with_cached_state_is_retryable(self):
        src = (ROOT / "Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift").read_text()
        block = src.split("private func upsert(", 1)[1].split("private func finish(", 1)[0]
        self.assertIn("ActivityAuthorizationInfo().areActivitiesEnabled", block)
        self.assertIn("!closedSessionIDs.contains(id)", block)
        self.assertIn("Activity<TrainingActivityAttributes>.activities.contains", block)
        self.assertIn("previous == state, exists", block)
        self.assertNotIn("if let previous = latestStates[id], previous == state { return }", block)
        self.assertIn("latestStates.removeValue(forKey: id)", block)
        self.assertIn("if latestStates[id] == state", block)
        self.assertIn("pushType: nil", block)
        self.assertIn("await activity.update(", block)
        self.assertIn("return activityExists(id)", block)

    def test_failed_request_does_not_consume_the_same_watch_snapshot(self):
        src = (ROOT / "Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift").read_text()
        watch = src.split("func updateWatchOwned(", 1)[1].split("func finishWatchOwned(", 1)[0]
        self.assertIn("let previousMark = watchMarks[id]", watch)
        self.assertLess(watch.index("await upsert("), watch.index("rollbackWatchDeliveryMark("))
        rollback = src.split("func rollbackWatchDeliveryMark(", 1)[1].split(
            "func retainWatchOwnedUntilSaved(", 1
        )[0]
        self.assertIn("!current.closed", rollback)
        self.assertIn("current.capture == capture", rollback)
        self.assertIn("watchMarks.removeValue(forKey: id)", rollback)
        self.assertIn("persistWatchMarks()", rollback)

    def test_watch_path_still_uses_same_uuid_and_owner(self):
        src = (ROOT / "Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift").read_text()
        self.assertIn('let id = "watch:" + snapshot.id.uuidString', src)
        self.assertIn("guard mayAcceptWatchOwned(snapshot) else { return }", src)
        self.assertIn("await upsert(id: id, isPlanned: false, state: state)", src)
        self.assertIn("func finishWatchOwned(sessionID: UUID, saved: Bool)", src)
        self.assertIn("func retainWatchOwnedUntilSaved(sessionID: UUID)", src)


if __name__ == "__main__":
    unittest.main()
