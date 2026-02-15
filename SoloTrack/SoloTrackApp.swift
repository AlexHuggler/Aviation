import SwiftUI
import SwiftData

@main
struct SoloTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FlightLog.self)
    }
}
