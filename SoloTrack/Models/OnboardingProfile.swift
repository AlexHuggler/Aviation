import Foundation
import SwiftUI

// MARK: - Training Stage Persona

/// Represents where the student pilot is in their training journey.
/// Drives conditional defaults and dashboard emphasis.
enum TrainingStage: String, CaseIterable, Codable {
    case preSolo = "pre_solo"
    case postSolo = "post_solo"
    case checkridPrep = "checkride_prep"

    var displayTitle: String {
        switch self {
        case .preSolo: return "Pre-Solo"
        case .postSolo: return "Post-Solo"
        case .checkridPrep: return "Checkride Prep"
        }
    }

    var icon: String {
        switch self {
        case .preSolo: return "person.and.person.fill"
        case .postSolo: return "airplane"
        case .checkridPrep: return "checkmark.seal.fill"
        }
    }

    var tagline: String {
        switch self {
        case .preSolo: return "Building the foundation"
        case .postSolo: return "Building hours & confidence"
        case .checkridPrep: return "Almost there"
        }
    }

    // MARK: - Branching Logic: Flight Form Defaults

    /// Default flight category toggle states based on training stage.
    var defaultIsSolo: Bool {
        switch self {
        case .preSolo: return false
        case .postSolo: return true
        case .checkridPrep: return true
        }
    }

    var defaultIsDualReceived: Bool {
        switch self {
        case .preSolo: return true
        case .postSolo: return false
        case .checkridPrep: return false
        }
    }

    // MARK: - Branching Logic: Dashboard Emphasis

    /// Which dashboard section should be visually highlighted for this persona.
    var primaryDashboardFocus: DashboardFocus {
        switch self {
        case .preSolo: return .currency
        case .postSolo: return .progress
        case .checkridPrep: return .progressGaps
        }
    }

    /// Motivational greeting shown after onboarding completes.
    var welcomeMessage: String {
        switch self {
        case .preSolo:
            return "Every hour in the logbook is a step closer to solo. Let's track them all."
        case .postSolo:
            return "You've soloed — now let's build toward that checkride. Every flight counts."
        case .checkridPrep:
            return "The finish line is in sight. Let's make sure every requirement is checked off."
        }
    }
}

// MARK: - Dashboard Focus

enum DashboardFocus: String, Codable {
    case currency       // Emphasize Day/Night currency cards
    case progress       // Emphasize PPL progress ring
    case progressGaps   // Emphasize unmet requirements
}

// MARK: - Getting Started Intent

/// What the user wants to do immediately after onboarding.
enum GettingStartedIntent: String, CaseIterable, Codable {
    case logFresh = "log_fresh"
    case backfill = "backfill"
    case explore = "explore"

    var displayTitle: String {
        switch self {
        case .logFresh: return "Log a flight"
        case .backfill: return "Enter past flights"
        case .explore: return "Explore the app"
        }
    }

    var subtitle: String {
        switch self {
        case .logFresh: return "I just flew or have a recent flight to log"
        case .backfill: return "I want to backfill flights from my paper logbook"
        case .explore: return "Show me around first"
        }
    }

    var icon: String {
        switch self {
        case .logFresh: return "plus.circle.fill"
        case .backfill: return "clock.arrow.circlepath"
        case .explore: return "binoculars.fill"
        }
    }
}

// MARK: - Coach Mark Step

/// Sequential interactive tour steps shown during the "explore" flow.
enum CoachMarkStep: Int, CaseIterable, Codable, Comparable {
    case dashboardWelcome = 0
    case currencyCards = 1
    case progressTab = 2
    case logbookTab = 3
    case addFlightButton = 4
    case tourComplete = 5

