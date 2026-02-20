import Testing
import Foundation
@testable import SoloTrack

// MARK: - ProgressTracker Tests

@Suite("ProgressTracker — FAR 61.109 PPL requirement tracking")
struct ProgressTrackerTests {
    let tracker = ProgressTracker()

    // MARK: - Empty State

    @Test("No flights → all requirements at 0 progress")
    func emptyFlights() {
        let reqs = tracker.computeRequirements(from: [])
        #expect(reqs.count == 6)
        for req in reqs {
            #expect(req.loggedHours == 0)
            #expect(req.progress == 0)
            #expect(!req.isMet)
        }
    }

    @Test("No flights → overall progress is 0")
    func emptyOverallProgress() {
        let progress = tracker.overallProgress(from: [])
        #expect(progress == 0)
    }

    @Test("No flights → 0 requirements met")
    func emptyRequirementsMet() {
        #expect(tracker.requirementsMet(from: []) == 0)
    }

    @Test("Total requirements count is 6")
    func totalRequirements() {
        #expect(tracker.totalRequirements() == 6)
    }

    // MARK: - Accumulation

    @Test("Solo XC flights contribute to total, solo, solo XC")
    func soloXCContribution() {
        let flights = [
            FlightLog(durationHobbs: 2.0, isSolo: true, isCrossCountry: true),
        ]
        let reqs = tracker.computeRequirements(from: flights)

        let total = reqs.first { $0.farReference == "61.109(a)" }!
        #expect(total.loggedHours == 2.0)

        let solo = reqs.first { $0.farReference == "61.109(a)(2)" }!
        #expect(solo.loggedHours == 2.0)

        let soloXC = reqs.first { $0.farReference == "61.109(a)(2)(i)" }!
        #expect(soloXC.loggedHours == 2.0)

        // Should NOT count as dual
        let dual = reqs.first { $0.farReference == "61.109(a)(1)" }!
        #expect(dual.loggedHours == 0)
    }

    @Test("Dual flights contribute to total and dual instruction")
    func dualContribution() {
        let flights = [
            FlightLog(durationHobbs: 5.0, isDualReceived: true),
        ]
        let reqs = tracker.computeRequirements(from: flights)

        let total = reqs.first { $0.farReference == "61.109(a)" }!
        #expect(total.loggedHours == 5.0)

        let dual = reqs.first { $0.farReference == "61.109(a)(1)" }!
        #expect(dual.loggedHours == 5.0)

        // Should NOT count as solo
        let solo = reqs.first { $0.farReference == "61.109(a)(2)" }!
        #expect(solo.loggedHours == 0)
    }

    @Test("Night flights (with night landings) count toward night training")
    func nightContribution() {
        let flights = [
            FlightLog(durationHobbs: 1.5, landingsNightFullStop: 2),
        ]
        let reqs = tracker.computeRequirements(from: flights)

        let night = reqs.first { $0.farReference == "61.109(a)(2)(ii)" }!
        #expect(night.loggedHours == 1.5)
    }

    @Test("Instrument flights count toward instrument training")
    func instrumentContribution() {
        let flights = [
            FlightLog(durationHobbs: 1.0, isSimulatedInstrument: true),
        ]
        let reqs = tracker.computeRequirements(from: flights)

        let inst = reqs.first { $0.farReference == "61.109(a)(3)" }!
        #expect(inst.loggedHours == 1.0)
    }

    // MARK: - Completion

    @Test("Meeting a requirement → isMet = true, progress capped at 1.0")
    func requirementMet() {
        let flights = [
            FlightLog(durationHobbs: 50.0, isSolo: true, isCrossCountry: true, isSimulatedInstrument: true),
        ]
        let reqs = tracker.computeRequirements(from: flights)

        let soloXC = reqs.first { $0.farReference == "61.109(a)(2)(i)" }!
        #expect(soloXC.isMet)
        #expect(soloXC.progress == 1.0) // Capped, not >1.0
        #expect(soloXC.remainingHours == 0)
        #expect(soloXC.formattedRemaining == "Complete")
    }

    // MARK: - PPLRequirement Properties

    @Test("Stable ID based on farReference")
    func stableId() {
        let req1 = PPLRequirement(title: "Test", farReference: "61.109(a)", goalHours: 40, loggedHours: 10)
        let req2 = PPLRequirement(title: "Test", farReference: "61.109(a)", goalHours: 40, loggedHours: 20)
        #expect(req1.id == req2.id)
    }

    @Test("formattedProgress shows hours as X.X / Y.X format")
    func formattedProgress() {
        let req = PPLRequirement(title: "Test", farReference: "test", goalHours: 40, loggedHours: 12.5)
        #expect(req.formattedProgress == "12.5 / 40.0 hours")
    }

    @Test("percentComplete rounds down")
    func percentComplete() {
        let req = PPLRequirement(title: "Test", farReference: "test", goalHours: 3, loggedHours: 1)
        #expect(req.percentComplete == 33)
    }
}
