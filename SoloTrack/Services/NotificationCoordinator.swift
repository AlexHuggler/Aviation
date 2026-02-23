import SwiftUI
import SwiftData

// MARK: - Notification Coordinator

/// ViewModifier that wires notification evaluation into the SwiftUI lifecycle.
///
/// Attach to the root view. Evaluates heuristics in two situations:
///   1. **Flight count changes** — detects milestones and currency shifts after save.
///   2. **App returns to foreground** — detects momentum stalls and currency decay.
struct NotificationCoordinator: ViewModifier {
    @Query(sort: \FlightLog.date, order: .reverse) private var flights: [FlightLog]
    @Environment(OnboardingManager.self) private var onboarding
    @Environment(\.scenePhase) private var scenePhase

    private let service = NotificationService()
    private let evaluator = NotificationEvaluator()

    /// Track flight count to detect saves/deletes.
    @State private var lastKnownFlightCount = 0

    func body(content: Content) -> some View {
        content
            .task {
                await service.requestAuthorization()
            }
            .onChange(of: flights.count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                // A flight was added — check for milestones and currency changes.
                Task {
                    let events = evaluator.detectEvents(
                        flights: flights,
                        trainingStage: onboarding.trainingStage
                    )
                    await service.evaluate(
                        events,
                        trainingStage: onboarding.trainingStage
                    )
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                guard onboarding.hasCompletedOnboarding else { return }
                guard !flights.isEmpty else { return }
                // App foregrounded — check for stalls and currency decay.
                Task {
                    let events = evaluator.detectEvents(
                        flights: flights,
                        trainingStage: onboarding.trainingStage
                    )
                    await service.evaluate(
                        events,
                        trainingStage: onboarding.trainingStage
                    )
                }
            }
    }
}

extension View {
    func notificationCoordinator() -> some View {
        modifier(NotificationCoordinator())
    }
}
