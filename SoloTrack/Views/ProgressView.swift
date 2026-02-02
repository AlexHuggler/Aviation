import SwiftUI
import SwiftData

struct PPLProgressView: View {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]

    private let progressTracker = ProgressTracker()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    overallProgressCard
                    requirementsList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PPL Progress")
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
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: overall)
                    .stroke(
                        Color.skyBlue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: overall)

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
            .frame(width: 160, height: 160)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
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
                        .fill(Color.gray.opacity(0.15))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * requirement.progress)
                        .animation(.easeInOut(duration: 0.6), value: requirement.progress)

                    // Milestone tick marks at 25%, 50%, 75%
                    ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                        Rectangle()
                            .fill(Color.primary.opacity(0.15))
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
        .modelContainer(for: FlightLog.self, inMemory: true)
}
