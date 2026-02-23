import Foundation
import UserNotifications

// MARK: - High-Value Notification Event

/// Every notification SoloTrack sends must be a response to a specific,
/// high-value moment — never a generic time-based nag. Each case encodes
/// the behavioral trigger and the data required to format a useful message.
enum NotificationEvent: Hashable {

    // ── 1. Currency Cliff ──────────────────────────────────────────────
    // Trigger: Currency transitions into caution (≤30 days) or danger (≤7 days).
    // Why it matters: Legal compliance — flying without currency is an FAR violation.
    case currencyCliff(kind: CurrencyKind, daysRemaining: Int)

    // ── 2. Milestone Crossed ───────────────────────────────────────────
    // Trigger: A PPL requirement's `isMet` transitions from false → true after a flight is saved.
    // Why it matters: Concrete progress confirmation during a long training journey.
    case milestoneCrossed(requirementTitle: String, farReference: String)

    // ── 3. Checkride Ready ─────────────────────────────────────────────
    // Trigger: All 6 FAR 61.109 requirements are met for the first time.
    // Why it matters: The single biggest milestone in the app — student is checkride-eligible.
    case checkrideReady

    // ── 4. Training Momentum Stall ─────────────────────────────────────
    // Trigger: No flights logged in 14+ days AND unmet requirements exist.
    // Why it matters: Re-engagement at a contextually relevant moment (skills degrade).
    case momentumStall(daysSinceLastFlight: Int, nextRequirement: String, remainingHours: Double)

    /// Category key for rate-limiting. Notifications in the same category
    /// share a cooldown timer.
    var category: String {
        switch self {
        case .currencyCliff:   return "currency_cliff"
        case .milestoneCrossed: return "milestone_crossed"
        case .checkrideReady:  return "checkride_ready"
        case .momentumStall:   return "momentum_stall"
        }
    }
}

// MARK: - Currency Kind

enum CurrencyKind: String, Hashable {
    case day   = "Day"
    case night = "Night"
}

// MARK: - Scored Event (internal pipeline artifact)

/// Pairs an event with its computed value score. Only events that cross
/// the send threshold survive the pipeline.
struct ScoredEvent {
    let event: NotificationEvent
    let score: Double          // 0.0 – 1.0
    let title: String
    let body: String
}

// MARK: - Notification Preferences

/// User-configurable preferences stored in UserDefaults.
/// Controls what the user has opted into, plus per-category cooldowns.
struct NotificationPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Opt-in Flags

    var currencyAlertsEnabled: Bool {
        get { defaults.object(forKey: Keys.currencyAlerts) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.currencyAlerts) }
    }

    var milestoneAlertsEnabled: Bool {
        get { defaults.object(forKey: Keys.milestoneAlerts) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.milestoneAlerts) }
    }

    var momentumAlertsEnabled: Bool {
        get { defaults.object(forKey: Keys.momentumAlerts) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.momentumAlerts) }
    }

    // MARK: - Cooldown Tracking

    /// Returns the date of the last notification sent for a given category.
    func lastSentDate(for category: String) -> Date? {
        defaults.object(forKey: Keys.lastSentPrefix + category) as? Date
    }

    /// Records that a notification was sent now for this category.
    func recordSent(for category: String, at date: Date = .now) {
        defaults.set(date, forKey: Keys.lastSentPrefix + category)
    }

    /// Returns the timestamp of the last notification of *any* category.
    var lastGlobalSendDate: Date? {
        get { defaults.object(forKey: Keys.globalLastSent) as? Date }
        set { defaults.set(newValue, forKey: Keys.globalLastSent) }
    }

    /// Running count of notifications sent today (resets on date change).
    func notificationsSentToday(asOf date: Date = .now) -> Int {
        guard let storedDate = defaults.object(forKey: Keys.dailyCountDate) as? Date else { return 0 }
        if Calendar.current.isDate(storedDate, inSameDayAs: date) {
            return defaults.integer(forKey: Keys.dailyCount)
        }
        return 0
    }

    func incrementDailyCount(asOf date: Date = .now) {
        let currentCount = notificationsSentToday(asOf: date)
        defaults.set(date, forKey: Keys.dailyCountDate)
        defaults.set(currentCount + 1, forKey: Keys.dailyCount)
    }

    // MARK: - Milestone Memory

    /// Set of FAR references that have already triggered a milestone notification.
    /// Prevents the same requirement from firing twice.
    var acknowledgedMilestones: Set<String> {
        get {
            let array = defaults.stringArray(forKey: Keys.acknowledgedMilestones) ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: Keys.acknowledgedMilestones)
        }
    }

    var hasNotifiedCheckrideReady: Bool {
        get { defaults.bool(forKey: Keys.checkrideReadyNotified) }
        set { defaults.set(newValue, forKey: Keys.checkrideReadyNotified) }
    }

    // MARK: - Keys

    private enum Keys {
        static let currencyAlerts       = "notif_currency_alerts"
        static let milestoneAlerts      = "notif_milestone_alerts"
        static let momentumAlerts       = "notif_momentum_alerts"
        static let lastSentPrefix       = "notif_last_sent_"
        static let globalLastSent       = "notif_global_last_sent"
        static let dailyCount           = "notif_daily_count"
        static let dailyCountDate       = "notif_daily_count_date"
        static let acknowledgedMilestones = "notif_acknowledged_milestones"
        static let checkrideReadyNotified = "notif_checkride_ready_notified"
    }
}

