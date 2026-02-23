import Testing
import Foundation
@testable import SoloTrack

// MARK: - NotificationService Tests

@Suite("NotificationService — Value scoring, rate limiting, and event evaluation")
struct NotificationServiceTests {
    let calendar = Calendar.current

    // Use a fresh UserDefaults suite for each test to avoid cross-contamination.
    private func freshPreferences() -> NotificationPreferences {
        let suiteName = "test_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return NotificationPreferences(defaults: defaults)
    }

    private func service(preferences: NotificationPreferences? = nil) -> NotificationService {
        let prefs = preferences ?? freshPreferences()
        return NotificationService(preferences: prefs, center: .current())
    }

    // MARK: - Helpers

    private func flight(
        daysAgo: Int,
        hobbs: Double = 1.0,
        dayLandings: Int = 1,
        nightFullStop: Int = 0,
        solo: Bool = false,
        dual: Bool = false,
        xc: Bool = false,
        instrument: Bool = false,
        referenceDate: Date = .now
    ) -> FlightLog {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        return FlightLog(
            date: date,
            durationHobbs: hobbs,
            landingsDay: dayLandings,
            landingsNightFullStop: nightFullStop,
            isSolo: solo,
            isDualReceived: dual,
            isCrossCountry: xc,
            isSimulatedInstrument: instrument
        )
    }

    // MARK: - Value Scoring

