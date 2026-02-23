import Foundation

// MARK: - Notification Evaluator

/// Inspects the current flight data to detect high-value notification moments.
///
/// This is the "event bus" — it runs all four heuristics against the current
/// state and returns zero or more `NotificationEvent` values. The downstream
/// `NotificationService` handles scoring, rate limiting, and dispatch.
///
/// Call sites:
///   1. After a flight is saved (detect milestones & currency shifts)
///   2. On app foreground (detect stalls & currency decay since last open)
struct NotificationEvaluator {
    private let currencyManager = CurrencyManager()
    private let progressTracker = ProgressTracker()
    private let preferences: NotificationPreferences

    init(preferences: NotificationPreferences = NotificationPreferences()) {
        self.preferences = preferences
    }

    /// Evaluates all heuristics against the current flights and returns
    /// candidate events. Does NOT filter by rate limits — that's the service's job.
    func detectEvents(
        flights: [FlightLog],
        trainingStage: TrainingStage,
        asOf date: Date = .now
    ) -> [NotificationEvent] {
        var events: [NotificationEvent] = []

        events.append(contentsOf: detectCurrencyCliffs(flights: flights, asOf: date))
        events.append(contentsOf: detectMilestones(flights: flights))
        if let ready = detectCheckrideReady(flights: flights) {
            events.append(ready)
        }
        if let stall = detectMomentumStall(flights: flights, asOf: date) {
            events.append(stall)
        }

        return events
    }

    // MARK: - Heuristic 1: Currency Cliff

    /// Fires when day or night currency enters caution (≤30 days remaining).
    private func detectCurrencyCliffs(flights: [FlightLog], asOf date: Date) -> [NotificationEvent] {
        var events: [NotificationEvent] = []

        let day = currencyManager.dayCurrency(flights: flights, asOf: date)
        if let event = currencyEvent(state: day, kind: .day) {
            events.append(event)
        }

        let night = currencyManager.nightCurrency(flights: flights, asOf: date)
        if let event = currencyEvent(state: night, kind: .night) {
            events.append(event)
        }

        return events
    }

    private func currencyEvent(state: CurrencyState, kind: CurrencyKind) -> NotificationEvent? {
        switch state {
        case .caution(let days):
            return .currencyCliff(kind: kind, daysRemaining: days)
        case .valid, .expired:
            // Valid = nothing to warn about. Expired = too late for a nudge
            // (dashboard already shows red state on next open).
            return nil
        }
    }

    // MARK: - Heuristic 2: Milestone Crossed

    /// Fires when a PPL requirement is newly met (not previously acknowledged).
    private func detectMilestones(flights: [FlightLog]) -> [NotificationEvent] {
        let requirements = progressTracker.computeRequirements(from: flights)
        let acknowledged = preferences.acknowledgedMilestones

        return requirements
            .filter { $0.isMet && !acknowledged.contains($0.farReference) }
            .map { .milestoneCrossed(requirementTitle: $0.title, farReference: $0.farReference) }
    }

    // MARK: - Heuristic 3: Checkride Ready

    /// Fires once when all 6 PPL requirements are met for the first time.
    private func detectCheckrideReady(flights: [FlightLog]) -> NotificationEvent? {
        guard !preferences.hasNotifiedCheckrideReady else { return nil }

        let metCount = progressTracker.requirementsMet(from: flights)
        let total = progressTracker.totalRequirements()

        return metCount >= total ? .checkrideReady : nil
    }

    // MARK: - Heuristic 4: Momentum Stall

    /// Fires when no flights in 14+ days and unmet requirements remain.
    private func detectMomentumStall(
        flights: [FlightLog],
        asOf date: Date
    ) -> NotificationEvent? {
        guard let mostRecent = flights.max(by: { $0.date < $1.date }) else { return nil }

        let daysSince = Calendar.current.dateComponents([.day], from: mostRecent.date, to: date).day ?? 0
        guard daysSince >= 14 else { return nil }

        // Only fire if there's still something to work toward.
        let requirements = progressTracker.computeRequirements(from: flights)
        guard let nextUnmet = requirements.first(where: { !$0.isMet }) else { return nil }

        return .momentumStall(
            daysSinceLastFlight: daysSince,
            nextRequirement: nextUnmet.title,
            remainingHours: nextUnmet.remainingHours
        )
    }
}
