import SwiftUI

// MARK: - Coach Mark Overlay

/// A semi-transparent overlay that presents contextual coach marks during the
/// interactive tour. Shown as an overlay on the root view, it dims the background
/// and displays a floating card with step-specific copy and a "Next" button.
struct CoachMarkOverlay: View {
    @Environment(OnboardingManager.self) private var onboarding

    let step: CoachMarkStep

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tapping backdrop advances the tour (forgiving UX)
                    advanceOrDismiss()
                }

            // Coach mark card
            VStack(spacing: AppTokens.Spacing.xxl) {
                // Step indicator
                HStack(spacing: 6) {
                    ForEach(CoachMarkStep.allCases.filter { $0 != .tourComplete }, id: \.self) { s in
                        Circle()
                            .fill(s.rawValue <= step.rawValue ? Color.skyBlue : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }

                // Icon
                Image(systemName: step.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.skyBlue)
                    .symbolEffect(.bounce, value: step)

                // Title
                Text(step.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                // Body
                Text(step.message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Action buttons
                HStack(spacing: 16) {
                    if step != .tourComplete {
                        Button("Skip Tour") {
                            onboarding.skipTour()
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        advanceOrDismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text(step == .tourComplete ? "Start Logging" : "Next")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            if step != .tourComplete {
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.skyBlue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(AppTokens.Spacing.section)
            .frame(maxWidth: 340)
            .background(.ultraThinMaterial)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.card))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            .motionAwareAnimation(.spring(duration: 0.4, bounce: 0.2), value: appeared)
            .padding(.horizontal, 24)
        }
        .onAppear {
            appeared = true
        }
        .onChange(of: step) { _, _ in
            // Re-trigger entrance animation on step change
            appeared = false
            withMotionAwareAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tour step: \(step.title). \(step.message)")
        .accessibilityAddTraits(.isModal)
    }

    private func advanceOrDismiss() {
        HapticService.lightImpact()
        if step == .tourComplete {
            onboarding.completeTour()
        } else {
            withMotionAwareAnimation(.spring(duration: 0.4)) {
                onboarding.advanceTour()
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        CoachMarkOverlay(step: .dashboardWelcome)
    }
    .environment(OnboardingManager())
}
