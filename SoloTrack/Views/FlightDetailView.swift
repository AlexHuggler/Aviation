import SwiftUI

// MARK: - Flight Detail View (B6: Edit support, B2: Duplicate)

struct FlightDetailView: View {
    let flight: FlightLog
    var onDuplicate: ((FlightLog) -> Void)?

    @State private var showingEditSheet = false
    @State private var showingVoidAlert = false

    // DL-7: Progressive disclosure state
    @State private var showSignatureDetail = true
    @State private var showRemarksDetail = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Route header
                VStack(spacing: 4) {
                    Text(flight.formattedRoute)
                        .font(.system(.title, design: .rounded, weight: .bold))

                    Text(flight.date, format: .dateTime.month(.wide).day().year())
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Times
                HStack(spacing: 24) {
                    DetailItem(label: "Hobbs", value: String(format: "%.1f", flight.durationHobbs))
                    DetailItem(label: "Tach", value: String(format: "%.1f", flight.durationTach))
                }
                .cardStyle()

                // Landings
                HStack(spacing: 24) {
                    DetailItem(label: "Day Landings", value: "\(flight.landingsDay)")
                    DetailItem(label: "Night FS", value: "\(flight.landingsNightFullStop)")
                }
                .cardStyle()

                // Categories — D4: using shared CategoryBadge
                if !flight.categoryTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(flight.categoryTags, id: \.self) { tag in
                            CategoryBadge(tag: tag)
                        }
                    }
                }

                // Signature status — DL-7: Progressive disclosure
                if flight.hasValidSignature {
                    DisclosureGroup(isExpanded: $showSignatureDetail) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "signature")
                                    .foregroundStyle(Color.currencyGreen)
                                Text("Signed by CFI #\(flight.cfiNumber)")
                                    .font(.system(.subheadline, design: .rounded))
                                if flight.isSignatureLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let signatureData = flight.instructorSignature,
                               let uiImage = UIImage(data: signatureData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: AppTokens.Size.signatureHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            if let signDate = flight.signatureDate {
                                Text("Signed on \(signDate, format: .dateTime.month(.wide).day().year())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Void signature button
                            if flight.isSignatureLocked {
                                Button(role: .destructive) {
                                    showingVoidAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.shield")
                                        Text("Void Signature")
                                    }
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                }
                                .padding(.top, 4)
                            }
                        }
                    } label: {
                        HStack {
                            Text("CFI ENDORSEMENT")
                                .sectionHeaderStyle()
                            Spacer()
                            if let signDate = flight.signatureDate {
                                Text("Signed \(signDate, format: .dateTime.month(.abbreviated).day().year())")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(Color.skyBlue)
                    .cardStyle()
                }

                // Remarks — DL-7: Progressive disclosure
                if !flight.remarks.isEmpty {
                    DisclosureGroup(isExpanded: $showRemarksDetail) {
                        Text(flight.remarks)
                            .font(.system(.body, design: .rounded))
                    } label: {
                        Text("REMARKS")
                            .sectionHeaderStyle()
                    }
                    .tint(Color.skyBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flight Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // B2: Duplicate button
                if let onDuplicate {
                    Button {
                        onDuplicate(flight)
                        HapticService.success()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
                // B6: Edit button for unsigned flights
                if flight.isEditable {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddFlightView(editingFlight: flight)
        }
        .alert("Void Signature?", isPresented: $showingVoidAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Void", role: .destructive) {
                flight.voidSignature()
                HapticService.warning()
            }
        } message: {
            Text("This will remove the CFI endorsement and unlock the flight for editing. The instructor will need to re-sign.")
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FlightDetailView(flight: FlightLog())
        .modelContainer(for: [FlightLog.self, FlightTemplate.self], inMemory: true)
}
