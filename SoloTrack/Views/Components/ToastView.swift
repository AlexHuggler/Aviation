import SwiftUI

// MARK: - Reusable Toast Component

struct ToastView: View {
    let icon: String
    let message: String
    var iconColor: Color = .currencyGreen
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppTokens.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            if let actionLabel, let onAction {
                Button(actionLabel) {
                    onAction()
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.skyBlue)
            }
        }
        .padding(.horizontal, AppTokens.Spacing.xl)
        .padding(.vertical, AppTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(AppTokens.Opacity.light), radius: 8, y: 4)
        .padding(.top, AppTokens.Spacing.md)
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastView(icon: "checkmark.circle.fill", message: "Flight saved")
        ToastView(icon: "checkmark.circle.fill", message: "Saved! (3)", iconColor: .currencyGreen)
        ToastView(icon: "trash", message: "Flight deleted", iconColor: .warningRed, actionLabel: "Undo", onAction: {})
    }
}