    @Test("Currency cliff ≤3 days scores ≥0.9")
    func currencyCliffCriticalScore() {
        let svc = service()
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 2)
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored != nil)
        #expect(scored!.score >= 0.9)
    }

    @Test("Currency cliff ≤7 days scores ≥0.8")
    func currencyCliffUrgentScore() {
        let svc = service()
        let event = NotificationEvent.currencyCliff(kind: .night, daysRemaining: 5)
        let scored = svc.score(event: event, trainingStage: .preSolo)
        #expect(scored != nil)
        #expect(scored!.score >= 0.8)
    }

    @Test("Currency cliff 20 days scores ≥0.5 (caution threshold)")
    func currencyCliffCautionScore() {
        let svc = service()
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 20)
        let scored = svc.score(event: event, trainingStage: .preSolo)
        #expect(scored != nil)
        #expect(scored!.score >= 0.5)
    }

    @Test("Milestone crossed scores ≥0.75")
    func milestoneCrossedScore() {
        let svc = service()
        let event = NotificationEvent.milestoneCrossed(
            requirementTitle: "Solo Flight",
            farReference: "61.109(a)(2)"
        )
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored != nil)
        #expect(scored!.score >= 0.75)
    }

    @Test("Milestone score boosted for checkride prep")
    func milestoneBoostedForCheckride() {
        let svc = service()
        let event = NotificationEvent.milestoneCrossed(
            requirementTitle: "Instrument Training",
            farReference: "61.109(a)(3)"
        )
        let postSolo = svc.score(event: event, trainingStage: .postSolo)
        let checkride = svc.score(event: event, trainingStage: .checkridPrep)
        #expect(postSolo != nil)
        #expect(checkride != nil)
        #expect(checkride!.score > postSolo!.score)
    }

    @Test("Checkride ready scores 1.0 (maximum)")
    func checkrideReadyMaxScore() {
        let svc = service()
        let event = NotificationEvent.checkrideReady
        let scored = svc.score(event: event, trainingStage: .checkridPrep)
        #expect(scored != nil)
        #expect(scored!.score == 1.0)
    }

    @Test("Momentum stall scores ≥0.5")
    func momentumStallBaseScore() {
        let svc = service()
        let event = NotificationEvent.momentumStall(
            daysSinceLastFlight: 18,
            nextRequirement: "Solo Cross-Country",
            remainingHours: 3.5
        )
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored != nil)
        #expect(scored!.score >= 0.5)
    }

    @Test("Momentum stall scores higher for checkride prep")
    func momentumStallBoostedForCheckride() {
        let svc = service()
        let event = NotificationEvent.momentumStall(
            daysSinceLastFlight: 20,
            nextRequirement: "Night Training",
            remainingHours: 1.5
        )
        let postSolo = svc.score(event: event, trainingStage: .postSolo)
        let checkride = svc.score(event: event, trainingStage: .checkridPrep)
        #expect(checkride!.score > postSolo!.score)
    }

    // MARK: - Rate Limiting

    @Test("Fresh state passes all rate limits")
    func freshStatePassesLimits() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 5)
        #expect(svc.passesRateLimits(event))
    }

    @Test("Same category within cooldown is blocked")
    func categoryCooldownBlocks() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 5)

        // Simulate a recent send
        prefs.recordSent(for: event.category)

        #expect(!svc.passesRateLimits(event))
    }

    @Test("Category cooldown passes after sufficient time")
    func categoryCooldownPassesAfterTime() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 5)

        // Simulate send 8 days ago (cooldown is 7 days)
        let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: .now)!
        prefs.recordSent(for: event.category, at: eightDaysAgo)

        // Also set global send in the past to avoid global cooldown blocking
        prefs.lastGlobalSendDate = eightDaysAgo

        #expect(svc.passesRateLimits(event))
    }

    @Test("Daily cap blocks after 2 notifications in same day")
    func dailyCapBlocks() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())

        prefs.incrementDailyCount()
        prefs.incrementDailyCount()

        let event = NotificationEvent.momentumStall(
            daysSinceLastFlight: 20,
            nextRequirement: "Solo Flight",
            remainingHours: 5.0
        )
        #expect(!svc.passesRateLimits(event))
    }

    @Test("Global cooldown blocks notifications sent too close together")
    func globalCooldownBlocks() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())

        // Simulate global send 1 hour ago (cooldown is 4 hours)
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: .now)!
        prefs.lastGlobalSendDate = oneHourAgo

        let event = NotificationEvent.milestoneCrossed(
            requirementTitle: "Dual Instruction",
            farReference: "61.109(a)(1)"
        )
        #expect(!svc.passesRateLimits(event))
    }

    @Test("Checkride ready blocked after first notification")
    func checkrideReadyOnceOnly() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())

        prefs.hasNotifiedCheckrideReady = true

        let event = NotificationEvent.checkrideReady
        #expect(!svc.passesRateLimits(event))
    }

    @Test("Acknowledged milestone blocked from re-firing")
    func acknowledgedMilestoneBlocked() {
        let prefs = freshPreferences()
        let svc = NotificationService(preferences: prefs, center: .current())

        var milestones = prefs.acknowledgedMilestones
        milestones.insert("61.109(a)(2)")
        prefs.acknowledgedMilestones = milestones

        let event = NotificationEvent.milestoneCrossed(
            requirementTitle: "Solo Flight",
            farReference: "61.109(a)(2)"
        )
        #expect(!svc.passesRateLimits(event))
    }

    // MARK: - User Preference Opt-out

    @Test("Disabled currency alerts returns nil score")
    func disabledCurrencyAlerts() {
        let prefs = freshPreferences()
        prefs.currencyAlertsEnabled = false
        let svc = NotificationService(preferences: prefs, center: .current())

        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 3)
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored == nil)
    }

    @Test("Disabled milestone alerts returns nil score")
    func disabledMilestoneAlerts() {
        let prefs = freshPreferences()
        prefs.milestoneAlertsEnabled = false
        let svc = NotificationService(preferences: prefs, center: .current())

        let event = NotificationEvent.checkrideReady
        let scored = svc.score(event: event, trainingStage: .checkridPrep)
        #expect(scored == nil)
    }

    @Test("Disabled momentum alerts returns nil score")
    func disabledMomentumAlerts() {
        let prefs = freshPreferences()
        prefs.momentumAlertsEnabled = false
        let svc = NotificationService(preferences: prefs, center: .current())

        let event = NotificationEvent.momentumStall(
            daysSinceLastFlight: 21,
            nextRequirement: "Total Flight Time",
            remainingHours: 15.0
        )
        let scored = svc.score(event: event, trainingStage: .preSolo)
        #expect(scored == nil)
    }

    // MARK: - Copy Formatting

    @Test("Currency cliff copy includes days remaining")
    func currencyCliffCopyFormat() {
        let svc = service()
        let event = NotificationEvent.currencyCliff(kind: .day, daysRemaining: 5)
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored != nil)
        #expect(scored!.title.contains("5"))
        #expect(scored!.title.contains("Day"))
    }

    @Test("Milestone copy includes requirement title")
    func milestoneCopyFormat() {
        let svc = service()
        let event = NotificationEvent.milestoneCrossed(
            requirementTitle: "Night Training",
            farReference: "61.109(a)(2)(ii)"
        )
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored!.title.contains("Night Training"))
        #expect(scored!.body.contains("Night Training"))
    }

    @Test("Checkride ready copy mentions FAR 61.109")
    func checkrideReadyCopyFormat() {
        let svc = service()
        let scored = svc.score(event: .checkrideReady, trainingStage: .checkridPrep)
        #expect(scored!.body.contains("61.109"))
    }

    @Test("Momentum stall copy includes days and remaining hours")
    func momentumStallCopyFormat() {
        let svc = service()
        let event = NotificationEvent.momentumStall(
            daysSinceLastFlight: 21,
            nextRequirement: "Solo Cross-Country",
            remainingHours: 2.5
        )
        let scored = svc.score(event: event, trainingStage: .postSolo)
        #expect(scored!.title.contains("21"))
        #expect(scored!.body.contains("2.5"))
        #expect(scored!.body.contains("Solo Cross-Country"))
    }

    // MARK: - Event Categories

    @Test("Each event type has a unique category key")
    func uniqueCategories() {
        let events: [NotificationEvent] = [
            .currencyCliff(kind: .day, daysRemaining: 5),
            .milestoneCrossed(requirementTitle: "Test", farReference: "test"),
            .checkrideReady,
            .momentumStall(daysSinceLastFlight: 14, nextRequirement: "Test", remainingHours: 1.0),
        ]
        let categories = Set(events.map(\.category))
        #expect(categories.count == events.count)
    }
}

