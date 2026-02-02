import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    private let currencyManager = CurrencyManager()
    private let progressTracker = ProgressTracker()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    currencySection
                    quickStatsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SoloTrack")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("LEGAL TO FLY?")
                .sectionHeaderStyle()

            let dayCurrency = currencyManager.dayCurrency(flights: flights)
            let nightCurrency = currencyManager.nightCurrency(flights: flights)
            let overallLegal = dayCurrency.isLegal

            HStack {
                Image(systemName: overallLegal ? "airplane" : "airplane.slash")
                    .font(.title)
                Text(overallLegal ? "You are current" : "NOT CURRENT")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            .foregroundStyle(overallLegal ? Color.currencyGreen : Color.warningRed)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Currency Cards

    private var currencySection: some View {
        VStack(spacing: 12) {
            Text("PASSENGER CURRENCY")
                .sectionHeaderStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            let dayCurrency = currencyManager.dayCurrency(flights: flights)
            let nightCurrency = currencyManager.nightCurrency(flights: flights)

            HStack(spacing: 12) {
                CurrencyCard(
                    title: "Day",
                    icon: "sun.max.fill",
                    state: dayCurrency
                )

                CurrencyCard(
                    title: "Night",
                    icon: "moon.stars.fill",
                    state: nightCurrency
                )
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            Text("QUICK STATS")
                .sectionHeaderStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            let totalHours = flights.reduce(0.0) { $0 + $1.durationHobbs }
            let totalFlights = flights.count
            let met = progressTracker.requirementsMet(from: flights)
            let total = progressTracker.totalRequirements()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatCard(value: String(format: "%.1f", totalHours), label: "Total Hours")
                StatCard(value: "\(totalFlights)", label: "Flights")
                StatCard(value: "\(met)/\(total)", label: "PPL Reqs Met")
            }
        }
    }
}

// MARK: - Currency Card

struct CurrencyCard: View {
    let title: String
    let icon: String
    let state: CurrencyState

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: state.iconName)
                .font(.system(size: 32))
                .foregroundStyle(state.color)

            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(state.shortLabel)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(state.color)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(state.color.opacity(0.4), lineWidth: 2)
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.skyBlue)

            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
