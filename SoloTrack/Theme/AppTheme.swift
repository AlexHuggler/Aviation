import SwiftUI

// MARK: - Aviation Color Palette

extension Color {
    // Currency traffic light
    static let currencyGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let cautionYellow = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let warningRed = Color(red: 0.91, green: 0.22, blue: 0.22)

    // Aviation theme
    static let skyBlue = Color(red: 0.40, green: 0.73, blue: 0.94)
    static let cockpitDark = Color(red: 0.09, green: 0.09, blue: 0.13)
    static let instrumentPanel = Color(red: 0.15, green: 0.15, blue: 0.20)
    static let altitudeGold = Color(red: 0.85, green: 0.75, blue: 0.40)
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

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}
