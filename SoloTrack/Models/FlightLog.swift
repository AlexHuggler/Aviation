import Foundation
import SwiftData

// MARK: - Schema Versioning (C-1: prevents data loss on schema evolution)

enum FlightLogSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FlightLog.self]
    }
}

enum FlightLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FlightLogSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []  // No migrations yet — V1 is the initial schema
    }
}

@Model
final class FlightLog {
    // MARK: - Core Flight Data
    var id: UUID
    var date: Date
    var durationHobbs: Double
    var durationTach: Double
    var routeFrom: String
    var routeTo: String

    // MARK: - Landings
    var landingsDay: Int
    var landingsNightFullStop: Int

    // MARK: - Flight Categories
    var isSolo: Bool
    var isDualReceived: Bool
    var isCrossCountry: Bool
    var isSimulatedInstrument: Bool

    // MARK: - Instructor Signature
    var instructorSignature: Data?
    var cfiNumber: String
    var signatureDate: Date?
    var isSignatureLocked: Bool

    // MARK: - Metadata
    var remarks: String
    var createdAt: Date

    init(
        date: Date = .now,
        durationHobbs: Double = 0.0,
        durationTach: Double = 0.0,
        routeFrom: String = "",
        routeTo: String = "",
        landingsDay: Int = 1,  // M-5: aligned with UI default — every flight has at least one landing
        landingsNightFullStop: Int = 0,
        isSolo: Bool = false,
        isDualReceived: Bool = false,
        isCrossCountry: Bool = false,
        isSimulatedInstrument: Bool = false,
        instructorSignature: Data? = nil,
        cfiNumber: String = "",
        signatureDate: Date? = nil,
        isSignatureLocked: Bool = false,
        remarks: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.durationHobbs = durationHobbs
        self.durationTach = durationTach
        self.routeFrom = routeFrom
        self.routeTo = routeTo
        self.landingsDay = landingsDay
        self.landingsNightFullStop = landingsNightFullStop
        self.isSolo = isSolo
        self.isDualReceived = isDualReceived
        self.isCrossCountry = isCrossCountry
        self.isSimulatedInstrument = isSimulatedInstrument
        self.instructorSignature = instructorSignature
        self.cfiNumber = cfiNumber
        self.signatureDate = signatureDate
        self.isSignatureLocked = isSignatureLocked
        self.remarks = remarks
        self.createdAt = .now
    }

    // MARK: - Computed Properties

    var totalLandings: Int {
        landingsDay + landingsNightFullStop
    }

    var hasValidSignature: Bool {
        instructorSignature != nil && !cfiNumber.isEmpty && signatureDate != nil
    }

    var isEditable: Bool {
        !isSignatureLocked
    }

    var formattedRoute: String {
        if routeFrom.isEmpty && routeTo.isEmpty { return "Local" }
        if routeFrom.isEmpty { return routeTo.uppercased() }
        if routeTo.isEmpty { return routeFrom.uppercased() }
        return "\(routeFrom.uppercased()) → \(routeTo.uppercased())"
    }

    var formattedDuration: String {
        String(format: "%.1f", durationHobbs)
    }

    var categoryTags: [String] {
        var tags: [String] = []
        if isSolo { tags.append("Solo") }
        if isDualReceived { tags.append("Dual") }
        if isCrossCountry { tags.append("XC") }
        if isSimulatedInstrument { tags.append("Inst") }
        return tags
    }

    // MARK: - Signature Management

    func lockSignature(signatureData: Data, cfi: String) {
        self.instructorSignature = signatureData
        self.cfiNumber = cfi
        self.signatureDate = .now
        self.isSignatureLocked = true
    }

    func voidSignature() {
        self.instructorSignature = nil
        self.cfiNumber = ""
        self.signatureDate = nil
        self.isSignatureLocked = false
    }
}
