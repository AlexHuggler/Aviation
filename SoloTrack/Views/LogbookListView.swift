import SwiftUI
import SwiftData

struct LogbookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    @State private var showingAddFlight = false
    @State private var showingExportSheet = false
    @State private var exportedCSV = ""

    // A2: Save confirmation toast — only set via onSave callback
    @State private var showSavedToast = false

    // A6: Delete-locked alert
    @State private var showLockedDeleteAlert = false

    // A1: Search & filter
    @State private var searchText = ""

    // B2: Duplicate flight
    @State private var duplicatingFlight: FlightLog?

    // D2: Static date formatter (avoid re-allocation on every group call)
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // A1: Filtered flights based on search text
    private var filteredFlights: [FlightLog] {
        guard !searchText.isEmpty else { return flights }
        let query = searchText.lowercased()
        return flights.filter { flight in
            flight.routeFrom.lowercased().contains(query)
            || flight.routeTo.lowercased().contains(query)
            || flight.formattedRoute.lowercased().contains(query)
            || flight.categoryTags.contains { $0.lowercased().contains(query) }
            || flight.remarks.lowercased().contains(query)
            || flight.cfiNumber.lowercased().contains(query)
        }
    }

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
            // A2: Fixed — toast only fires via onSave callback, not onDismiss
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView(onSave: {
                    showSavedToast = true
                })
            }
            // B2: Duplicate sheet
            .sheet(item: $duplicatingFlight) { flight in
                AddFlightView(
                    editingFlight: nil,
                    onSave: { showSavedToast = true }
                )
                .onAppear {
                    // The duplicate pre-fills via a new flight with today's date
                    // handled by creating a temporary flight and passing values
                }
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + AppTokens.Duration.toast) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showSavedToast = false
                                }
                            }
                        }
                }
            }
            .motionAwareAnimation(.spring(duration: 0.4), value: showSavedToast)
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

    // MARK: - Flight List (A1: searchable, B3: summary header)

    private var flightList: some View {
        let grouped = groupedByMonth(filteredFlights)

        return List {
            // B3: Logbook summary header
            logbookSummarySection

            ForEach(grouped, id: \.key) { section in
                Section {
                    ForEach(section.flights) { flight in
                        NavigationLink {
                            FlightDetailView(flight: flight, onDuplicate: { duplicatedFlight in
                                duplicatingFlight = duplicatedFlight
                            })
                        } label: {
                            FlightRow(flight: flight)
                        }
                        // PX-2: Swipe actions for quick access
                        .swipeActions(edge: .leading) {
                            Button {
                                duplicateFlight(flight)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(Color.skyBlue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if flight.isSignatureLocked {
                                    showLockedDeleteAlert = true
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                } else {
                                    modelContext.delete(flight)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        // B2: Context menu kept for discoverability
                        .contextMenu {
                            Button {
                                duplicateFlight(flight)
                            } label: {
                                Label("Duplicate Flight", systemImage: "doc.on.doc")
                            }
                        }
                    }
                } header: {
                    Text(section.key)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        // A1: Search bar
        .searchable(text: $searchText, prompt: "Route, category, or remarks")
        // A1: Empty search results
        .overlay {
            if !searchText.isEmpty && filteredFlights.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    // MARK: - B3: Logbook Summary

    private var logbookSummarySection: some View {
        let totalHours = flights.reduce(0.0) { $0 + $1.durationHobbs }
        let totalFlights = flights.count

        // Hours this month
        let now = Date.now
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthHours = flights
            .filter { $0.date >= startOfMonth }
            .reduce(0.0) { $0 + $1.durationHobbs }

        return Section {
            HStack {
                SummaryPill(value: String(format: "%.1f", totalHours), label: "Total Hrs")
                SummaryPill(value: "\(totalFlights)", label: "Flights")
                SummaryPill(value: String(format: "%.1f", monthHours), label: "This Month")
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }

    // MARK: - Grouping (D2: static formatter)

    private struct MonthSection {
        let key: String
        let flights: [FlightLog]
    }

    private func groupedByMonth(_ flights: [FlightLog]) -> [MonthSection] {
        let grouped = Dictionary(grouping: flights) { flight in
            Self.monthFormatter.string(from: flight.date)
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

    // MARK: - B2: Duplicate Flight

    private func duplicateFlight(_ source: FlightLog) {
        let newFlight = FlightLog(
            date: .now,
            durationHobbs: source.durationHobbs,
            durationTach: source.durationTach,
            routeFrom: source.routeFrom,
            routeTo: source.routeTo,
            landingsDay: source.landingsDay,
            landingsNightFullStop: source.landingsNightFullStop,
            isSolo: source.isSolo,
            isDualReceived: source.isDualReceived,
            isCrossCountry: source.isCrossCountry,
            isSimulatedInstrument: source.isSimulatedInstrument,
            remarks: source.remarks
        )
        modelContext.insert(newFlight)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showSavedToast = true
    }
}

// MARK: - B3: Summary Pill

private struct SummaryPill: View {
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
            .frame(width: AppTokens.Size.dateCircle)

            VStack(alignment: .leading, spacing: 4) {
                Text(flight.formattedRoute)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                HStack(spacing: 6) {
                    ForEach(flight.categoryTags, id: \.self) { tag in
                        CategoryBadge(tag: tag)
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
                            .accessibilityLabel("Has instructor signature")
                    }
                    if flight.isSignatureLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Signature locked")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - D4: Shared Category Badge

struct CategoryBadge: View {
    let tag: String

    private var badgeColor: Color {
        switch tag {
        case "Solo": return .skyBlue
        case "Dual": return .purple
        case "XC": return .orange
        case "Inst": return .gray
        default: return .skyBlue
        }
    }

    var body: some View {
        Text(tag)
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(AppTokens.Opacity.light))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
}

// MARK: - Flight Detail View (B6: Edit support, B2: Duplicate)

struct FlightDetailView: View {
    let flight: FlightLog
    var onDuplicate: ((FlightLog) -> Void)?

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

                // Categories — D4: using shared CategoryBadge
                if !flight.categoryTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(flight.categoryTags, id: \.self) { tag in
                            CategoryBadge(tag: tag)
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
