import SwiftUI
import SwiftData

struct PPLProgressView: View {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    // FR-4: Actionable empty state
    @State private var showingAddFlight = false

    private let progressTracker = ProgressTracker()

    // Track previous met count to detect milestone transitions
    @State private var lastMetCount = -1
    @State private var allMetCelebrating = false

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    emptyProgressState
                } else {
                    progressContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PPL Progress")
        }
    }

    // MARK: - A8: Empty State (FR-4: Actionable CTA)

    private var emptyProgressState: some View {
        ContentUnavailableView {
            Label {
                Text("No Progress Yet")
            } icon: {
                ZStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.skyBlue.opacity(AppTokens.Opacity.strong))
                    Image(systemName: "airplane")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.skyBlue)
                        .offset(x: 16, y: -16)
                }
            }
        } description: {
            Text("Log your first flight to start tracking progress toward your Private Pilot License requirements under FAR 61.109.")
        } actions: {
            Button("Log Your First Flight") {
                showingAddFlight = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.skyBlue)
        }
        .sheet(isPresented: $showingAddFlight) {
            AddFlightView()
        }
    }

    // MARK: - Progress Content

    private var progressContent: some View {
        ScrollView {
            VStack(spacing: AppTokens.Spacing.xxl) {
                overallProgressCard
                requirementsList
            }
            .padding()
        }
    }

    // MARK: - Overall Progress

    private var overallProgressCard: some View {
        VStack(spacing: 12) {
            Text("FAR 61.109 REQUIREMENTS")
                .sectionHeaderStyle()

            let overall = progressTracker.overallProgress(from: flights)
            let met = progressTracker.requirementsMet(from: flights)
            let total = progressTracker.totalRequirements()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: AppTokens.Size.strokeWidth)

                Circle()
                    .trim(from: 0, to: overall)
                    .stroke(
                        Color.skyBlue,
                        style: StrokeStyle(lineWidth: AppTokens.Size.strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .motionAwareAnimation(.easeInOut(duration: 0.8), value: overall)

                VStack(spacing: 4) {
                    Text("\(Int(overall * 100))%")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.skyBlue)
                        .contentTransition(.numericText())

                    Text("\(met) of \(total) met")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .frame(width: AppTokens.Size.progressRing, height: AppTokens.Size.progressRing)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Int(overall * 100)) percent complete. \(met) of \(total) requirements met.")
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppTokens.Radius.card)
                .stroke(allMetCelebrating ? Color.currencyGreen.opacity(0.6) : Color.clear, lineWidth: 3)
        )
        .scaleEffect(allMetCelebrating ? 1.03 : 1.0)
        .motionAwareAnimation(.spring(duration: 0.6, bounce: 0.3), value: allMetCelebrating)
        .onChange(of: progressTracker.requirementsMet(from: flights)) { oldMet, newMet in
            // Celebrate when all requirements are newly met
            if newMet == progressTracker.totalRequirements() && oldMet < newMet {
                allMetCelebrating = true
                HapticService.milestoneAchieved()
            }
        }
        .task(id: allMetCelebrating) {
            guard allMetCelebrating else { return }
            do { try await Task.sleep(for: .seconds(AppTokens.Duration.celebration)) }
            catch { return }
            allMetCelebrating = false
        }
    }

    // MARK: - Requirements List

    private var requirementsList: some View {
        VStack(spacing: 12) {
            let requirements = progressTracker.computeRequirements(from: flights)

            ForEach(requirements) { req in
                RequirementRow(requirement: req)
            }
        }
    }
}

// MARK: - Requirement Row (B5: milestones and remaining hours)

struct RequirementRow: View {
    let requirement: PPLRequirement

    @State private var celebrating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(requirement.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))

                    Text(requirement.farReference)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if requirement.isMet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.currencyGreen)
                        .font(.title3)
                        .symbolEffect(.bounce, value: requirement.isMet)
                } else {
                    Text("\(requirement.percentComplete)%")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(progressColor)
                        .contentTransition(.numericText())
                }
            }

            // B5: Progress bar with milestone tick marks
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(AppTokens.Opacity.light))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * requirement.progress)
                        .motionAwareAnimation(.easeInOut(duration: 0.6), value: requirement.progress)

                    // Milestone tick marks at 25%, 50%, 75%
                    ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                        Rectangle()
                            .fill(Color.primary.opacity(AppTokens.Opacity.light))
                            .frame(width: 1.5, height: 10)
                            .offset(x: geometry.size.width * milestone)
                    }
                }
            }
            .frame(height: 10)

            // B5: Remaining hours text
            HStack {
                Text(requirement.formattedProgress)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(requirement.formattedRemaining)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(requirement.isMet ? Color.currencyGreen : progressColor)
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppTokens.Radius.card)
                .stroke(celebrating ? Color.currencyGreen.opacity(0.6) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(celebrating ? 1.05 : 1.0)
        .motionAwareAnimation(.spring(duration: 0.5, bounce: 0.3), value: celebrating)
        .onChange(of: requirement.isMet) { wasMet, isMet in
            if !wasMet && isMet {
                celebrating = true
                HapticService.milestoneAchieved()
            }
        }
        .task(id: celebrating) {
            guard celebrating else { return }
            do { try await Task.sleep(for: .seconds(AppTokens.Duration.celebration)) }
            catch { return }
            celebrating = false
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(requirement.title): \(requirement.formattedProgress). \(requirement.formattedRemaining).")
    }

    private var progressColor: Color {
        if requirement.isMet {
            return .currencyGreen
        } else if requirement.progress >= 0.5 {
            return .skyBlue
        } else {
            return .cautionYellow
        }
    }
}

#Preview {
    PPLProgressView()
        .modelContainer(for: [FlightLog.self, FlightTemplate.self], inMemory: true)
        .environment(OnboardingManager())
}
