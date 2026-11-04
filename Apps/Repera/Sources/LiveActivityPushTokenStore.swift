@preconcurrency import ActivityKit
import Foundation
import os

/// Captures ActivityKit push tokens so a trusted backend can update / push-to-start
/// Live Activities without opening the UI. Tokens stay on-device until a push path exists.
@MainActor
enum LiveActivityPushTokenStore {
    private static let logger = Logger(subsystem: "com.app.repera", category: "LiveActivityPush")
    private static let tokenKey = "repera.liveActivity.pushToken.v1"
    private static var observersStarted = false

    static var latestTokenHex: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    static func startObservingIfNeeded() {
        guard !observersStarted else { return }
        observersStarted = true
        Task {
            for await data in Activity<TrainingActivityAttributes>.pushToStartTokenUpdates {
                persist(data)
            }
        }
        Task {
            for await activity in Activity<TrainingActivityAttributes>.activityUpdates {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        persist(tokenData)
                    }
                }
            }
        }
    }

    private static func persist(_ data: Data) {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: tokenKey)
        logger.debug("ActivityKit push token updated (\(hex.count, privacy: .public) hex chars)")
    }
}