    static func < (lhs: CoachMarkStep, rhs: CoachMarkStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .dashboardWelcome: return "Your Home Base"
        case .currencyCards: return "Currency at a Glance"
        case .progressTab: return "Track Your Progress"
        case .logbookTab: return "Your Digital Logbook"
        case .addFlightButton: return "Log Your First Flight"
        case .tourComplete: return "You're All Set!"
        }
    }

    var body: String {
        switch self {
        case .dashboardWelcome:
            return "This is your dashboard — your flight status at a glance. It updates automatically as you log flights."
        case .currencyCards:
            return "These cards show your Day and Night currency under FAR 61.57. Green means you're legal to carry passengers."
        case .progressTab:
            return "Tap Progress to see exactly where you stand on each FAR 61.109 PPL requirement."
        case .logbookTab:
            return "Your Logbook holds every flight — searchable, exportable, and ready for your CFI's signature."
        case .addFlightButton:
            return "Tap + to log a flight. SoloTrack remembers your last route and settings to save you time."
        case .tourComplete:
            return "That's the tour! Log your first flight whenever you're ready."
        }
    }

    var icon: String {
        switch self {
        case .dashboardWelcome: return "gauge.with.dots.needle.33percent"
        case .currencyCards: return "shield.checkered"
        case .progressTab: return "chart.bar.fill"
        case .logbookTab: return "book.closed.fill"
        case .addFlightButton: return "plus.circle.fill"
        case .tourComplete: return "checkmark.circle.fill"
        }
    }

    /// Which tab should be selected during this coach mark step.
    var associatedTab: Int? {
        switch self {
        case .dashboardWelcome, .currencyCards, .addFlightButton, .tourComplete: return 0
        case .progressTab: return 1
        case .logbookTab: return 2
        }
    }

    var next: CoachMarkStep? {
        CoachMarkStep(rawValue: rawValue + 1)
    }
}

// MARK: - Onboarding State Manager

/// Centralized onboarding state with @Observable tracking.
/// Stored properties are tracked by the @Observable macro; UserDefaults is used
/// for persistence only (synced in didSet, restored in init).
@MainActor @Observable
final class OnboardingManager {
    // MARK: - Persisted State (backed by stored properties for @Observable tracking)

    /// Whether the user has completed the initial questionnaire.
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboardingCompleted) }
    }

    /// Whether the interactive tour has been completed or dismissed.
    var hasCompletedTour: Bool {
        didSet { UserDefaults.standard.set(hasCompletedTour, forKey: Keys.tourCompleted) }
    }

    /// The user's selected training stage.
    var trainingStage: TrainingStage {
        didSet { UserDefaults.standard.set(trainingStage.rawValue, forKey: Keys.trainingStage) }
    }

    /// What the user chose to do after onboarding.
    var gettingStartedIntent: GettingStartedIntent {
        didSet { UserDefaults.standard.set(gettingStartedIntent.rawValue, forKey: Keys.gettingStartedIntent) }
    }

    // MARK: - Transient Tour State

    /// Current step in the interactive coach mark tour.
    var currentCoachStep: CoachMarkStep? = nil

    /// Whether the onboarding questionnaire sheet should be presented.
    var showOnboardingSheet: Bool = false

    /// Whether we should auto-open AddFlightView after onboarding.
    var shouldOpenAddFlight: Bool = false

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let onboardingCompleted = "onboarding_completed"
        static let tourCompleted = "tour_completed"
        static let trainingStage = "training_stage"
        static let gettingStartedIntent = "getting_started_intent"
    }

    // MARK: - Init (restore from UserDefaults)

    init() {
        let defaults = UserDefaults.standard
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.onboardingCompleted)
        self.hasCompletedTour = defaults.bool(forKey: Keys.tourCompleted)

        if let raw = defaults.string(forKey: Keys.trainingStage),
           let stage = TrainingStage(rawValue: raw) {
            self.trainingStage = stage
        } else {
            self.trainingStage = .preSolo
        }

        if let raw = defaults.string(forKey: Keys.gettingStartedIntent),
           let intent = GettingStartedIntent(rawValue: raw) {
            self.gettingStartedIntent = intent
        } else {
            self.gettingStartedIntent = .explore
        }
    }

    // MARK: - Actions

    func completeOnboarding(stage: TrainingStage, intent: GettingStartedIntent) {
        trainingStage = stage
        gettingStartedIntent = intent
        hasCompletedOnboarding = true
        showOnboardingSheet = false

        switch intent {
        case .logFresh, .backfill:
            shouldOpenAddFlight = true
        case .explore:
            currentCoachStep = .dashboardWelcome
        }
    }

    func advanceTour() {
        guard let current = currentCoachStep, let next = current.next else {
            completeTour()
            return
        }
        currentCoachStep = next
    }

    func completeTour() {
        currentCoachStep = nil
        hasCompletedTour = true
    }

    func skipTour() {
        currentCoachStep = nil
        hasCompletedTour = true
    }

    /// Full reset for development/testing.
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedTour = false
        currentCoachStep = nil
        showOnboardingSheet = false
        shouldOpenAddFlight = false
        trainingStage = .preSolo
        gettingStartedIntent = .explore
    }
}
