@preconcurrency import ActivityKit
import Foundation
import os

/// Captures ActivityKit push-to-start and per-activity update tokens so a trusted
/// backend can start/update Live Activities while the iPhone is suspended.
/// Tokens stay on-device only: `register_push_device` currently allows `ios`/`android`
/// alert tokens, not ActivityKit PTS tokens. Uploading them requires a future
/// migration + Edge APNs ActivityKit sender (not deployed from this change).
@MainActor
enum LiveActivityPushTokenStore {
    private static let logger = Logger(subsystem: "com.app.repera", category: "LiveActivityPush")
    private static let updateTokenKey = "repera.liveActivity.pushToken.v1"
    private static let pushToStartTokenKey = "repera.liveActivity.pushToStartToken.v1"
    private static var observersStarted = false

    static var latestTokenHex: String? {
        UserDefaults.standard.string(forKey: updateTokenKey)
    }

    static var latestPushToStartTokenHex: String? {
        UserDefaults.standard.string(forKey: pushToStartTokenKey)
    }

    static func startObservingIfNeeded() {
        guard !observersStarted else { return }
        observersStarted = true
        Task {
            for await data in Activity<TrainingActivityAttributes>.pushToStartTokenUpdates {
                persistPushToStart(data)
            }
        }
        Task {
            for await data in Activity<RestActivityAttributes>.pushToStartTokenUpdates {
                persistPushToStart(data)
            }
        }
        Task {
            for await activity in Activity<TrainingActivityAttributes>.activityUpdates {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        persistUpdateToken(tokenData)
                    }
                }
            }
        }
        Task {
            for await activity in Activity<RestActivityAttributes>.activityUpdates {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        persistUpdateToken(tokenData)
                    }
                }
            }
        }
    }

    private static func persistUpdateToken(_ data: Data) {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: updateTokenKey)
        logger.debug("ActivityKit update token updated (\(hex.count, privacy: .public) hex chars)")
    }

    private static func persistPushToStart(_ data: Data) {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: pushToStartTokenKey)
        logger.debug("ActivityKit push-to-start token updated (\(hex.count, privacy: .public) hex chars)")
    }
}