// MARK: - NotificationEvaluator Tests

@Suite("NotificationEvaluator — Behavioral event detection")
struct NotificationEvaluatorTests {
    let calendar = Calendar.current

    private func freshPreferences() -> NotificationPreferences {
        let suiteName = "test_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return NotificationPreferences(defaults: defaults)
    }

    private func flight(
        daysAgo: Int,
        hobbs: Double = 1.5,
        dayLandings: Int = 1,
        nightFullStop: Int = 0,
        solo: Bool = false,
        dual: Bool = false,
        xc: Bool = false,
        instrument: Bool = false,
        referenceDate: Date = .now
    ) -> FlightLog {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        return FlightLog(
            date: date,
            durationHobbs: hobbs,
            landingsDay: dayLandings,
            landingsNightFullStop: nightFullStop,
            isSolo: solo,
            isDualReceived: dual,
            isCrossCountry: xc,
            isSimulatedInstrument: instrument
        )
    }

    // MARK: - Currency Cliff Detection

    @Test("Detects day currency in caution zone")
    func detectsDayCurrencyCaution() {
        // 3 landings 75 days ago → ~15 days remaining → caution
        let flights = [flight(daysAgo: 75, dayLandings: 3)]
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .postSolo)

        let currencyEvents = events.filter {
            if case .currencyCliff(kind: .day, _) = $0 { return true }
            return false
        }
        #expect(!currencyEvents.isEmpty)
    }

    @Test("No currency event when fully current (>30 days)")
    func noCurrencyEventWhenCurrent() {
        // 3 landings today → 90 days remaining → valid, no notification
        let flights = [flight(daysAgo: 0, dayLandings: 3, nightFullStop: 3)]
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .postSolo)

        let currencyEvents = events.filter {
            if case .currencyCliff = $0 { return true }
            return false
        }
        #expect(currencyEvents.isEmpty)
    }

    @Test("No currency event when expired (too late for a nudge)")
    func noCurrencyEventWhenExpired() {
        let flights = [flight(daysAgo: 100, dayLandings: 3)]
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .postSolo)

        let currencyEvents = events.filter {
            if case .currencyCliff = $0 { return true }
            return false
        }
        #expect(currencyEvents.isEmpty)
    }

    // MARK: - Milestone Detection

    @Test("Detects newly met requirement as milestone")
    func detectsNewMilestone() {
        // 20+ hours of dual instruction → meets "Dual Instruction" requirement
        let flights = (0..<15).map { i in
            flight(daysAgo: i, hobbs: 1.5, dual: true)
        }
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .preSolo)

        let milestoneEvents = events.filter {
            if case .milestoneCrossed = $0 { return true }
            return false
        }
        #expect(!milestoneEvents.isEmpty)
    }

    @Test("Already acknowledged milestone is not re-detected")
    func acknowledgedMilestoneSkipped() {
        let flights = (0..<15).map { i in
            flight(daysAgo: i, hobbs: 1.5, dual: true)
        }
        let prefs = freshPreferences()
        prefs.acknowledgedMilestones = Set(["61.109(a)(1)"]) // Dual Instruction
        let evaluator = NotificationEvaluator(preferences: prefs)
        let events = evaluator.detectEvents(flights: flights, trainingStage: .preSolo)

        let dualMilestones = events.filter {
            if case .milestoneCrossed(_, let far) = $0, far == "61.109(a)(1)" { return true }
            return false
        }
        #expect(dualMilestones.isEmpty)
    }

    // MARK: - Checkride Ready Detection

    @Test("Detects checkride ready when all 6 requirements met")
    func detectsCheckrideReady() {
        // Build flights that satisfy all 6 FAR 61.109 requirements
        var flights: [FlightLog] = []

        // Dual instruction: 20+ hours
        flights.append(contentsOf: (0..<14).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, dual: true)
        })

        // Solo: 10+ hours, including 5+ XC
        flights.append(contentsOf: (14..<21).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, solo: true, xc: true)
        })

        // Night training: 3+ hours
        flights.append(contentsOf: (21..<24).map { i in
            flight(daysAgo: i, hobbs: 1.5, nightFullStop: 1, dual: true)
        })

        // Instrument training: 3+ hours
        flights.append(contentsOf: (24..<27).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, dual: true, instrument: true)
        })

        let prefs = freshPreferences()
        let evaluator = NotificationEvaluator(preferences: prefs)
        let events = evaluator.detectEvents(flights: flights, trainingStage: .checkridPrep)

        let checkrideEvents = events.filter {
            if case .checkrideReady = $0 { return true }
            return false
        }
        #expect(!checkrideEvents.isEmpty)
    }

    @Test("Checkride ready not detected if already notified")
    func checkrideReadyNotReDetected() {
        let flights = (0..<30).map { i in
            flight(daysAgo: i, hobbs: 2.0, dayLandings: 1, solo: true, dual: false, xc: true, instrument: true)
        }
        let prefs = freshPreferences()
        prefs.hasNotifiedCheckrideReady = true
        let evaluator = NotificationEvaluator(preferences: prefs)
        let events = evaluator.detectEvents(flights: flights, trainingStage: .checkridPrep)

        let checkrideEvents = events.filter {
            if case .checkrideReady = $0 { return true }
            return false
        }
        #expect(checkrideEvents.isEmpty)
    }

    // MARK: - Momentum Stall Detection

    @Test("Detects stall when no flights for 14+ days with unmet requirements")
    func detectsMomentumStall() {
        // One flight 20 days ago — not enough for all requirements
        let flights = [flight(daysAgo: 20, hobbs: 1.5, dual: true)]
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .postSolo)

        let stallEvents = events.filter {
            if case .momentumStall = $0 { return true }
            return false
        }
        #expect(!stallEvents.isEmpty)
    }

    @Test("No stall detected with recent flights")
    func noStallWithRecentFlights() {
        let flights = [flight(daysAgo: 3, hobbs: 1.5, dual: true)]
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .postSolo)

        let stallEvents = events.filter {
            if case .momentumStall = $0 { return true }
            return false
        }
        #expect(stallEvents.isEmpty)
    }

    @Test("No stall detected when all requirements met (nothing to work toward)")
    func noStallWhenAllRequirementsMet() {
        // Build flights satisfying all requirements, but 20 days ago
        var flights: [FlightLog] = []
        flights.append(contentsOf: (20..<34).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, dual: true)
        })
        flights.append(contentsOf: (34..<41).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, solo: true, xc: true)
        })
        flights.append(contentsOf: (41..<44).map { i in
            flight(daysAgo: i, hobbs: 1.5, nightFullStop: 1, dual: true)
        })
        flights.append(contentsOf: (44..<47).map { i in
            flight(daysAgo: i, hobbs: 1.5, dayLandings: 1, dual: true, instrument: true)
        })

        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: flights, trainingStage: .checkridPrep)

        let stallEvents = events.filter {
            if case .momentumStall = $0 { return true }
            return false
        }
        #expect(stallEvents.isEmpty)
    }

    @Test("No events from empty flight list")
    func noEventsFromEmptyFlights() {
        let evaluator = NotificationEvaluator(preferences: freshPreferences())
        let events = evaluator.detectEvents(flights: [], trainingStage: .preSolo)

        // Should have no stalls or milestones (might have expired currency, but
        // we don't fire notifications for already-expired currency)
        let stallEvents = events.filter {
            if case .momentumStall = $0 { return true }
            return false
        }
        let milestoneEvents = events.filter {
            if case .milestoneCrossed = $0 { return true }
            return false
        }
        #expect(stallEvents.isEmpty)
        #expect(milestoneEvents.isEmpty)
    }
}

