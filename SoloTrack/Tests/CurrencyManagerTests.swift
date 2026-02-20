import Testing
import Foundation
@testable import SoloTrack

// MARK: - CurrencyManager Tests

@Suite("CurrencyManager — FAR 61.57 currency calculations")
struct CurrencyManagerTests {
    let manager = CurrencyManager()
    let calendar = Calendar.current

    // MARK: - Helpers

    /// Creates a FlightLog with specified date and landings for testing.
    private func flight(
        daysAgo: Int,
        dayLandings: Int = 0,
        nightFullStop: Int = 0,
        referenceDate: Date = .now
    ) -> FlightLog {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        return FlightLog(
            date: date,
            durationHobbs: 1.0,
            landingsDay: dayLandings,
            landingsNightFullStop: nightFullStop
        )
    }

    // MARK: - Day Currency

    @Test("No flights → expired with 0 days")
    func dayCurrencyNoFlights() {
        let result = manager.dayCurrency(flights: [])
        #expect(!result.isLegal)
        if case .expired(let days) = result {
            #expect(days == 0)
        } else {
            Issue.record("Expected .expired, got \(result)")
        }
    }

    @Test("3 day landings today → valid for ~90 days")
    func dayCurrencyFreshLandings() {
        let flights = [flight(daysAgo: 0, dayLandings: 3)]
        let result = manager.dayCurrency(flights: flights)
        #expect(result.isLegal)
        if case .valid(let days) = result {
            #expect(days >= 59) // ~90 days minus caution threshold of 30
        }
    }

    @Test("3 day landings 80 days ago → caution (within 30-day threshold)")
    func dayCurrencyCaution() {
        let flights = [flight(daysAgo: 80, dayLandings: 3)]
        let result = manager.dayCurrency(flights: flights)
        #expect(result.isLegal)
        if case .caution(let days) = result {
            #expect(days <= 30)
            #expect(days >= 0)
        } else {
            Issue.record("Expected .caution, got \(result)")
        }
    }

    @Test("3 day landings 91 days ago → expired")
    func dayCurrencyExpired() {
        let flights = [flight(daysAgo: 91, dayLandings: 3)]
        let result = manager.dayCurrency(flights: flights)
        #expect(!result.isLegal)
    }

    @Test("Only 2 day landings within window → expired (need 3)")
    func dayCurrencyInsufficientLandings() {
        let flights = [
            flight(daysAgo: 10, dayLandings: 1),
            flight(daysAgo: 20, dayLandings: 1),
        ]
        let result = manager.dayCurrency(flights: flights)
        #expect(!result.isLegal)
    }

    @Test("Cumulative landings across flights reach 3 → valid")
    func dayCurrencyCumulativeLandings() {
        let flights = [
            flight(daysAgo: 5, dayLandings: 1),
            flight(daysAgo: 10, dayLandings: 1),
            flight(daysAgo: 15, dayLandings: 1),
        ]
        let result = manager.dayCurrency(flights: flights)
        #expect(result.isLegal)
    }

    // MARK: - Night Currency

    @Test("No night landings → expired")
    func nightCurrencyNoFlights() {
        let result = manager.nightCurrency(flights: [])
        #expect(!result.isLegal)
    }

    @Test("3 night full-stop landings today → valid")
    func nightCurrencyFreshLandings() {
        let flights = [flight(daysAgo: 0, nightFullStop: 3)]
        let result = manager.nightCurrency(flights: flights)
        #expect(result.isLegal)
    }

    @Test("Day landings don't count for night currency")
    func nightCurrencyIgnoresDayLandings() {
        let flights = [flight(daysAgo: 0, dayLandings: 10, nightFullStop: 0)]
        let result = manager.nightCurrency(flights: flights)
        #expect(!result.isLegal)
    }

    // MARK: - CurrencyState properties

    @Test("CurrencyState.isLegal — valid and caution are legal, expired is not")
    func currencyStateLegal() {
        #expect(CurrencyState.valid(daysRemaining: 60).isLegal)
        #expect(CurrencyState.caution(daysRemaining: 10).isLegal)
        #expect(!CurrencyState.expired(daysSince: 5).isLegal)
    }

    @Test("CurrencyState.label — descriptive strings")
    func currencyStateLabel() {
        let valid = CurrencyState.valid(daysRemaining: 45)
        #expect(valid.label.contains("45"))

        let expired = CurrencyState.expired(daysSince: 10)
        #expect(expired.label.contains("10"))
    }
}
