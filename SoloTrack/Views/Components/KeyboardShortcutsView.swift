import SwiftUI

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTokens.Spacing.xxl) {
                    shortcutSection(title: "NAVIGATION", shortcuts: [
                        ShortcutItem(keys: "\u{2318}1", description: "Dashboard"),
                        ShortcutItem(keys: "\u{2318}2", description: "Progress"),
                        ShortcutItem(keys: "\u{2318}3", description: "Logbook"),
                    ])

                    shortcutSection(title: "ACTIONS", shortcuts: [
                        ShortcutItem(keys: "\u{2318}N", description: "New Flight"),
                        ShortcutItem(keys: "\u{2318}S", description: "Save Flight"),
                        ShortcutItem(keys: "\u{2318}E", description: "Export Logbook"),
                    ])

                    shortcutSection(title: "FORM NAVIGATION", shortcuts: [
                        ShortcutItem(keys: "Next", description: "Advance to next field"),
                        ShortcutItem(keys: "Previous", description: "Return to previous field"),
                        ShortcutItem(keys: "Done", description: "Dismiss keyboard"),
                    ])
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func shortcutSection(title: String, shortcuts: [ShortcutItem]) -> some View {
        VStack(alignment: .leading, spacing: AppTokens.Spacing.lg) {
            Text(title)
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(shortcuts) { shortcut in
                    HStack {
                        Text(shortcut.description)
                            .font(.system(.body, design: .rounded))

                        Spacer()

                        Text(shortcut.keys)
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                            .padding(.horizontal, AppTokens.Spacing.md)
                            .padding(.vertical, AppTokens.Spacing.xs)
                            .background(Color.skyBlue.opacity(AppTokens.Opacity.subtle))
                            .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.sm))
                    }
                    .padding(.vertical, AppTokens.Spacing.md)

                    if shortcut.id != shortcuts.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
            .cardStyle()
        }
    }
}

private struct ShortcutItem: Identifiable {
    let id = UUID()
    let keys: String
    let description: String
}

#Preview {
    KeyboardShortcutsView()
}
