import SwiftUI

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

// MARK: - Aviation Color Palette

extension Color {
    // Currency traffic light
    static let currencyGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let cautionYellow = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let warningRed = Color(red: 0.91, green: 0.22, blue: 0.22)

    // Aviation theme
    static let skyBlue = Color(red: 0.40, green: 0.73, blue: 0.94)
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
