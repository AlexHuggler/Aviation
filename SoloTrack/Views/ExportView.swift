import SwiftUI

struct ExportView: View {
    let csvContent: String
    @Environment(\.dismiss) private var dismiss

    // A8: Copy confirmation state
    @State private var copied = false

    // DL-5: Staggered appearance animation
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTokens.Spacing.xxl) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.skyBlue)

                Text("Export Logbook")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Your logbook data is ready to export as CSV. This format is compatible with spreadsheet applications and most digital logbook services.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // DL-5: Export metadata summary
                HStack(spacing: 12) {
                    let rowCount = max(0, csvContent.components(separatedBy: "\n").count - 2)
                    let fileSize = ByteCountFormatter.string(fromByteCount: Int64(csvContent.utf8.count), countStyle: .file)

                    SummaryChip(value: "\(rowCount)", label: "Flights")
                    SummaryChip(value: fileSize, label: "Size")
                }
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // Preview
                ScrollView {
                    Text(csvContent)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 240)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                // Share button
                ShareLink(
                    item: csvContent,
                    subject: Text("SoloTrack Logbook Export"),
                    message: Text("Flight logbook exported from SoloTrack")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share CSV")
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.skyBlue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                // A8: Copy button with confirmation feedback
                Button {
                    UIPasteboard.general.string = csvContent
                    HapticService.success()
                    withMotionAwareAnimation(.spring(duration: 0.3)) {
                        copied = true
                    }
                } label: {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .contentTransition(.symbolEffect(.replace))
                        Text(copied ? "Copied!" : "Copy to Clipboard")
                            .contentTransition(.numericText())
                    }
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(copied ? Color.currencyGreen.opacity(AppTokens.Opacity.light) : Color(.tertiarySystemFill))
                    .foregroundStyle(copied ? Color.currencyGreen : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .animation(.smooth(duration: 0.3), value: copied)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .onAppear { withMotionAwareAnimation(.easeOut(duration: 0.4)) { appeared = true } }
            // H-5 fix: Structured concurrency auto-cancels on view dismissal
            .task(id: copied) {
                guard copied else { return }
                try? await Task.sleep(for: .seconds(AppTokens.Duration.toast))
                withMotionAwareAnimation(.easeOut(duration: 0.3)) { copied = false }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// DL-5: Export summary chip
private struct SummaryChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.skyBlue)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.skyBlue.opacity(AppTokens.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ExportView(csvContent: "Date,From,To,Hobbs\n2025-01-15,KSJC,KRHV,1.2")
}
