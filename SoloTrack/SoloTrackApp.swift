import SwiftUI
import SwiftData

@main
struct SoloTrackApp: App {
    @State private var onboarding = OnboardingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(onboarding)
        }
        .modelContainer(for: FlightLog.self)
    }
}
