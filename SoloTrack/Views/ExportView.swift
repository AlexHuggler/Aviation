import SwiftUI

struct ExportView: View {
    let csvContent: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
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

                // Preview
                ScrollView {
                    Text(csvContent)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

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

                // Copy button
                Button {
                    UIPasteboard.general.string = csvContent
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy to Clipboard")
                    }
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExportView(csvContent: "Date,From,To,Hobbs\n2025-01-15,KSJC,KRHV,1.2")
}
