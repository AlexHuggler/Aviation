import UIKit

// M-1: Centralized haptic feedback — avoids re-instantiating generators on every trigger.
// Per Apple docs, generators should be prepared in advance for lower-latency feedback.
enum Haptic {
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func error() {
        notification.notificationOccurred(.error)
    }

    static func warning() {
        notification.notificationOccurred(.warning)
    }

    static func selection() {
        selection.selectionChanged()
    }

    /// Call before a known haptic trigger to reduce latency (e.g., on button highlight)
    static func prepare() {
        notification.prepare()
    }
}
