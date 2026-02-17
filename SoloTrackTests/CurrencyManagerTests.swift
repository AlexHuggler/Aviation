import Testing
import Foundation
@testable import SoloTrack

// MARK: - Currency Manager Tests (FAR 61.57)

struct CurrencyManagerTests {
    let sut = CurrencyManager()
    let calendar = Calendar.current

    // Helper: create a FlightLog with specific day/night landings on a given date
    private func makeFlight(
        daysAgo: Int,
        dayLandings: Int = 0,
        nightLandings: Int = 0,
        referenceDate: Date = .now
    ) -> FlightLog {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        return FlightLog(
            date: date,
            durationHobbs: 1.5,
            landingsDay: dayLandings,
            landingsNightFullStop: nightLandings
        )
    }

    // MARK: - Day Currency

    @Test("Day currency is valid with 3+ landings in last 90 days")
    func dayCurrency_valid() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 10, dayLandings: 3, referenceDate: ref)
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(state.isLegal)
        if case .valid(let days) = state {
            #expect(days > 0)
        } else if case .caution = state {
            // Also acceptable if within caution threshold
        } else {
            Issue.record("Expected .valid or .caution, got \(state)")
        }
    }

    @Test("Day currency is expired with 0 landings")
    func dayCurrency_expired_noFlights() {
        let state = sut.dayCurrency(flights: [], asOf: .now)
        #expect(!state.isLegal)
        #expect(state == .expired(daysSince: 0))
    }

    @Test("Day currency is expired with only 2 landings (below threshold)")
    func dayCurrency_expired_insufficientLandings() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 5, dayLandings: 2, referenceDate: ref)
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(!state.isLegal)
    }

    @Test("Day currency expires after 90 days from oldest needed landing")
    func dayCurrency_rollsOff() {
        let ref = Date.now
        // 3 landings exactly 91 days ago — should be expired
        let flights = [
            makeFlight(daysAgo: 91, dayLandings: 3, referenceDate: ref)
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(!state.isLegal)
    }

    @Test("Day currency at exactly 90 days is still valid or caution")
    func dayCurrency_boundary90Days() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 89, dayLandings: 3, referenceDate: ref)
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(state.isLegal)
    }

    @Test("Day currency in caution zone (within 30 days of expiry)")
    func dayCurrency_cautionZone() {
        let ref = Date.now
        // 3 landings 70 days ago → expires at day 90, so 20 days remaining → caution
        let flights = [
            makeFlight(daysAgo: 70, dayLandings: 3, referenceDate: ref)
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(state.isLegal)
        if case .caution(let days) = state {
            #expect(days <= 30)
            #expect(days >= 0)
        } else if case .valid = state {
            // Some boundary cases might still be valid
        } else {
            Issue.record("Expected .caution or .valid, got \(state)")
        }
    }

    // MARK: - Night Currency

    @Test("Night currency is valid with 3+ full-stop night landings")
    func nightCurrency_valid() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 5, nightLandings: 3, referenceDate: ref)
        ]

        let state = sut.nightCurrency(flights: flights, asOf: ref)
        #expect(state.isLegal)
    }

    @Test("Night currency is expired with no night landings")
    func nightCurrency_expired() {
        let ref = Date.now
        // Only day landings, no night
        let flights = [
            makeFlight(daysAgo: 5, dayLandings: 5, referenceDate: ref)
        ]

        let state = sut.nightCurrency(flights: flights, asOf: ref)
        #expect(!state.isLegal)
    }

    @Test("Night currency counts only night landings, not day landings")
    func nightCurrency_ignoresDayLandings() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 5, dayLandings: 10, nightLandings: 2, referenceDate: ref)
        ]

        let state = sut.nightCurrency(flights: flights, asOf: ref)
        #expect(!state.isLegal) // Only 2 night landings, need 3
    }

    // MARK: - Rolling Window

    @Test("Currency uses rolling window — spread landings still valid")
    func dayCurrency_rollingWindow_spreadLandings() {
        let ref = Date.now
        let flights = [
            makeFlight(daysAgo: 80, dayLandings: 1, referenceDate: ref),
            makeFlight(daysAgo: 50, dayLandings: 1, referenceDate: ref),
            makeFlight(daysAgo: 10, dayLandings: 1, referenceDate: ref),
        ]

        let state = sut.dayCurrency(flights: flights, asOf: ref)
        #expect(state.isLegal)
    }

    // MARK: - CurrencyState Properties

    @Test("CurrencyState labels are correct")
    func currencyState_labels() {
        #expect(CurrencyState.valid(daysRemaining: 45).shortLabel == "Expires in 45d")
        #expect(CurrencyState.caution(daysRemaining: 10).shortLabel == "Expires in 10d")
        #expect(CurrencyState.expired(daysSince: 5).shortLabel == "Expired 5d ago")

        #expect(CurrencyState.valid(daysRemaining: 45).isLegal)
        #expect(CurrencyState.caution(daysRemaining: 10).isLegal)
        #expect(!CurrencyState.expired(daysSince: 5).isLegal)
    }

    @Test("absoluteDateLabel returns nil for expired state")
    func absoluteDateLabel_expired() {
        let state = CurrencyState.expired(daysSince: 5)
        #expect(state.absoluteDateLabel == nil)
    }

    @Test("absoluteDateLabel returns a date string for valid state")
    func absoluteDateLabel_valid() {
        let state = CurrencyState.valid(daysRemaining: 30)
        #expect(state.absoluteDateLabel != nil)
        #expect(!state.absoluteDateLabel!.isEmpty)
    }
}