// MARK: - NotificationPreferences Tests

@Suite("NotificationPreferences — Cooldown and state tracking")
struct NotificationPreferencesTests {
    private func freshPreferences() -> NotificationPreferences {
        let suiteName = "test_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return NotificationPreferences(defaults: defaults)
    }

    @Test("Default opt-in flags are all true")
    func defaultOptInsEnabled() {
        let prefs = freshPreferences()
        #expect(prefs.currencyAlertsEnabled)
        #expect(prefs.milestoneAlertsEnabled)
        #expect(prefs.momentumAlertsEnabled)
    }

    @Test("Daily count resets across days")
    func dailyCountResets() {
        let prefs = freshPreferences()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!

        // Increment count "yesterday"
        prefs.incrementDailyCount(asOf: yesterday)
        prefs.incrementDailyCount(asOf: yesterday)

        // Today's count should be 0 (different day)
        #expect(prefs.notificationsSentToday() == 0)
    }

    @Test("Daily count increments correctly within same day")
    func dailyCountIncrements() {
        let prefs = freshPreferences()
        #expect(prefs.notificationsSentToday() == 0)

        prefs.incrementDailyCount()
        #expect(prefs.notificationsSentToday() == 1)

        prefs.incrementDailyCount()
        #expect(prefs.notificationsSentToday() == 2)
    }

    @Test("Acknowledged milestones persist")
    func acknowledgedMilestonesPersist() {
        let prefs = freshPreferences()
        #expect(prefs.acknowledgedMilestones.isEmpty)

        var milestones = prefs.acknowledgedMilestones
        milestones.insert("61.109(a)")
        milestones.insert("61.109(a)(1)")
        prefs.acknowledgedMilestones = milestones

        #expect(prefs.acknowledgedMilestones.count == 2)
        #expect(prefs.acknowledgedMilestones.contains("61.109(a)"))
        #expect(prefs.acknowledgedMilestones.contains("61.109(a)(1)"))
    }

    @Test("Last sent date records and retrieves correctly")
    func lastSentDateTracking() {
        let prefs = freshPreferences()
        #expect(prefs.lastSentDate(for: "test_category") == nil)

        let now = Date.now
        prefs.recordSent(for: "test_category", at: now)

        let stored = prefs.lastSentDate(for: "test_category")
        #expect(stored != nil)
        // Allow 1 second tolerance for Date precision
        #expect(abs(stored!.timeIntervalSince(now)) < 1.0)
    }
}
