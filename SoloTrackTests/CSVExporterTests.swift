import Testing
import Foundation
@testable import SoloTrack

// MARK: - CSV Exporter Tests

struct CSVExporterTests {

    @Test("Empty flights produces header-only CSV")
    func emptyFlights() {
        let csv = CSVExporter.generateCSV(from: [])

        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 1) // header only
        #expect(lines[0].contains("Date"))
        #expect(lines[0].contains("Hobbs"))
    }

    @Test("Single flight produces correct CSV row")
    func singleFlight() {
        let flight = FlightLog(
            date: makeDate(year: 2025, month: 6, day: 15),
            durationHobbs: 1.5,
            durationTach: 1.3,
            routeFrom: "KSJC",
            routeTo: "KRHV",
            landingsDay: 3,
            landingsNightFullStop: 0,
            isSolo: true,
            isDualReceived: false,
            isCrossCountry: true,
            isSimulatedInstrument: false,
            remarks: "Pattern work"
        )

        let csv = CSVExporter.generateCSV(from: [flight])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2) // header + 1 row

        let row = lines[1]
        #expect(row.contains("2025-06-15"))
        #expect(row.contains("KSJC"))
        #expect(row.contains("KRHV"))
        #expect(row.contains("1.5"))
        #expect(row.contains("1.3"))
        #expect(row.contains("Y")) // Solo = Y
    }

    @Test("CSV escapes fields with commas")
    func escapesCommas() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            remarks: "Winds 270, gusty"
        )

        let csv = CSVExporter.generateCSV(from: [flight])
        #expect(csv.contains("\"Winds 270, gusty\""))
    }

    @Test("CSV escapes fields with double quotes")
    func escapesQuotes() {
        let flight = FlightLog(
            durationHobbs: 1.0,
            remarks: "Called \"base\" early"
        )

        let csv = CSVExporter.generateCSV(from: [flight])
        #expect(csv.contains("\"Called \"\"base\"\" early\""))
    }

    @Test("CSV sorts flights chronologically (oldest first)")
    func sortedChronologically() {
        let earlier = FlightLog(
            date: makeDate(year: 2025, month: 1, day: 1),
            durationHobbs: 1.0,
            routeFrom: "FIRST"
        )
        let later = FlightLog(
            date: makeDate(year: 2025, month: 6, day: 1),
            durationHobbs: 1.0,
            routeFrom: "SECOND"
        )

        // Pass in reverse order
        let csv = CSVExporter.generateCSV(from: [later, earlier])
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines[1].contains("FIRST"))   // older flight first
        #expect(lines[2].contains("SECOND"))
    }

    @Test("CSV header has exactly 13 columns")
    func headerColumnCount() {
        let csv = CSVExporter.generateCSV(from: [])
        let header = csv.components(separatedBy: "\n")[0]
        let columns = header.components(separatedBy: ",")
        #expect(columns.count == 13)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
