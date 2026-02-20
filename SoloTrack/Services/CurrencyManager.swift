import Foundation

// MARK: - Currency Status

enum CurrencyState: Comparable, Hashable {
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

    // FR-7: Static formatter (avoid re-allocation on every render)
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    // B4: Absolute date label for currency cards
    var absoluteDateLabel: String? {
        let calendar = Calendar.current
        let now = Date.now
        switch self {
        case .valid(let days), .caution(let days):
            guard let date = calendar.date(byAdding: .day, value: days, to: now) else { return nil }
            return Self.shortDateFormatter.string(from: date)
        case .expired:
            return nil
        }
    }
}

// MARK: - Currency Manager

/// Handles FAR 61.57 currency calculations.
/// - Day Currency: 3 takeoffs & landings in the preceding 90 days.
/// - Night Currency: 3 full-stop night takeoffs & landings in the preceding 90 days.
struct CurrencyManager {
    private let calendar = Calendar.current
    private let requiredLandings = 3
    private let lookbackDays = 90
    private let cautionThreshold = 30

    // MARK: - Day Currency (FAR 61.57(a))

    func dayCurrency(flights: [FlightLog], asOf referenceDate: Date = .now) -> CurrencyState {
        guard let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: referenceDate) else {
            return .expired(daysSince: 0)
        }

        let recentFlights = flights
            .filter { $0.date >= windowStart && $0.date <= referenceDate }
            .sorted { $0.date < $1.date }

        var totalDayLandings = 0

        for flight in recentFlights {
            totalDayLandings += flight.landingsDay
        }

        if totalDayLandings < requiredLandings {
            return computeExpiredState(flights: flights, referenceDate: referenceDate, isNight: false)
        }

        let expirationDate = expirationForRollingCurrency(
            flights: recentFlights,
            referenceDate: referenceDate,
            landingExtractor: { $0.landingsDay }
        )

        return stateFromExpiration(expirationDate, referenceDate: referenceDate)
    }

    // MARK: - Night Currency (FAR 61.57(b))

    func nightCurrency(flights: [FlightLog], asOf referenceDate: Date = .now) -> CurrencyState {
        guard let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: referenceDate) else {
            return .expired(daysSince: 0)
        }

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

    private func expirationForRollingCurrency(
        flights: [FlightLog],
        referenceDate: Date,
        landingExtractor: (FlightLog) -> Int
    ) -> Date {
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

        return calendar.date(byAdding: .day, value: lookbackDays, to: oldestNeededDate) ?? referenceDate
    }

    // MARK: - Expired State

    private func computeExpiredState(flights: [FlightLog], referenceDate: Date, isNight: Bool) -> CurrencyState {
        let allSorted = flights.sorted { $0.date > $1.date }
        guard let lastFlight = allSorted.first(where: {
            isNight ? $0.landingsNightFullStop > 0 : $0.landingsDay > 0
        }) else {
            return .expired(daysSince: 0)
        }

        guard let lastPossibleExpiry = calendar.date(byAdding: .day, value: lookbackDays, to: lastFlight.date) else {
            return .expired(daysSince: 0)
        }
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
