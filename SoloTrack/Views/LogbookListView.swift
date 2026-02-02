import SwiftUI
import SwiftData

struct LogbookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    @State private var showingAddFlight = false
    @State private var showingExportSheet = false
    @State private var exportedCSV = ""

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
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(csvContent: exportedCSV)
            }
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

    // MARK: - Flight List

    private var flightList: some View {
        List {
            ForEach(flights) { flight in
                NavigationLink {
                    FlightDetailView(flight: flight)
                } label: {
                    FlightRow(flight: flight)
                }
            }
            .onDelete(perform: deleteFlights)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteFlights(at offsets: IndexSet) {
        for index in offsets {
            let flight = flights[index]
            if !flight.isSignatureLocked {
                modelContext.delete(flight)
            }
        }
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

                if flight.hasValidSignature {
                    Image(systemName: "signature")
                        .font(.caption)
                        .foregroundStyle(Color.currencyGreen)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flight Detail View

struct FlightDetailView: View {
    let flight: FlightLog

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
