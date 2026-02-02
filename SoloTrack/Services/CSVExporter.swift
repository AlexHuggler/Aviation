import Foundation

struct CSVExporter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func generateCSV(from flights: [FlightLog]) -> String {
        var csv = "Date,From,To,Hobbs,Tach,Day Landings,Night FS Landings,"
        csv += "Solo,Dual,XC,Instrument,CFI Number,Remarks\n"

        let sorted = flights.sorted { $0.date < $1.date }
        for flight in sorted {
            let row = [
                dateFormatter.string(from: flight.date),
                escapeCsvField(flight.routeFrom),
                escapeCsvField(flight.routeTo),
                String(format: "%.1f", flight.durationHobbs),
                String(format: "%.1f", flight.durationTach),
                "\(flight.landingsDay)",
                "\(flight.landingsNightFullStop)",
                flight.isSolo ? "Y" : "N",
                flight.isDualReceived ? "Y" : "N",
                flight.isCrossCountry ? "Y" : "N",
                flight.isSimulatedInstrument ? "Y" : "N",
                escapeCsvField(flight.cfiNumber),
                escapeCsvField(flight.remarks),
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    private static func escapeCsvField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
