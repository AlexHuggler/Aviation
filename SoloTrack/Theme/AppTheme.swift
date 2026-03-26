import SwiftUI
import UIKit

// MARK: - PX-4: Design Tokens

enum AppTokens {
    // Spacing scale
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let section: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let jumbo: CGFloat = 40
    }

    // Corner radius scale
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
        static let xl: CGFloat = 14
        static let card: CGFloat = 16
    }

    // Animation durations
    enum Duration {
        static let quick: Double = 0.3
        static let normal: Double = 0.4
        static let slow: Double = 0.6
        static let ring: Double = 0.8
        static let toast: Double = 2.0
        static let celebration: Double = 1.2
    }

    // Opacity scale
    enum Opacity {
        static let subtle: Double = 0.08
        static let light: Double = 0.15
        static let medium: Double = 0.3
        static let strong: Double = 0.6
    }

    // Sizing
    enum Size {
        static let dateCircle: CGFloat = 44
        static let progressRing: CGFloat = 160
        static let strokeWidth: CGFloat = 12
        static let signatureHeight: CGFloat = 80
        static let inputWidth: CGFloat = 80
        static let onboardingIcon: CGFloat = 56
        static let coachMarkMaxWidth: CGFloat = 340
    }

    // Onboarding-specific
    enum Onboarding {
        static let sheetDetent: CGFloat = 0.92
        static let cardInset: CGFloat = 24
        static let stepTransitionDuration: Double = 0.5
        static let autoOpenDelay: Double = 0.5
    }
}

// MARK: - FR-6: ScaledMetric Tokens for Dynamic Type

struct ScaledTokens {
    @ScaledMetric(relativeTo: .body) var dateCircle: CGFloat = 44
    @ScaledMetric(relativeTo: .body) var progressRing: CGFloat = 160
    @ScaledMetric(relativeTo: .body) var strokeWidth: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var signatureHeight: CGFloat = 80
    @ScaledMetric(relativeTo: .body) var inputWidth: CGFloat = 80
    @ScaledMetric(relativeTo: .title) var onboardingIcon: CGFloat = 56
    @ScaledMetric(relativeTo: .body) var coachMarkMaxWidth: CGFloat = 340
    @ScaledMetric(relativeTo: .body) var exportIcon: CGFloat = 48
    @ScaledMetric(relativeTo: .body) var featureIconMin: CGFloat = 28
    @ScaledMetric(relativeTo: .body) var featureIconIdeal: CGFloat = 32
    @ScaledMetric(relativeTo: .body) var featureIconMax: CGFloat = 40
    @ScaledMetric(relativeTo: .title) var currencyIcon: CGFloat = 32
    @ScaledMetric(relativeTo: .title) var airplaneIcon: CGFloat = 64
    @ScaledMetric(relativeTo: .body) var onboardingRowIcon: CGFloat = 28
    @ScaledMetric(relativeTo: .body) var welcomeIcon: CGFloat = 52
    @ScaledMetric(relativeTo: .body) var cloudLarge: CGFloat = 28
    @ScaledMetric(relativeTo: .body) var cloudSmall: CGFloat = 20
    @ScaledMetric(relativeTo: .body) var csvPreviewMaxHeight: CGFloat = 240
}

// MARK: - Aviation Color Palette (Dark Mode Aware)

extension Color {
    // Currency traffic light — slightly brighter in dark mode for contrast
    static let currencyGreen = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.25, green: 0.88, blue: 0.52, alpha: 1)
                : UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
        }
    )
    static let cautionYellow = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.82, blue: 0.15, alpha: 1)
                : UIColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1)
        }
    )
    static let warningRed = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.96, green: 0.30, blue: 0.30, alpha: 1)
                : UIColor(red: 0.91, green: 0.22, blue: 0.22, alpha: 1)
        }
    )

    // Aviation theme — slightly lighter in dark mode
    static let skyBlue = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.47, green: 0.78, blue: 0.97, alpha: 1)
                : UIColor(red: 0.40, green: 0.73, blue: 0.94, alpha: 1)
        }
    )

    // Category badge palette
    static let badgeDual = Color.purple
    static let badgeXC = Color.orange
    static let badgeInst = Color.gray
}

// MARK: - Currency State Colors

extension CurrencyState {
    var color: Color {
        switch self {
        case .valid: return .currencyGreen
        case .caution: return .cautionYellow
        case .expired: return .warningRed
        }
    }

    var iconName: String {
        switch self {
        case .valid: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.shield.fill"
        }
    }
}

// MARK: - Haptic Service (M-8 fix: centralized, pre-allocated generators)

enum HapticService {
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    private static let impact = UIImpactFeedbackGenerator(style: .light)

    static func success() { notification.notificationOccurred(.success) }
    static func error() { notification.notificationOccurred(.error) }
    static func warning() { notification.notificationOccurred(.warning) }
    static func selectionChanged() { selection.selectionChanged() }
    static func lightImpact() { impact.impactOccurred() }

    // DL-2: Compound haptic patterns for premium feel
    // Note: try? on Task.sleep is intentional here — these are fire-and-forget
    // haptic delays where cancellation simply means the haptic sequence stops early.
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    static func saveConfirmation() {
        lightImpact()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            success()
        }
    }

    static func deleteConfirmation() {
        warning()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            lightImpact()
        }
    }

    static func milestoneAchieved() {
        success()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            success()
            try? await Task.sleep(for: .milliseconds(200))
            mediumImpact.impactOccurred()
        }
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

// MARK: - FR-6: Reduced Motion Modifier

struct ReducedMotionAware: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let value: AnyHashable

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }

    /// FR-6: Applies animation only when reduced motion is not enabled
    func motionAwareAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ReducedMotionAware(animation: animation, value: AnyHashable(value)))
    }
}

// MARK: - Motion-Aware withAnimation Wrapper

/// Wraps `withAnimation` to respect the user's Reduce Motion accessibility setting.
/// Use this instead of `withAnimation(...)` for all imperative animation triggers.
func withMotionAwareAnimation<Result>(_ animation: Animation = .default, _ body: () throws -> Result) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    }
    return try withAnimation(animation, body)
}
