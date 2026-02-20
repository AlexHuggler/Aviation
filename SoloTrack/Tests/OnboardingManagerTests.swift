import Testing
import Foundation
@testable import SoloTrack

// MARK: - OnboardingManager Tests

@Suite("OnboardingManager — state transitions and branching logic")
@MainActor
struct OnboardingManagerTests {

    @Test("Fresh manager → not completed, explore intent, preSolo stage")
    func freshState() {
        let manager = OnboardingManager()
        // Clear any persisted state from prior test runs
        manager.resetOnboarding()

        #expect(!manager.hasCompletedOnboarding)
        #expect(!manager.hasCompletedTour)
        #expect(manager.trainingStage == .preSolo)
        #expect(manager.gettingStartedIntent == .explore)
        #expect(manager.currentCoachStep == nil)
        #expect(!manager.showOnboardingSheet)
        #expect(!manager.shouldOpenAddFlight)
    }

    @Test("completeOnboarding with logFresh → sheet dismissed, shouldOpenAddFlight = true")
    func completeOnboardingLogFresh() {
        let manager = OnboardingManager()
        manager.showOnboardingSheet = true

        manager.completeOnboarding(stage: .postSolo, intent: .logFresh)

        #expect(manager.hasCompletedOnboarding)
        #expect(!manager.showOnboardingSheet)
        #expect(manager.shouldOpenAddFlight)
        #expect(manager.trainingStage == .postSolo)
        #expect(manager.gettingStartedIntent == .logFresh)
        #expect(manager.currentCoachStep == nil)
    }

    @Test("completeOnboarding with explore → starts tour at dashboardWelcome")
    func completeOnboardingExplore() {
        let manager = OnboardingManager()
        manager.showOnboardingSheet = true

        manager.completeOnboarding(stage: .checkridPrep, intent: .explore)

        #expect(manager.hasCompletedOnboarding)
        #expect(!manager.showOnboardingSheet)
        #expect(!manager.shouldOpenAddFlight)
        #expect(manager.currentCoachStep == .dashboardWelcome)
    }

    @Test("advanceTour moves through all steps sequentially")
    func advanceTourSequence() {
        let manager = OnboardingManager()
        manager.currentCoachStep = .dashboardWelcome

        manager.advanceTour() // → currencyCards
        #expect(manager.currentCoachStep == .currencyCards)

        manager.advanceTour() // → progressTab
        #expect(manager.currentCoachStep == .progressTab)

        manager.advanceTour() // → logbookTab
        #expect(manager.currentCoachStep == .logbookTab)

        manager.advanceTour() // → addFlightButton
        #expect(manager.currentCoachStep == .addFlightButton)

        manager.advanceTour() // → tourComplete
        #expect(manager.currentCoachStep == .tourComplete)

        manager.advanceTour() // → completes tour
        #expect(manager.currentCoachStep == nil)
        #expect(manager.hasCompletedTour)
    }

    @Test("skipTour → tour completed, step cleared")
    func skipTour() {
        let manager = OnboardingManager()
        manager.currentCoachStep = .currencyCards

        manager.skipTour()

        #expect(manager.currentCoachStep == nil)
        #expect(manager.hasCompletedTour)
    }

    @Test("resetOnboarding clears all state")
    func resetOnboarding() {
        let manager = OnboardingManager()
        manager.completeOnboarding(stage: .checkridPrep, intent: .logFresh)

        manager.resetOnboarding()

        #expect(!manager.hasCompletedOnboarding)
        #expect(!manager.hasCompletedTour)
        #expect(manager.trainingStage == .preSolo)
        #expect(manager.gettingStartedIntent == .explore)
        #expect(manager.currentCoachStep == nil)
        #expect(!manager.showOnboardingSheet)
        #expect(!manager.shouldOpenAddFlight)
    }

    // MARK: - TrainingStage branching logic

    @Test("preSolo defaults → dual received ON, solo OFF")
    func preSoloDefaults() {
        #expect(!TrainingStage.preSolo.defaultIsSolo)
        #expect(TrainingStage.preSolo.defaultIsDualReceived)
    }

    @Test("postSolo defaults → solo ON, dual received OFF")
    func postSoloDefaults() {
        #expect(TrainingStage.postSolo.defaultIsSolo)
        #expect(!TrainingStage.postSolo.defaultIsDualReceived)
    }

    @Test("checkridPrep defaults → solo ON, dual received OFF")
    func checkrideDefaults() {
        #expect(TrainingStage.checkridPrep.defaultIsSolo)
        #expect(!TrainingStage.checkridPrep.defaultIsDualReceived)
    }

    // MARK: - CoachMarkStep

    @Test("CoachMarkStep.next walks through all steps")
    func coachMarkStepSequence() {
        var step: CoachMarkStep? = .dashboardWelcome
        var visited: [CoachMarkStep] = []

        while let current = step {
            visited.append(current)
            step = current.next
        }

        #expect(visited.count == CoachMarkStep.allCases.count)
        #expect(visited == CoachMarkStep.allCases)
    }

    @Test("Each coach step has an associated tab")
    func coachMarkAssociatedTabs() {
        for step in CoachMarkStep.allCases {
            #expect(step.associatedTab != nil, "Step \(step) should have an associated tab")
        }
    }
}
