import SwiftUI

// MARK: - Onboarding Questionnaire

/// A two-step, full-screen onboarding flow presented as a sheet.
/// Step 1: Training stage selection (persona profiling).
/// Step 2: Getting-started intent (immediate next action).
struct OnboardingView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var currentStep = 0
    @State private var selectedStage: TrainingStage?
    @State private var selectedIntent: GettingStartedIntent?
    @State private var appearAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressDots
                .padding(.top, 24)

            Spacer()

            // Animated step content
            Group {
                switch currentStep {
                case 0: trainingStageStep
                case 1: gettingStartedStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Continue / Get Started button
            continueButton
                .padding(.horizontal, AppTokens.Spacing.section)
                .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withMotionAwareAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.skyBlue : Color.gray.opacity(0.3))
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .motionAwareAnimation(.spring(duration: 0.4), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Training Stage

    private var trainingStageStep: some View {
        VStack(spacing: AppTokens.Spacing.xxxl) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.skyBlue)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 16)
                    .motionAwareAnimation(.easeOut(duration: 0.6), value: appearAnimation)

                Text("Welcome to SoloTrack")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("To customize your experience,\ntell us where you are in your training.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Training stage cards
            VStack(spacing: 12) {
                ForEach(TrainingStage.allCases, id: \.self) { stage in
                    OnboardingOptionCard(
                        icon: stage.icon,
                        title: stage.displayTitle,
                        subtitle: stage.tagline,
                        isSelected: selectedStage == stage
                    ) {
                        withMotionAwareAnimation(.spring(duration: 0.3)) {
                            selectedStage = stage
                        }
                        HapticService.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, AppTokens.Spacing.section)
        }
    }

    // MARK: - Step 2: Getting Started Intent

    private var gettingStartedStep: some View {
        VStack(spacing: AppTokens.Spacing.xxxl) {
            // Header
            VStack(spacing: 12) {
                if let stage = selectedStage {
                    Image(systemName: stage.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(Color.skyBlue)
                }

                Text("How would you like\nto get started?")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("You can always change this later.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Intent cards
            VStack(spacing: 12) {
                ForEach(GettingStartedIntent.allCases, id: \.self) { intent in
                    OnboardingOptionCard(
                        icon: intent.icon,
                        title: intent.displayTitle,
                        subtitle: intent.subtitle,
                        isSelected: selectedIntent == intent
                    ) {
                        withMotionAwareAnimation(.spring(duration: 0.3)) {
                            selectedIntent = intent
                        }
                        HapticService.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, AppTokens.Spacing.section)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleContinue()
        } label: {
            HStack(spacing: 8) {
                Text(currentStep == 0 ? "Continue" : "Get Started")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Image(systemName: currentStep == 0 ? "arrow.right" : "arrow.right.circle.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonEnabled ? Color.skyBlue : Color.gray.opacity(0.3))
            .foregroundStyle(buttonEnabled ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.xl))
        }
        .disabled(!buttonEnabled)
        .motionAwareAnimation(.spring(duration: 0.3), value: buttonEnabled)
    }

    private var buttonEnabled: Bool {
        switch currentStep {
        case 0: return selectedStage != nil
        case 1: return selectedIntent != nil
        default: return false
        }
    }

    private func handleContinue() {
        switch currentStep {
        case 0:
            withMotionAwareAnimation(.spring(duration: 0.5)) {
                currentStep = 1
            }
        case 1:
            guard let stage = selectedStage, let intent = selectedIntent else { return }
            HapticService.success()
            onboarding.completeOnboarding(stage: stage, intent: intent)
        default:
            break
        }
    }
}

// MARK: - Option Card

/// A tap-to-select card used in both onboarding steps.
private struct OnboardingOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.skyBlue : .secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.skyBlue : Color.gray.opacity(0.3))
            }
            .padding()
            .background(isSelected ? Color.skyBlue.opacity(AppTokens.Opacity.subtle) : .clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTokens.Radius.card)
                    .stroke(isSelected ? Color.skyBlue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

#Preview {
    OnboardingView()
        .environment(OnboardingManager())
}
