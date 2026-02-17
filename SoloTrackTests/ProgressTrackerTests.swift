import Testing
import Foundation
@testable import SoloTrack

// MARK: - Progress Tracker Tests (FAR 61.109)

struct ProgressTrackerTests {
    let sut = ProgressTracker()

    // MARK: - Empty State

    @Test("No flights produces all-zero progress")
    func emptyFlights() {
        let requirements = sut.computeRequirements(from: [])
        #expect(requirements.count == 6)
        for req in requirements {
            #expect(req.loggedHours == 0)
            #expect(req.progress == 0)
            #expect(!req.isMet)
        }
    }

    @Test("Overall progress is 0 with no flights")
    func overallProgress_empty() {
        let progress = sut.overallProgress(from: [])
        #expect(progress == 0)
    }

    @Test("Requirements met is 0 with no flights")
    func requirementsMet_empty() {
        #expect(sut.requirementsMet(from: []) == 0)
    }

    @Test("Total requirements is always 6")
    func totalRequirements() {
        #expect(sut.totalRequirements() == 6)
    }

    // MARK: - Single Flight

    @Test("Solo flight counts toward solo and total time")
    func soloFlight() {
        let flight = FlightLog(durationHobbs: 1.5, isSolo: true)
        let requirements = sut.computeRequirements(from: [flight])

        let total = requirements.first { $0.farReference == "61.109(a)" }!
        let solo = requirements.first { $0.farReference == "61.109(a)(2)" }!
        let dual = requirements.first { $0.farReference == "61.109(a)(1)" }!

        #expect(total.loggedHours == 1.5)
        #expect(solo.loggedHours == 1.5)
        #expect(dual.loggedHours == 0)
    }

    @Test("Dual flight counts toward dual and total time")
    func dualFlight() {
        let flight = FlightLog(durationHobbs: 2.0, isDualReceived: true)
        let requirements = sut.computeRequirements(from: [flight])

        let dual = requirements.first { $0.farReference == "61.109(a)(1)" }!
        let solo = requirements.first { $0.farReference == "61.109(a)(2)" }!

        #expect(dual.loggedHours == 2.0)
        #expect(solo.loggedHours == 0)
    }

    @Test("Solo XC flight counts toward solo, solo XC, and total")
    func soloXCFlight() {
        let flight = FlightLog(durationHobbs: 3.0, isSolo: true, isCrossCountry: true)
        let requirements = sut.computeRequirements(from: [flight])

        let soloXC = requirements.first { $0.farReference == "61.109(a)(2)(i)" }!
        let solo = requirements.first { $0.farReference == "61.109(a)(2)" }!

        #expect(soloXC.loggedHours == 3.0)
        #expect(solo.loggedHours == 3.0)
    }

    // MARK: - PPLRequirement Properties

    @Test("Stable ID is based on farReference")
    func stableIdentity() {
        let req1 = PPLRequirement(title: "Test", farReference: "61.109(a)", goalHours: 40, loggedHours: 10)
        let req2 = PPLRequirement(title: "Test", farReference: "61.109(a)", goalHours: 40, loggedHours: 20)

        // C-3: same farReference → same id, even though loggedHours differs
        #expect(req1.id == req2.id)
    }

    @Test("Progress is capped at 1.0 when exceeding goal")
    func progressCapped() {
        let req = PPLRequirement(title: "T", farReference: "test", goalHours: 10, loggedHours: 15)
        #expect(req.progress == 1.0)
        #expect(req.isMet)
        #expect(req.percentComplete == 100)
        #expect(req.remainingHours == 0)
        #expect(req.formattedRemaining == "Complete")
    }

    @Test("Remaining hours calculated correctly")
    func remainingHours() {
        let req = PPLRequirement(title: "T", farReference: "test", goalHours: 40, loggedHours: 25)
        #expect(req.remainingHours == 15)
        #expect(req.formattedRemaining == "15.0 hrs to go")
    }

    // MARK: - Full Checkride Readiness

    @Test("All requirements met with sufficient flights")
    func allRequirementsMet() {
        var flights: [FlightLog] = []

        // 30 hours dual with instrument training
        for _ in 0..<20 {
            flights.append(FlightLog(
                durationHobbs: 1.5,
                landingsDay: 1,
                landingsNightFullStop: 0,
                isDualReceived: true,
                isSimulatedInstrument: true
            ))
        }

        // 15 hours solo, 8 of which are XC
        for _ in 0..<10 {
            flights.append(FlightLog(
                durationHobbs: 1.5,
                landingsDay: 1,
                isSolo: true,
                isCrossCountry: true
            ))
        }

        // 5 hours night
        for _ in 0..<4 {
            flights.append(FlightLog(
                durationHobbs: 1.5,
                landingsNightFullStop: 3,
                isDualReceived: true
            ))
        }

        let met = sut.requirementsMet(from: flights)
        #expect(met == 6)
    }
}
