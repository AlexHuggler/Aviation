import Foundation
import SwiftData

// MARK: - Currency Status

enum CurrencyState: Comparable {
    case valid(daysRemaining: Int)
    case caution(daysRemaining: Int)
    case expired(daysSince: Int)

    var isLegal: Bool {
        switch self {
        case .valid, .caution: return true
        case .expired: return false
        }
    }

    var label: String {
        switch self {
        case .valid(let days):
            return "Current — \(days) days remaining"
        case .caution(let days):
            return "Expiring in \(days) days"
        case .expired(let days):
            return "Expired \(days) days ago"
        }
    }

    var shortLabel: String {
        switch self {
        case .valid(let days):
            return "Expires in \(days)d"
        case .caution(let days):
            return "Expires in \(days)d"
        case .expired(let days):
            return "Expired \(days)d ago"
        }
    }
}

// MARK: - Currency Manager

/// Handles FAR 61.57 currency calculations.
/// - Day Currency: 3 takeoffs & landings in the preceding 90 days.
/// - Night Currency: 3 full-stop night takeoffs & landings in the preceding 90 days.
@Observable
final class CurrencyManager {
    private let calendar = Calendar.current
    private let requiredLandings = 3
    private let lookbackDays = 90
    private let cautionThreshold = 30

    // MARK: - Day Currency (FAR 61.57(a))

    func dayCurrency(flights: [FlightLog], asOf referenceDate: Date = .now) -> CurrencyState {
        let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: referenceDate)!

        let recentFlights = flights
            .filter { $0.date >= windowStart && $0.date <= referenceDate }
            .sorted { $0.date < $1.date }

        var totalDayLandings = 0
        var thirdLandingDate: Date?

        for flight in recentFlights {
            let previous = totalDayLandings
            totalDayLandings += flight.landingsDay
            if previous < requiredLandings && totalDayLandings >= requiredLandings {
                thirdLandingDate = flight.date
            }
        }

        // If we never reached 3 landings in the window, find the last time we did
        if totalDayLandings < requiredLandings {
            return computeExpiredState(flights: flights, referenceDate: referenceDate, isNight: false)
        }

        // Currency expires 90 days after the flight that gave us the 3rd landing
        // We need to find the rolling window: the earliest date from which
        // 3 landings were accumulated that still falls within the 90-day window.
        let expirationDate = expirationForRollingCurrency(
            flights: recentFlights,
            referenceDate: referenceDate,
            landingExtractor: { $0.landingsDay }
        )

        return stateFromExpiration(expirationDate, referenceDate: referenceDate)
    }

    // MARK: - Night Currency (FAR 61.57(b))

    func nightCurrency(flights: [FlightLog], asOf referenceDate: Date = .now) -> CurrencyState {
        let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: referenceDate)!

        let recentFlights = flights
            .filter { $0.date >= windowStart && $0.date <= referenceDate }
            .sorted { $0.date < $1.date }

        var totalNightLandings = 0
        for flight in recentFlights {
            totalNightLandings += flight.landingsNightFullStop
        }

        if totalNightLandings < requiredLandings {
            return computeExpiredState(flights: flights, referenceDate: referenceDate, isNight: true)
        }

        let expirationDate = expirationForRollingCurrency(
            flights: recentFlights,
            referenceDate: referenceDate,
            landingExtractor: { $0.landingsNightFullStop }
        )

        return stateFromExpiration(expirationDate, referenceDate: referenceDate)
    }

    // MARK: - Rolling Window Expiration

    /// Finds the expiration date using a sliding window approach.
    /// The currency expires 90 days after the earliest flight in the smallest
    /// window of flights that together provide >= 3 landings,
    /// where that window's start is as late as possible.
    private func expirationForRollingCurrency(
        flights: [FlightLog],
        referenceDate: Date,
        landingExtractor: (FlightLog) -> Int
    ) -> Date {
        // Work backwards: find the most recent set of flights that give us 3 landings.
        let reversedFlights = flights.sorted { $0.date > $1.date }
        var accumulated = 0
        var oldestNeededDate = referenceDate

        for flight in reversedFlights {
            accumulated += landingExtractor(flight)
            oldestNeededDate = flight.date
            if accumulated >= requiredLandings {
                break
            }
        }

        // Currency expires 90 days from the oldest flight we needed
        return calendar.date(byAdding: .day, value: lookbackDays, to: oldestNeededDate)!
    }

    // MARK: - Expired State

    private func computeExpiredState(flights: [FlightLog], referenceDate: Date, isNight: Bool) -> CurrencyState {
        // Find when currency last expired (if ever current)
        let allSorted = flights.sorted { $0.date > $1.date }
        guard let lastFlight = allSorted.first(where: {
            isNight ? $0.landingsNightFullStop > 0 : $0.landingsDay > 0
        }) else {
            return .expired(daysSince: 0)
        }

        let lastPossibleExpiry = calendar.date(byAdding: .day, value: lookbackDays, to: lastFlight.date)!
        if lastPossibleExpiry < referenceDate {
            let daysSince = calendar.dateComponents([.day], from: lastPossibleExpiry, to: referenceDate).day ?? 0
            return .expired(daysSince: daysSince)
        }

        return .expired(daysSince: 0)
    }

    // MARK: - State from Expiration Date

    private func stateFromExpiration(_ expiration: Date, referenceDate: Date) -> CurrencyState {
        let daysRemaining = calendar.dateComponents([.day], from: referenceDate, to: expiration).day ?? 0

        if daysRemaining < 0 {
            return .expired(daysSince: abs(daysRemaining))
        } else if daysRemaining <= cautionThreshold {
            return .caution(daysRemaining: daysRemaining)
        } else {
            return .valid(daysRemaining: daysRemaining)
        }
    }
}
