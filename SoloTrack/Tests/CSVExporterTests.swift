import Testing
import Foundation
@testable import SoloTrack

// MARK: - CSVExporter Tests

@Suite("CSVExporter — CSV generation and field escaping")
struct CSVExporterTests {

    @Test("Empty flight list → header row only")
    func emptyFlights() {
        let csv = CSVExporter.generateCSV(from: [])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 1)
        #expect(lines[0].contains("Date,From,To,Hobbs"))
    }

    @Test("Single flight → header + 1 data row")
    func singleFlight() {
        let flight = FlightLog(
            durationHobbs: 1.5,
            routeFrom: "KSJC",
            routeTo: "KRHV",
            landingsDay: 2,
            isSolo: true
        )
        let csv = CSVExporter.generateCSV(from: [flight])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 2)

        let dataRow = lines[1]
        #expect(dataRow.contains("KSJC"))
        #expect(dataRow.contains("KRHV"))
        #expect(dataRow.contains("1.5"))
        #expect(dataRow.contains("Y")) // Solo = Y
    }

    @Test("CSV escapes fields containing commas")
    func escapesCommas() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            remarks: "Good flight, smooth air"
        )
        let csv = CSVExporter.generateCSV(from: [flight])
        #expect(csv.contains("\"Good flight, smooth air\""))
    }

    @Test("CSV escapes fields containing quotes")
    func escapesQuotes() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            remarks: "Called \"downwind\" early"
        )
        let csv = CSVExporter.generateCSV(from: [flight])
        #expect(csv.contains("\"Called \"\"downwind\"\" early\""))
    }

    @Test("CSV escapes fields containing newlines")
    func escapesNewlines() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            remarks: "Line 1\nLine 2"
        )
        let csv = CSVExporter.generateCSV(from: [flight])
        #expect(csv.contains("\"Line 1\nLine 2\""))
    }

    @Test("Flights are sorted chronologically (oldest first)")
    func sortOrder() {
        let calendar = Calendar.current
        let older = FlightLog(date: calendar.date(byAdding: .day, value: -10, to: .now)!, durationHobbs: 1.0, routeFrom: "AAA")
        let newer = FlightLog(date: .now, durationHobbs: 2.0, routeFrom: "BBB")

        let csv = CSVExporter.generateCSV(from: [newer, older])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // First data row should be the older flight
        #expect(lines[1].contains("AAA"))
        #expect(lines[2].contains("BBB"))
    }

    @Test("Boolean fields render as Y/N")
    func booleanFields() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            isSolo: true,
            isDualReceived: false,
            isCrossCountry: true,
            isSimulatedInstrument: false
        )
        let csv = CSVExporter.generateCSV(from: [flight])
        let dataRow = csv.components(separatedBy: "\n").filter { !$0.isEmpty }[1]
        let fields = dataRow.components(separatedBy: ",")

        // Column indices: Solo=7, Dual=8, XC=9, Instrument=10
        #expect(fields[7] == "Y")  // Solo
        #expect(fields[8] == "N")  // Dual
        #expect(fields[9] == "Y")  // XC
        #expect(fields[10] == "N") // Instrument
    }
}
