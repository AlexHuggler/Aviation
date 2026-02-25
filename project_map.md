# SoloTrack — Architecture Map

## Frameworks

| Layer | Technology | Notes |
|-------|-----------|-------|
| **UI** | **SwiftUI** (pure, iOS 17+) | No UIKit views except PencilKit bridge |
| **Persistence** | **SwiftData** | `@Model` on `FlightLog`, `@Query` in views |
| **User Preferences** | **UserDefaults** | Onboarding state via `OnboardingManager` |
| **Signature Capture** | **PencilKit** | `UIViewRepresentable` bridge in `SignatureCaptureView` |
| **Notifications** | **UserNotifications** | Smart pipeline: Evaluator → Scorer → Rate-limiter → Dispatch |
| **Haptics** | **UIKit** + SwiftUI | Centralized `HapticService` enum + `.sensoryFeedback` |

**No third-party dependencies.** No SPM, CocoaPods, or Carthage. Apple first-party frameworks only.

## Pattern: MVVM-Lite / View-Service Hybrid

- **Views** own `@Query` (SwiftData) and `@State` for UI state — no formal ViewModel layer
- **Services** (`CurrencyManager`, `ProgressTracker`, `CSVExporter`) are stateless structs with pure business logic
- **Single @Observable class**: `OnboardingManager` (`@MainActor`) injected via SwiftUI environment
- Follows Apple's recommended SwiftUI + SwiftData pattern

## Entry Point

```
@main SoloTrackApp
  └─ WindowGroup
       ├─ .modelContainer(for: FlightLog.self)
       └─ .environment(OnboardingManager)
            └─ ContentView (TabView, 3 tabs)
                 ├─ Tab 0: DashboardView
                 ├─ Tab 1: PPLProgressView
                 └─ Tab 2: LogbookListView
```

## Module Map

```
SoloTrack/
├── SoloTrackApp.swift               — @main entry, ModelContainer + Environment setup
├── Models/
│   ├── FlightLog.swift              — @Model, 14 properties, computed categoryTags
│   └── OnboardingProfile.swift      — TrainingStage, CoachMarkStep, OnboardingManager
├── Views/
│   ├── ContentView.swift            — Root TabView + coach mark overlay
│   ├── DashboardView.swift          — Currency cards, progress nudge, quick stats
│   ├── ProgressView.swift           — PPL requirements ring + requirement rows
│   ├── LogbookListView.swift        — Flight list, search, detail, FlightRow, CategoryBadge
│   ├── AddFlightView.swift          — Flight entry form (smart defaults, Hobbs calc, quick-entry)
│   ├── OnboardingView.swift         — 2-step persona + intent questionnaire
│   ├── ExportView.swift             — CSV preview, share, clipboard copy
│   └── Components/
│       ├── SignatureCaptureView.swift      — PencilKit UIViewRepresentable bridge
│       ├── CoachMarkOverlay.swift          — Interactive tour overlay
│       └── PersonalizedEmptyDashboard.swift — Stage-aware empty state
├── Services/
│   ├── CurrencyManager.swift        — FAR 61.57 day/night currency calculations
│   ├── ProgressTracker.swift        — FAR 61.109 PPL requirements tracking
│   ├── CSVExporter.swift            — Logbook → CSV conversion
│   └── NotificationService.swift    — Evaluator → Scorer → Rate-limiter → Dispatch
├── Theme/
│   └── AppTheme.swift               — AppTokens, Color ext, ViewModifiers, HapticService
└── Tests/ (5 suites, ~115 tests, Swift Testing)
    ├── CSVExporterTests.swift
    ├── CurrencyManagerTests.swift
    ├── ProgressTrackerTests.swift
    ├── NotificationServiceTests.swift
    └── OnboardingManagerTests.swift
```

## Key Design Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| `AppTokens` | `AppTheme.swift` | Design tokens (Spacing, Radius, Duration, Opacity, Size) |
| `HapticService` | `AppTheme.swift` | Pre-allocated UIFeedbackGenerators for ~50ms latency reduction |
| `motionAwareAnimation` | `AppTheme.swift` | ViewModifier that suppresses animations when Reduce Motion enabled |
| `.task(id:)` | Multiple views | Auto-cancelling structured concurrency for toasts/timers |
| `cardStyle()` | `AppTheme.swift` | Standard card container modifier |
| `sectionHeaderStyle()` | `AppTheme.swift` | Uppercase tracking header text |
| Persona-driven defaults | `TrainingStage` | preSolo/postSolo/checkridPrep drives form defaults + dashboard emphasis |