// MARK: - Notification Service

/// Evaluates user events against value heuristics, applies rate limiting,
/// and dispatches only notifications that clear the "high-value" bar.
///
/// Architecture:
/// ```
///  Flight Saved / App Foreground
///        │
///        ▼
///  ┌─────────────┐
///  │  Evaluator   │  Detects events from current state vs. prior state
///  └──────┬──────┘
///         │  [NotificationEvent]
///         ▼
///  ┌─────────────┐
///  │ Value Scorer │  Assigns 0.0–1.0 score based on context & training stage
///  └──────┬──────┘
///         │  [ScoredEvent] (score ≥ threshold only)
///         ▼
///  ┌─────────────┐
///  │ Rate Limiter │  Checks per-category cooldown + daily global cap
///  └──────┬──────┘
///         │  [ScoredEvent] (survivors only)
///         ▼
///  ┌─────────────┐
///  │  Dispatcher  │  Formats & schedules UNNotificationRequest
///  └─────────────┘
/// ```
struct NotificationService {

    // MARK: - Configuration

    /// Minimum value score required to send a notification.
    static let sendThreshold: Double = 0.5

    /// Maximum notifications per calendar day.
    static let dailyCap: Int = 2

    /// Per-category cooldown periods.
    static let cooldowns: [String: TimeInterval] = [
        "currency_cliff":   7 * 86_400,    // 7 days
        "milestone_crossed": 24 * 3_600,   // 24 hours
        "checkride_ready":  Double.infinity, // once ever
        "momentum_stall":   14 * 86_400,   // 14 days
    ]

    /// Minimum gap between any two notifications, regardless of category.
    static let globalCooldown: TimeInterval = 4 * 3_600  // 4 hours

    private let preferences: NotificationPreferences
    private let center: UNUserNotificationCenter

    init(
        preferences: NotificationPreferences = NotificationPreferences(),
        center: UNUserNotificationCenter = .current()
    ) {
        self.preferences = preferences
        self.center = center
    }

    // MARK: - Public API

    /// Request notification authorization (call once, early in app lifecycle).
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Main entry point. Evaluates a batch of candidate events, scores them,
    /// rate-limits, and dispatches survivors. Returns the events that were sent.
    @discardableResult
    func evaluate(
        _ events: [NotificationEvent],
        trainingStage: TrainingStage,
        asOf date: Date = .now
    ) async -> [NotificationEvent] {
        // 1. Score each event
        let scored = events.compactMap { score(event: $0, trainingStage: trainingStage) }

        // 2. Sort by value (highest first) — if we hit the daily cap, the
        //    most valuable notification wins.
        let ranked = scored.sorted { $0.score > $1.score }

        // 3. Filter through rate limiter and dispatch
        var sent: [NotificationEvent] = []
        for candidate in ranked {
            guard passesRateLimits(candidate.event, asOf: date) else { continue }
            await dispatch(candidate)
            recordDelivery(candidate.event, at: date)
            sent.append(candidate.event)
        }

        return sent
    }

    // MARK: - Value Scoring

    /// Assigns a value score (0.0–1.0) to an event. Returns nil if the event
    /// is below threshold or disabled by user preference.
    func score(event: NotificationEvent, trainingStage: TrainingStage) -> ScoredEvent? {
        guard isEnabledByUser(event) else { return nil }

        let (baseScore, title, body) = scoreAndFormat(event: event, trainingStage: trainingStage)
        guard baseScore >= Self.sendThreshold else { return nil }

        return ScoredEvent(event: event, score: baseScore, title: title, body: body)
    }

