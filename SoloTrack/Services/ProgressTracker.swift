import Foundation

// MARK: - PPL Requirement

struct PPLRequirement: Identifiable {
    let id = UUID()
    let title: String
    let farReference: String
    let goalHours: Double
    var loggedHours: Double

    var progress: Double {
        min(loggedHours / goalHours, 1.0)
    }

    var percentComplete: Int {
        Int(progress * 100)
    }

    var isMet: Bool {
        loggedHours >= goalHours
    }

    var remainingHours: Double {
        max(goalHours - loggedHours, 0)
    }

    var formattedProgress: String {
        String(format: "%.1f / %.1f hours", loggedHours, goalHours)
    }

    var formattedRemaining: String {
        if isMet { return "Complete" }
        return String(format: "%.1f hrs to go", remainingHours)
    }
}

// MARK: - Progress Tracker

/// Tracks progress against FAR 61.109 PPL requirements.
struct ProgressTracker {

    func computeRequirements(from flights: [FlightLog]) -> [PPLRequirement] {
        let totalTime = flights.reduce(0.0) { $0 + $1.durationHobbs }
        let dualTime = flights.filter { $0.isDualReceived }.reduce(0.0) { $0 + $1.durationHobbs }
        let soloTime = flights.filter { $0.isSolo }.reduce(0.0) { $0 + $1.durationHobbs }
        let soloXCTime = flights.filter { $0.isSolo && $0.isCrossCountry }.reduce(0.0) { $0 + $1.durationHobbs }
        let nightTime = flights.filter { $0.landingsNightFullStop > 0 }.reduce(0.0) { $0 + $1.durationHobbs }
        let instrumentTime = flights.filter { $0.isSimulatedInstrument }.reduce(0.0) { $0 + $1.durationHobbs }

        return [
            PPLRequirement(
                title: "Total Flight Time",
                farReference: "61.109(a)",
                goalHours: 40,
                loggedHours: totalTime
            ),
            PPLRequirement(
                title: "Dual Instruction",
                farReference: "61.109(a)(1)",
                goalHours: 20,
                loggedHours: dualTime
            ),
            PPLRequirement(
                title: "Solo Flight",
                farReference: "61.109(a)(2)",
                goalHours: 10,
                loggedHours: soloTime
            ),
            PPLRequirement(
                title: "Solo Cross-Country",
                farReference: "61.109(a)(2)(i)",
                goalHours: 5,
                loggedHours: soloXCTime
            ),
            PPLRequirement(
                title: "Night Training",
                farReference: "61.109(a)(2)(ii)",
                goalHours: 3,
                loggedHours: nightTime
            ),
            PPLRequirement(
                title: "Instrument Training",
                farReference: "61.109(a)(3)",
                goalHours: 3,
                loggedHours: instrumentTime
            ),
        ]
    }

    func overallProgress(from flights: [FlightLog]) -> Double {
        let requirements = computeRequirements(from: flights)
        let totalProgress = requirements.reduce(0.0) { $0 + $1.progress }
        return totalProgress / Double(requirements.count)
    }

    func requirementsMet(from flights: [FlightLog]) -> Int {
        computeRequirements(from: flights).filter { $0.isMet }.count
    }

    func totalRequirements() -> Int {
        6
    }
}
