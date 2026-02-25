import SwiftUI

struct ContentView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var selectedTab = 0

    var body: some View {
        @Bindable var onboarding = onboarding

        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent", value: 0) {
                    DashboardView()
                }

                Tab("Progress", systemImage: "chart.bar.fill", value: 1) {
                    PPLProgressView()
                }

                Tab("Logbook", systemImage: "book.closed.fill", value: 2) {
                    LogbookListView()
                }
            }
            .tint(Color.skyBlue)

            // Coach mark overlay (shown during interactive tour)
            if let step = onboarding.currentCoachStep {
                CoachMarkOverlay(step: step)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .motionAwareAnimation(.spring(duration: 0.4), value: onboarding.currentCoachStep)
        // Present onboarding sheet on first launch
        .onAppear {
            if !onboarding.hasCompletedOnboarding {
                onboarding.showOnboardingSheet = true
            }
        }
        .sheet(isPresented: $onboarding.showOnboardingSheet) {
            OnboardingView()
        }
        // Drive tab selection during coach mark tour
        .onChange(of: onboarding.currentCoachStep) { _, newStep in
            if let tab = newStep?.associatedTab {
                withMotionAwareAnimation(.smooth(duration: 0.3)) {
                    selectedTab = tab
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FlightLog.self, inMemory: true)
        .environment(OnboardingManager())
}
