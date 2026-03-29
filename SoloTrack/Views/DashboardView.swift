import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]
    @Environment(OnboardingManager.self) private var onboarding

    // FR-3: Add Flight directly from Dashboard
    @State private var showingAddFlight = false

    // Save confirmation toast
    @State private var showSavedToast = false

    // C3: Flight recommendation from nudge card
    @State private var recommendedFlight: FlightRecommendation?

    // DL-6: Loading state polish
    @State private var hasAppeared = false

    // FR-6: Dynamic Type scaled dimensions
    private let scaled = ScaledTokens()

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
            // FR-3: Toolbar button to add flight from Dashboard
            .toolbar {
                if !flights.isEmpty {
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
            }
            .sheet(isPresented: $showingAddFlight, onDismiss: { recommendedFlight = nil }) {
                AddFlightView(defaultRecommendation: recommendedFlight, onSave: {
                    showSavedToast = true
                })
            }
            // Save confirmation overlay
            .overlay(alignment: .top) {
                if showSavedToast {
                    ToastView(icon: "checkmark.circle.fill", message: "Flight saved")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .motionAwareAnimation(.spring(duration: 0.4), value: showSavedToast)
            .sensoryFeedback(.success, trigger: showSavedToast)
            .task(id: showSavedToast) {
                guard showSavedToast else { return }
                do { try await Task.sleep(for: .seconds(AppTokens.Duration.toast)) }
                catch { return }
                withMotionAwareAnimation(.easeOut(duration: 0.3)) { showSavedToast = false }
            }
            // Auto-open AddFlightView when onboarding intent is log/backfill
            .task {
                guard onboarding.shouldOpenAddFlight else { return }
                onboarding.shouldOpenAddFlight = false
                // Small delay so the sheet presentation doesn't conflict
                // with the onboarding sheet dismissal
                do { try await Task.sleep(for: .seconds(AppTokens.Onboarding.autoOpenDelay)) }
                catch { return }
                showingAddFlight = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyDashboard: some View {
        Group {
            if onboarding.hasCompletedOnboarding {
                // Personalized empty state (post-onboarding)
                PersonalizedEmptyDashboard {
                    showingAddFlight = true
                }
            } else {
                // Original empty state (pre-onboarding fallback)
                genericEmptyDashboard
            }
        }
    }

    // MARK: - Generic Empty State (pre-onboarding fallback)

    private var genericEmptyDashboard: some View {
        ScrollView {
            VStack(spacing: AppTokens.Spacing.section) {
                Spacer(minLength: AppTokens.Spacing.jumbo)

                // DL-10: Composed empty state illustration
                ZStack {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: scaled.cloudLarge))
                        .foregroundStyle(Color.skyBlue.opacity(AppTokens.Opacity.light))
                        .offset(x: -40, y: -20)

                    Image(systemName: "cloud.fill")
                        .font(.system(size: scaled.cloudSmall))
                        .foregroundStyle(Color.skyBlue.opacity(AppTokens.Opacity.subtle))
                        .offset(x: 45, y: -10)

                    Image(systemName: "airplane.circle")
                        .font(.system(size: scaled.airplaneIcon))
                        .foregroundStyle(Color.skyBlue.opacity(AppTokens.Opacity.strong))
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }

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

                // FR-3: Actionable CTA instead of passive text
                Button {
                    showingAddFlight = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Your First Flight")
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.skyBlue)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Populated Dashboard

    private var populatedDashboard: some View {
        let dayCurrency = currencyManager.dayCurrency(flights: flights)
        let nightCurrency = currencyManager.nightCurrency(flights: flights)
        // H-2 fix: Compute requirements once and pass through
        let requirements = progressTracker.computeRequirements(from: flights)

        return ScrollView {
            VStack(spacing: AppTokens.Spacing.xxl) {
                headerSection(dayCurrency: dayCurrency)
                currencySection(dayCurrency: dayCurrency, nightCurrency: nightCurrency)
                quickStatsSection(requirements: requirements)
                progressNudgeSection(requirements: requirements)
            }
            .padding()
        }
        .refreshable {
            HapticService.lightImpact()
            do { try await Task.sleep(for: .milliseconds(300)) }
            catch { return }
        }
        .redacted(reason: hasAppeared ? [] : .placeholder)
        .task {
            guard !hasAppeared else { return }
            await MainActor.run {
                withMotionAwareAnimation(.easeOut(duration: AppTokens.Duration.quick)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - PX-1: Motivational Progress Nudge

    private func progressNudgeSection(requirements: [PPLRequirement]) -> some View {
        let nextGoal = requirements
            .filter { !$0.isMet }
            .min { $0.remainingHours < $1.remainingHours }
        let recommendation = progressTracker.nextRecommendation(from: flights)

        return Group {
            if let goal = nextGoal {
                Button {
                    recommendedFlight = recommendation
                    showingAddFlight = true
                    HapticService.selectionChanged()
                } label: {
                    HStack(spacing: AppTokens.Spacing.lg) {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundStyle(Color.skyBlue)

                        VStack(alignment: .leading, spacing: AppTokens.Spacing.xxs) {
                            Text("NEXT MILESTONE")
                                .sectionHeaderStyle()
                            Text("\(String(format: "%.1f", goal.remainingHours)) hrs to \(goal.title)")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            if let rec = recommendation {
                                Text(rec.description)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Color.skyBlue)
                            }
                            Text(goal.farReference)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("\(goal.percentComplete)%")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.skyBlue)
                                .contentTransition(.numericText())
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .accessibilityHint("Tap to log a recommended flight")
            }
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
            .motionAwareAnimation(.smooth(duration: 0.4), value: overallLegal)
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

    // MARK: - Quick Stats

    private func quickStatsSection(requirements: [PPLRequirement]) -> some View {
        VStack(spacing: 12) {
            Text("QUICK STATS")
                .sectionHeaderStyle()
                .frame(maxWidth: .infinity, alignment: .leading)

            let totalHours = flights.reduce(0.0) { $0 + $1.durationHobbs }
            let totalFlights = flights.count
            let met = requirements.filter(\.isMet).count
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

    // FR-6: Dynamic Type scaled dimensions
    private let scaled = ScaledTokens()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.skyBlue)
                .frame(width: scaled.onboardingRowIcon)

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

    // FR-6: Dynamic Type scaled dimensions
    private let scaled = ScaledTokens()

    @State private var showingDetail = false

    /// Ambient urgency gradient: green→green when safe, green→yellow when approaching, yellow→red when critical
    private var urgencyGradient: LinearGradient {
        switch state {
        case .valid(let days) where days > 60:
            return LinearGradient(colors: [.currencyGreen.opacity(0.4), .currencyGreen.opacity(0.4)], startPoint: .top, endPoint: .bottom)
        case .valid(let days) where days > 30:
            return LinearGradient(colors: [.currencyGreen.opacity(0.4), .cautionYellow.opacity(0.4)], startPoint: .top, endPoint: .bottom)
        case .valid, .caution:
            return LinearGradient(colors: [.cautionYellow.opacity(0.4), .warningRed.opacity(0.4)], startPoint: .top, endPoint: .bottom)
        case .expired:
            return LinearGradient(colors: [.warningRed.opacity(0.4), .warningRed.opacity(0.4)], startPoint: .top, endPoint: .bottom)
        }
    }

    var body: some View {
        Button {
            withMotionAwareAnimation(.spring(duration: 0.3)) {
                showingDetail.toggle()
            }
            HapticService.selectionChanged()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: state.iconName)
                    .font(.system(size: scaled.currencyIcon))
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

                // DL-8: Expandable detail on tap
                if showingDetail {
                    VStack(spacing: 4) {
                        Divider()
                        Text(state.label)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: AppTokens.Radius.card)
                    .stroke(urgencyGradient, lineWidth: 2)
            )
        }
        .buttonStyle(CardPressStyle())
        .motionAwareAnimation(.smooth(duration: 0.4), value: state)
        .onChange(of: state.label) { _, _ in
            if case .expired = state { HapticService.warning() }
            else if case .caution = state { HapticService.warning() }
        }
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
                .motionAwareAnimation(.spring(duration: AppTokens.Duration.normal), value: value)

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

// MARK: - DL-5: Card Press Effect

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .motionAwareAnimation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [FlightLog.self, FlightTemplate.self], inMemory: true)
        .environment(OnboardingManager())
}
