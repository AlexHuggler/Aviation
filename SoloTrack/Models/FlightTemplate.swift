import Foundation
import SwiftData

@Model
final class FlightTemplate {
    var id: UUID
    var name: String
    var routeFrom: String
    var routeTo: String
    var typicalHobbs: Double
    var isSolo: Bool
    var isDualReceived: Bool
    var isCrossCountry: Bool
    var isSimulatedInstrument: Bool
    var defaultLandingsDay: Int
    var remarks: String
    var cfiNumber: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        routeFrom: String = "",
        routeTo: String = "",
        typicalHobbs: Double = 0,
        isSolo: Bool = false,
        isDualReceived: Bool = false,
        isCrossCountry: Bool = false,
        isSimulatedInstrument: Bool = false,
        defaultLandingsDay: Int = 1,
        remarks: String = "",
        cfiNumber: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.routeFrom = routeFrom
        self.routeTo = routeTo
        self.typicalHobbs = typicalHobbs
        self.isSolo = isSolo
        self.isDualReceived = isDualReceived
        self.isCrossCountry = isCrossCountry
        self.isSimulatedInstrument = isSimulatedInstrument
        self.defaultLandingsDay = defaultLandingsDay
        self.remarks = remarks
        self.cfiNumber = cfiNumber
        self.createdAt = createdAt
    }
}