    private func scoreAndFormat(
        event: NotificationEvent,
        trainingStage: TrainingStage
    ) -> (score: Double, title: String, body: String) {
        switch event {

        // ── Currency Cliff ─────────────────────────────────────────────
        case .currencyCliff(let kind, let daysRemaining):
            let baseScore: Double
            let title: String
            let body: String

            if daysRemaining <= 3 {
                // CRITICAL: Legal compliance at immediate risk.
                baseScore = 0.95
                title = "\(kind.rawValue) Currency Expires in \(daysRemaining)d"
                body = daysRemaining == 1
                    ? "After tomorrow you won't be legal to carry passengers. One flight with \(kind == .day ? "3 landings" : "3 night full-stops") resets the clock."
                    : "You have \(daysRemaining) days before your \(kind.rawValue.lowercased()) currency lapses under FAR 61.57. A quick pattern session keeps you current."

            } else if daysRemaining <= 7 {
                // URGENT: A week to act.
                baseScore = 0.85
                title = "\(kind.rawValue) Currency: \(daysRemaining) Days Left"
                body = "Your \(kind.rawValue.lowercased()) currency expires in \(daysRemaining) days. Plan a flight this week to stay legal."

            } else {
                // CAUTION: Under 30 days — a gentle heads-up.
                baseScore = 0.6
                title = "Currency Heads-Up"
                body = "Your \(kind.rawValue.lowercased()) currency expires in \(daysRemaining) days. No rush, but keep it on your radar."
            }

            return (baseScore, title, body)

        // ── Milestone Crossed ──────────────────────────────────────────
        case .milestoneCrossed(let requirementTitle, _):
            let title = "\(requirementTitle) — Complete"
            let body = "You just met the \(requirementTitle) requirement. That's real progress toward your PPL."
            // Slightly boosted for checkride-prep students (every requirement matters more).
            let boost: Double = trainingStage == .checkridPrep ? 0.1 : 0.0
            return (0.75 + boost, title, body)

        // ── Checkride Ready ────────────────────────────────────────────
        case .checkrideReady:
            let title = "All PPL Requirements Met"
            let body = "Every FAR 61.109 box is checked. Talk to your CFI about scheduling that checkride."
            return (1.0, title, body)

        // ── Momentum Stall ─────────────────────────────────────────────
        case .momentumStall(let daysSince, let nextReq, let remaining):
            let remainingFormatted = String(format: "%.1f", remaining)
            let title = "\(daysSince) Days Since Your Last Flight"
            let body = "You're \(remainingFormatted) hrs from completing \(nextReq). Skills stay sharp when the gaps stay short."

            // Higher value for checkride-prep students (stakes are higher).
            var baseScore = 0.55
            if trainingStage == .checkridPrep { baseScore = 0.75 }
            if daysSince >= 30 { baseScore += 0.1 }

            return (min(baseScore, 1.0), title, body)
        }
    }

    // MARK: - Rate Limiting

    /// Returns true if the event is allowed through the rate limiter.
    func passesRateLimits(_ event: NotificationEvent, asOf date: Date = .now) -> Bool {
        // Gate 1: Daily cap
        if preferences.notificationsSentToday(asOf: date) >= Self.dailyCap {
            return false
        }

        // Gate 2: Global cooldown (avoid notification bursts)
        if let lastGlobal = preferences.lastGlobalSendDate,
           date.timeIntervalSince(lastGlobal) < Self.globalCooldown {
            return false
        }

        // Gate 3: Per-category cooldown
        let category = event.category
        if let cooldown = Self.cooldowns[category],
           let lastSent = preferences.lastSentDate(for: category),
           date.timeIntervalSince(lastSent) < cooldown {
            return false
        }

        // Gate 4: One-time events
        switch event {
        case .checkrideReady:
            if preferences.hasNotifiedCheckrideReady { return false }
        case .milestoneCrossed(_, let farRef):
            if preferences.acknowledgedMilestones.contains(farRef) { return false }
        default:
            break
        }

        return true
    }

    // MARK: - Dispatch

    private func dispatch(_ scored: ScoredEvent) async {
        let content = UNMutableNotificationContent()
        content.title = scored.title
        content.body = scored.body
        content.sound = .default
        content.categoryIdentifier = scored.event.category

        let request = UNNotificationRequest(
            identifier: "\(scored.event.category)_\(UUID().uuidString)",
            content: content,
            trigger: nil  // Deliver immediately
        )

        try? await center.add(request)
    }

    // MARK: - Record Keeping

    private func recordDelivery(_ event: NotificationEvent, at date: Date) {
        preferences.recordSent(for: event.category, at: date)
        preferences.lastGlobalSendDate = date
        preferences.incrementDailyCount(asOf: date)

        switch event {
        case .checkrideReady:
            preferences.hasNotifiedCheckrideReady = true
        case .milestoneCrossed(_, let farRef):
            var milestones = preferences.acknowledgedMilestones
            milestones.insert(farRef)
            preferences.acknowledgedMilestones = milestones
        default:
            break
        }
    }

    // MARK: - User Preference Check

    private func isEnabledByUser(_ event: NotificationEvent) -> Bool {
        switch event {
        case .currencyCliff:
            return preferences.currencyAlertsEnabled
        case .milestoneCrossed, .checkrideReady:
            return preferences.milestoneAlertsEnabled
        case .momentumStall:
            return preferences.momentumAlertsEnabled
        }
    }
}
