import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent") {
                DashboardView()
            }

            Tab("Progress", systemImage: "chart.bar.fill") {
                PPLProgressView()
            }

            Tab("Logbook", systemImage: "book.closed.fill") {
                LogbookListView()
            }
        }
        .tint(Color.skyBlue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
