import SwiftUI
import SwiftData

struct LogbookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    @State private var showingAddFlight = false
    @State private var showingExportSheet = false
    @State private var exportedCSV = ""

    // A3: Save confirmation toast
    @State private var showSavedToast = false

    // A6: Delete-locked alert
    @State private var showLockedDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    emptyState
                } else {
                    flightList
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exportedCSV = CSVExporter.generateCSV(from: flights)
                        showingExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(flights.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddFlight = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddFlight, onDismiss: {
                // A3: Show toast after sheet dismisses (flight was saved)
                showSavedToast = true
            }) {
                AddFlightView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(csvContent: exportedCSV)
            }
            .alert("Cannot Delete", isPresented: $showLockedDeleteAlert) {
                Button("OK") {}
            } message: {
                Text("This flight has a locked CFI signature and cannot be deleted. Void the signature first to enable deletion.")
            }
            // A3: Save confirmation overlay
            .overlay(alignment: .top) {
                if showSavedToast {
                    SavedToastView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showSavedToast = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(duration: 0.4), value: showSavedToast)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Flights Logged", systemImage: "airplane.departure")
        } description: {
            Text("Tap + to log your first flight")
        } actions: {
            Button("Add Flight") {
                showingAddFlight = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Flight List (B3: monthly section headers)

    private var flightList: some View {
        let grouped = groupedByMonth(flights)

        return List {
            ForEach(grouped, id: \.key) { section in
                Section {
                    ForEach(section.flights) { flight in
                        NavigationLink {
                            FlightDetailView(flight: flight)
                        } label: {
                            FlightRow(flight: flight)
                        }
                    }
                    .onDelete { offsets in
                        deleteFlights(from: section.flights, at: offsets)
                    }
                } header: {
                    Text(section.key)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouping

    private struct MonthSection {
        let key: String
        let flights: [FlightLog]
    }

    private func groupedByMonth(_ flights: [FlightLog]) -> [MonthSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: flights) { flight in
            formatter.string(from: flight.date)
        }

        // Maintain reverse-chronological order
        return grouped
            .map { MonthSection(key: $0.key, flights: $0.value) }
            .sorted { section1, section2 in
                guard let d1 = section1.flights.first?.date,
                      let d2 = section2.flights.first?.date else { return false }
                return d1 > d2
            }
    }

    // MARK: - Delete (A6: locked feedback)

    private func deleteFlights(from sectionFlights: [FlightLog], at offsets: IndexSet) {
        for index in offsets {
            let flight = sectionFlights[index]
            if flight.isSignatureLocked {
                showLockedDeleteAlert = true
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                modelContext.delete(flight)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Saved Toast (A3)

private struct SavedToastView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.currencyGreen)
            Text("Flight saved")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.top, 8)
    }
}

// MARK: - Flight Row

struct FlightRow: View {
    let flight: FlightLog

    var body: some View {
        HStack(spacing: 12) {
            // Date circle
            VStack(spacing: 2) {
                Text(flight.date, format: .dateTime.day())
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(flight.date, format: .dateTime.month(.abbreviated))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(flight.formattedRoute)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                HStack(spacing: 6) {
                    ForEach(flight.categoryTags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.skyBlue.opacity(0.15))
                            .foregroundStyle(Color.skyBlue)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(flight.formattedDuration)h")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))

                HStack(spacing: 4) {
                    if flight.hasValidSignature {
                        Image(systemName: "signature")
                            .font(.caption)
                            .foregroundStyle(Color.currencyGreen)
                    }
                    if flight.isSignatureLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flight Detail View (B6: Edit support)

struct FlightDetailView: View {
    let flight: FlightLog

    @State private var showingEditSheet = false
    @State private var showingVoidAlert = false

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

                // Categories
                if !flight.categoryTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(flight.categoryTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.skyBlue.opacity(0.15))
                                .foregroundStyle(Color.skyBlue)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Signature status
                if flight.hasValidSignature {
                    VStack(spacing: 8) {
                        Text("CFI ENDORSEMENT")
                            .sectionHeaderStyle()

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
                                .frame(height: 80)
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
                    .cardStyle()
                }

                // Remarks
                if !flight.remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REMARKS")
                            .sectionHeaderStyle()
                        Text(flight.remarks)
                            .font(.system(.body, design: .rounded))
                    }
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
            // B6: Edit button for unsigned flights
            if flight.isEditable {
                ToolbarItem(placement: .topBarTrailing) {
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
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
    LogbookListView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
