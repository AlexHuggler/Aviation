import SwiftUI
import SwiftData

struct LogbookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    @State private var showingAddFlight = false
    @State private var showingExportSheet = false
    @State private var appeared = false
    @State private var exportedCSV = ""

    // A2: Save confirmation toast — only set via onSave callback
    @State private var showSavedToast = false

    // A6: Delete-locked alert
    @State private var showLockedDeleteAlert = false

    // FR-R3: Undo support
    @State private var showDeletedToast = false
    @State private var lastDeletedFlight: FlightLog?

    // A1: Search & filter
    @State private var searchText = ""

    // Swipe-to-edit support
    @State private var flightToEdit: FlightLog?

    // Category & date filters
    @State private var activeFilters: Set<FlightFilter> = []

    // D2: Static date formatter (avoid re-allocation on every group call)
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // H-11 fix: Cached filtered results to avoid recomputation on every body eval
    @State private var filteredFlights: [FlightLog] = []

    // A1: Filtering logic extracted for reuse and testability
    static func filterFlights(
        _ flights: [FlightLog],
        searchText: String,
        activeFilters: Set<FlightFilter>
    ) -> [FlightLog] {
        var result = flights

        // Apply category/date filters
        if !activeFilters.isEmpty {
            let calendar = Calendar.current
            let now = Date.now
            result = result.filter { flight in
                activeFilters.allSatisfy { filter in
                    switch filter {
                    case .solo: return flight.isSolo
                    case .dual: return flight.isDualReceived
                    case .crossCountry: return flight.isCrossCountry
                    case .instrument: return flight.isSimulatedInstrument
                    case .night: return flight.landingsNightFullStop > 0
                    case .thisMonth:
                        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                        return flight.date >= start
                    case .last90Days:
                        let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
                        return flight.date >= start
                    }
                }
            }
        }

        // Apply text search
        guard !searchText.isEmpty else { return result }
        let query = searchText.lowercased()
        return result.filter { flight in
            flight.routeFrom.lowercased().contains(query)
            || flight.routeTo.lowercased().contains(query)
            || flight.formattedRoute.lowercased().contains(query)
            || flight.categoryTags.contains { $0.lowercased().contains(query) }
            || flight.remarks.lowercased().contains(query)
            || flight.cfiNumber.lowercased().contains(query)
            || flight.date.formatted(date: .abbreviated, time: .omitted).lowercased().contains(query)
            || flight.date.formatted(date: .long, time: .omitted).lowercased().contains(query)
        }
    }

    private func refilter() {
        filteredFlights = Self.filterFlights(flights, searchText: searchText, activeFilters: activeFilters)
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
                    .keyboardShortcut("e", modifiers: .command)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddFlight = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            // A2: Fixed — toast only fires via onSave callback, not onDismiss
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView(onSave: {
                    showSavedToast = true
                })
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(csvContent: exportedCSV)
            }
            .sheet(item: $flightToEdit) { flight in
                AddFlightView(editingFlight: flight, onSave: {
                    showSavedToast = true
                })
            }
            .alert("Cannot Delete", isPresented: $showLockedDeleteAlert) {
                Button("OK") {}
            } message: {
                Text("This flight has a locked CFI signature. Void the signature first to enable deletion.")
            }
            // A3: Save confirmation overlay
            .overlay(alignment: .top) {
                if showSavedToast {
                    ToastView(icon: "checkmark.circle.fill", message: "Flight saved")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .motionAwareAnimation(.spring(duration: 0.4), value: showSavedToast)
            // H-5 fix: Structured concurrency auto-cancels on view dismissal
            .task(id: showSavedToast) {
                guard showSavedToast else { return }
                do { try await Task.sleep(for: .seconds(AppTokens.Duration.toast)) }
                catch { return }
                withMotionAwareAnimation(.easeOut(duration: 0.3)) { showSavedToast = false }
            }
            // FR-R3: Delete undo toast
            .overlay(alignment: .top) {
                if showDeletedToast {
                    ToastView(
                        icon: "trash",
                        message: "Flight deleted",
                        iconColor: .warningRed,
                        actionLabel: "Undo",
                        onAction: { undoDelete() }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .motionAwareAnimation(.spring(duration: 0.4), value: showDeletedToast)
            .task(id: showDeletedToast) {
                guard showDeletedToast else { return }
                do { try await Task.sleep(for: .seconds(4.0)) }
                catch { return }
                withMotionAwareAnimation(.easeOut(duration: 0.3)) {
                    showDeletedToast = false
                    lastDeletedFlight = nil
                }
            }
            // H-11 fix: Refilter when inputs change instead of recomputing in body
            .onAppear { refilter() }
            .onChange(of: flights.count) { _, _ in refilter() }
            .onChange(of: searchText) { _, _ in refilter() }
            .onChange(of: activeFilters) { _, _ in refilter() }
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

            // Filter chips
            filterChipsSection

            ForEach(grouped, id: \.key) { section in
                Section {
                    ForEach(section.flights) { flight in
                        NavigationLink {
                            FlightDetailView(flight: flight, onDuplicate: { source in
                                duplicateFlight(source)
                            })
                        } label: {
                            FlightRow(flight: flight)
                        }
                        // PX-2: Swipe actions for quick access
                        .swipeActions(edge: .leading) {
                            if flight.isEditable {
                                Button {
                                    flightToEdit = flight
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
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
                                    HapticService.error()
                                } else {
                                    deleteFlight(flight)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        // B2: Context menu kept for discoverability
                        .contextMenu {
                            if flight.isEditable {
                                Button {
                                    flightToEdit = flight
                                } label: {
                                    Label("Edit Flight", systemImage: "pencil")
                                }
                            }
                            Button {
                                duplicateFlight(flight)
                            } label: {
                                Label("Duplicate Flight", systemImage: "doc.on.doc")
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                } header: {
                    Text(section.key)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            withMotionAwareAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        // A1: Search bar
        .searchable(text: $searchText, prompt: "Route, date, category, or remarks")
        // A1: Empty search results
        .overlay {
            if !searchText.isEmpty && filteredFlights.isEmpty {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No flights match \"\(searchText)\".\nTry a route code, date, or category.")
                }
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
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
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

    // FR-R3: Delete with undo support
    private func deleteFlight(_ flight: FlightLog) {
        lastDeletedFlight = flight
        modelContext.delete(flight)
        HapticService.deleteConfirmation()
        withMotionAwareAnimation(.spring(duration: 0.4)) {
            showDeletedToast = true
        }
    }

    private func undoDelete() {
        guard let flight = lastDeletedFlight else { return }
        modelContext.insert(flight)
        lastDeletedFlight = nil
        HapticService.success()
        withMotionAwareAnimation(.easeOut(duration: 0.3)) {
            showDeletedToast = false
        }
    }

    private func deleteFlights(from sectionFlights: [FlightLog], at offsets: IndexSet) {
        for index in offsets {
            let flight = sectionFlights[index]
            if flight.isSignatureLocked {
                showLockedDeleteAlert = true
                HapticService.error()
            } else {
                deleteFlight(flight)
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
        HapticService.success()
        showSavedToast = true
    }

    // MARK: - Filter Chips

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTokens.Spacing.sm) {
                    ForEach(FlightFilter.allCases) { filter in
                        Button {
                            withMotionAwareAnimation(.spring(duration: 0.3)) {
                                if activeFilters.contains(filter) {
                                    activeFilters.remove(filter)
                                } else {
                                    // Date filters are mutually exclusive
                                    if filter == .thisMonth || filter == .last90Days {
                                        activeFilters.remove(.thisMonth)
                                        activeFilters.remove(.last90Days)
                                    }
                                    activeFilters.insert(filter)
                                }
                            }
                            HapticService.selectionChanged()
                        } label: {
                            Text(filter.label)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .padding(.horizontal, AppTokens.Spacing.md)
                                .padding(.vertical, AppTokens.Spacing.xs)
                                .background(
                                    activeFilters.contains(filter)
                                        ? Color.skyBlue.opacity(0.2)
                                        : Color.skyBlue.opacity(AppTokens.Opacity.subtle)
                                )
                                .foregroundStyle(activeFilters.contains(filter) ? Color.skyBlue : .secondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // Clear all button when filters are active
                    if !activeFilters.isEmpty {
                        Button {
                            withMotionAwareAnimation(.spring(duration: 0.3)) {
                                activeFilters.removeAll()
                            }
                            HapticService.selectionChanged()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Flight Filter

enum FlightFilter: String, CaseIterable, Identifiable, Hashable {
    case solo, dual, crossCountry, instrument, night, thisMonth, last90Days

    var id: String { rawValue }

    var label: String {
        switch self {
        case .solo: return "Solo"
        case .dual: return "Dual"
        case .crossCountry: return "XC"
        case .instrument: return "Instrument"
        case .night: return "Night"
        case .thisMonth: return "This Month"
        case .last90Days: return "Last 90 Days"
        }
    }
}

// MARK: - B3: Summary Pill

private struct SummaryPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.skyBlue)
                .contentTransition(.numericText())
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
    LogbookListView()
        .modelContainer(for: [FlightLog.self, FlightTemplate.self], inMemory: true)
        .environment(OnboardingManager())
}
