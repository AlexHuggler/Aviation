import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    private let currencyManager = CurrencyManager()
    private let progressTracker = ProgressTracker()

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    emptyDashboard
                } else {
                    populatedDashboard
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SoloTrack")
        }
    }

    // MARK: - Empty State (B5: staggered entrance animations)

    private var emptyDashboard: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "airplane.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.skyBlue.opacity(0.6))
                    .symbolEffect(.pulse.byLayer, options: .repeating)

                VStack(spacing: 8) {
                    Text("Welcome to SoloTrack")
                        .font(.system(.title2, design: .rounded, weight: .bold))

                    Text("Log your first flight to start tracking\ncurrency and PPL progress.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    OnboardingRow(icon: "gauge.with.dots.needle.33percent", text: "Day & Night currency tracking")
                    OnboardingRow(icon: "chart.bar.fill", text: "FAR 61.109 PPL requirement progress")
                    OnboardingRow(icon: "signature", text: "Electronic CFI signature capture")
                    OnboardingRow(icon: "square.and.arrow.up", text: "CSV export for your records")
                }
                .padding()
                .cardStyle()

                Text("Tap the Logbook tab to get started")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.tertiary)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Populated Dashboard

    private var populatedDashboard: some View {
        let dayCurrency = currencyManager.dayCurrency(flights: flights)
        let nightCurrency = currencyManager.nightCurrency(flights: flights)

        return ScrollView {
            VStack(spacing: 20) {
                headerSection(dayCurrency: dayCurrency)
                currencySection(dayCurrency: dayCurrency, nightCurrency: nightCurrency)
                quickStatsSection
            }
            .padding()
        }
    }

    // MARK: - Header

    private func headerSection(dayCurrency: CurrencyState) -> some View {
        VStack(spacing: 4) {
            Text("LEGAL TO FLY?")
                .sectionHeaderStyle()

            let overallLegal = dayCurrency.isLegal

            HStack {
                Image(systemName: overallLegal ? "airplane" : "airplane.slash")
                    .font(.title)
                    .contentTransition(.symbolEffect(.replace))
                Text(overallLegal ? "You are current" : "NOT CURRENT")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(overallLegal ? Color.currencyGreen : Color.warningRed)
            .animation(.smooth(duration: 0.4), value: overallLegal)
            // A6: VoiceOver accessibility
            .accessibilityElement(children: .combine)
            .accessibilityLabel(overallLegal ? "You are current to fly" : "You are not current to fly")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Currency Cards

    private func currencySection(dayCurrency: CurrencyState, nightCurrency: CurrencyState) -> some View {
        VStack(spacing: 12) {
            Text("PASSENGER CURRENCY")
                .sectionHeaderStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

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

    // MARK: - Quick Stats (H-2: compute requirements once)

    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            Text("QUICK STATS")
                .sectionHeaderStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            let totalHours = flights.reduce(0.0) { $0 + $1.durationHobbs }
            let totalFlights = flights.count
            let requirements = progressTracker.computeRequirements(from: flights)
            let met = requirements.filter { $0.isMet }.count
            let total = requirements.count

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

// MARK: - Onboarding Row

private struct OnboardingRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.skyBlue)
                .frame(width: 28)

            Text(text)
                .font(.system(.subheadline, design: .rounded))
        }
    }
}

// MARK: - Currency Card (A6: accessibility, B4: absolute dates)

struct CurrencyCard: View {
    let title: String
    let icon: String
    let state: CurrencyState

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: state.iconName)
                .font(.system(size: 32))
                .foregroundStyle(state.color)
                .contentTransition(.symbolEffect(.replace))

            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            // B4: Show both relative and absolute date
            VStack(spacing: 2) {
                Text(state.shortLabel)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(state.color)
                    .contentTransition(.numericText())

                if let dateLabel = state.absoluteDateLabel {
                    Text(dateLabel)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(state.color.opacity(0.4), lineWidth: 2)
        )
        .animation(.smooth(duration: 0.4), value: state)
        // A6: Accessibility — combine children and provide descriptive label
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) currency: \(state.label)")
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
                .contentTransition(.numericText())

            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
