import SwiftUI

// MARK: - Personalized Empty Dashboard

/// Replaces the generic empty state on DashboardView after onboarding is complete.
/// Shows persona-specific messaging, highlighted features relevant to the user's
/// training stage, and a contextual CTA.
struct PersonalizedEmptyDashboard: View {
    @Environment(OnboardingManager.self) private var onboarding

    let onLogFlight: () -> Void

    @State private var staggeredAppear = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                // Personalized welcome header
                welcomeHeader

                // Stage-specific feature highlights
                featureHighlights

                // Contextual CTA
                ctaButton

                // Subtle tip based on intent
                contextualTip

                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                staggeredAppear = true
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: onboarding.trainingStage.icon)
                .font(.system(size: 52))
                .foregroundStyle(Color.skyBlue)
                .symbolEffect(.pulse.byLayer, options: .repeating)

            VStack(spacing: 6) {
                Text(stageGreeting)
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text(onboarding.trainingStage.welcomeMessage)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Stage badge
            Text(onboarding.trainingStage.displayTitle)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.skyBlue.opacity(AppTokens.Opacity.light))
                .foregroundStyle(Color.skyBlue)
                .clipShape(Capsule())
        }
        .opacity(staggeredAppear ? 1 : 0)
        .offset(y: staggeredAppear ? 0 : 12)
    }

    private var stageGreeting: String {
        switch onboarding.trainingStage {
        case .preSolo: return "Ready to Begin"
        case .postSolo: return "Building Toward the Checkride"
        case .checkridPrep: return "Final Stretch"
        }
    }

    // MARK: - Feature Highlights (persona-specific)

    private var featureHighlights: some View {
        let features = highlightedFeatures

        return VStack(alignment: .leading, spacing: 12) {
            Text("WHAT SOLOTRACK DOES FOR YOU")
                .sectionHeaderStyle()
                .padding(.horizontal, 4)

            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                FeatureHighlightRow(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                    isPrimary: index == 0
                )
                .opacity(staggeredAppear ? 1 : 0)
                .offset(y: staggeredAppear ? 0 : CGFloat(8 + index * 4))
                .motionAwareAnimation(
                    .easeOut(duration: 0.4).delay(Double(index) * 0.1),
                    value: staggeredAppear
                )
            }
        }
    }

    private var highlightedFeatures: [(icon: String, title: String, description: String)] {
        switch onboarding.trainingStage {
        case .preSolo:
            return [
                (icon: "gauge.with.dots.needle.33percent", title: "Currency Tracking",
                 description: "See your Day & Night currency status at a glance — know when you're legal to carry passengers."),
                (icon: "signature", title: "CFI Endorsements",
                 description: "Capture your instructor's signature digitally. Flights are locked once signed."),
                (icon: "chart.bar.fill", title: "PPL Progress",
                 description: "Track all 6 FAR 61.109 requirements. See exactly how many hours remain.")
            ]
        case .postSolo:
            return [
                (icon: "chart.bar.fill", title: "PPL Requirement Progress",
                 description: "Track solo hours, cross-country time, and all FAR 61.109 requirements in real time."),
                (icon: "gauge.with.dots.needle.33percent", title: "Stay Current",
                 description: "Day & Night currency cards update automatically as you log flights."),
                (icon: "square.and.arrow.up", title: "Export Your Logbook",
                 description: "Export to CSV anytime — perfect for backup or sharing with your flight school.")
            ]
        case .checkridPrep:
            return [
                (icon: "target", title: "Close the Gaps",
                 description: "See exactly which PPL requirements still need hours, with progress bars and remaining time."),
                (icon: "gauge.with.dots.needle.33percent", title: "Currency Check",
                 description: "Verify you're current before your checkride — Day and Night status in one glance."),
                (icon: "signature", title: "Endorsement Ready",
                 description: "All CFI signatures captured and locked. Your digital logbook is checkride-ready.")
            ]
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button(action: onLogFlight) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(ctaLabel)
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.skyBlue)
        .opacity(staggeredAppear ? 1 : 0)
    }

    private var ctaLabel: String {
        switch onboarding.gettingStartedIntent {
        case .logFresh: return "Log Your Latest Flight"
        case .backfill: return "Start Entering Past Flights"
        case .explore: return "Log Your First Flight"
        }
    }

    // MARK: - Contextual Tip

    private var contextualTip: some View {
        Group {
            if onboarding.gettingStartedIntent == .backfill {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("Tip: After logging your first flight, swipe left on it and tap Duplicate to quickly backfill more flights.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.cautionYellow.opacity(AppTokens.Opacity.subtle))
                .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.sm))
            }
        }
    }
}

// MARK: - Feature Highlight Row

private struct FeatureHighlightRow: View {
    let icon: String
    let title: String
    let description: String
    let isPrimary: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isPrimary ? Color.skyBlue : .secondary)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isPrimary ? Color.skyBlue.opacity(AppTokens.Opacity.subtle) : .clear)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTokens.Radius.card)
                .stroke(isPrimary ? Color.skyBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    PersonalizedEmptyDashboard(onLogFlight: {})
        .environment(OnboardingManager())
}
