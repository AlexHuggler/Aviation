import Testing
import Foundation
@testable import SoloTrack

// MARK: - FlightLog Model Tests

struct FlightLogTests {

    // MARK: - Default Values (M-5)

    @Test("Default landingsDay is 1, matching UI default")
    func defaultLandingsDay() {
        let flight = FlightLog()
        #expect(flight.landingsDay == 1)
    }

    @Test("Default durationHobbs is 0")
    func defaultDuration() {
        let flight = FlightLog()
        #expect(flight.durationHobbs == 0)
    }

    // MARK: - Computed Properties

    @Test("formattedRoute handles all combinations")
    func formattedRoute() {
        #expect(FlightLog(routeFrom: "KSJC", routeTo: "KRHV").formattedRoute == "KSJC → KRHV")
        #expect(FlightLog(routeFrom: "", routeTo: "").formattedRoute == "Local")
        #expect(FlightLog(routeFrom: "ksjc", routeTo: "").formattedRoute == "KSJC")
        #expect(FlightLog(routeFrom: "", routeTo: "krhv").formattedRoute == "KRHV")
    }

    @Test("categoryTags includes correct tags")
    func categoryTags() {
        let solo = FlightLog(isSolo: true)
        #expect(solo.categoryTags == ["Solo"])

        let dual = FlightLog(isDualReceived: true, isCrossCountry: true)
        #expect(dual.categoryTags == ["Dual", "XC"])

        let instrument = FlightLog(isSimulatedInstrument: true)
        #expect(instrument.categoryTags == ["Inst"])
    }

    @Test("totalLandings sums day and night")
    func totalLandings() {
        let flight = FlightLog(landingsDay: 3, landingsNightFullStop: 2)
        #expect(flight.totalLandings == 5)
    }

    // MARK: - Signature Management

    @Test("lockSignature sets all signature fields")
    func lockSignature() {
        let flight = FlightLog()
        let fakeData = Data([0x01, 0x02])
        flight.lockSignature(signatureData: fakeData, cfi: "CFI123")

        #expect(flight.instructorSignature == fakeData)
        #expect(flight.cfiNumber == "CFI123")
        #expect(flight.isSignatureLocked)
        #expect(flight.signatureDate != nil)
        #expect(flight.hasValidSignature)
    }

    @Test("voidSignature clears all signature fields")
    func voidSignature() {
        let flight = FlightLog()
        flight.lockSignature(signatureData: Data([0x01]), cfi: "CFI123")
        flight.voidSignature()

        #expect(flight.instructorSignature == nil)
        #expect(flight.cfiNumber.isEmpty)
        #expect(!flight.isSignatureLocked)
        #expect(flight.signatureDate == nil)
        #expect(!flight.hasValidSignature)
    }

    @Test("isEditable is true when signature is not locked")
    func isEditable() {
        let flight = FlightLog()
        #expect(flight.isEditable)

        flight.lockSignature(signatureData: Data([0x01]), cfi: "CFI123")
        #expect(!flight.isEditable)
    }

    @Test("hasValidSignature requires all three fields")
    func hasValidSignature() {
        let flight = FlightLog()

        // Missing signature data
        flight.cfiNumber = "CFI123"
        flight.signatureDate = .now
        #expect(!flight.hasValidSignature)

        // Missing CFI number
        flight.instructorSignature = Data([0x01])
        flight.cfiNumber = ""
        #expect(!flight.hasValidSignature)

        // Missing date
        flight.cfiNumber = "CFI123"
        flight.signatureDate = nil
        #expect(!flight.hasValidSignature)

        // All present
        flight.signatureDate = .now
        #expect(flight.hasValidSignature)
    }
}
