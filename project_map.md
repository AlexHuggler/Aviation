# SoloTrack — Architecture Map

## Overview

SoloTrack is a pure SwiftUI (iOS 17+) aviation training logbook app for student pilots pursuing their Private Pilot License. It tracks flight hours, FAR 61.57 passenger currency, and FAR 61.109 PPL requirements with zero third-party dependencies.

**Total**: 31 Swift files, ~6,100 lines of code

---

## Frameworks

| Layer | Technology | Notes |
|-------|-----------|-------|
| **UI** | **SwiftUI** (pure, iOS 17+) | No UIKit views except PencilKit bridge |
| **Persistence** | **SwiftData** | `@Model` on `FlightLog` + `FlightTemplate`, `@Query` in views |
| **User Preferences** | **UserDefaults** | Onboarding state via `OnboardingManager`, notification prefs |
| **Signature Capture** | **PencilKit** | `UIViewRepresentable` bridge in `SignatureCaptureView` |
| **Notifications** | **UserNotifications** | Smart pipeline: Evaluator -> Scorer -> Rate-limiter -> Dispatch |
| **Haptics** | **UIKit** + SwiftUI | Centralized `HapticService` enum + `.sensoryFeedback` |
| **Logging** | **os** | `Logger(subsystem:category:)` in NotificationService |

**No third-party dependencies.** No SPM, CocoaPods, or Carthage. Apple first-party frameworks only.

---

## Pattern: MVVM-Lite / View-Service Hybrid

- **Views** own `@Query` (SwiftData) and `@State` for UI state -- no formal ViewModel layer
- **Services** (`CurrencyManager`, `ProgressTracker`, `CSVExporter`, `NotificationService`) are stateless structs with pure business logic
- **Single @Observable class**: `OnboardingManager` (`@MainActor`) injected via SwiftUI environment
- Follows Apple's recommended SwiftUI + SwiftData pattern

---

## Entry Point & Navigation Flow

```
@main SoloTrackApp
  |-- .modelContainer(for: [FlightLog.self, FlightTemplate.self])
  |-- .environment(OnboardingManager)
  |-- .notificationCoordinator()
  |
  +-- ContentView (TabView, 3 tabs + CoachMarkOverlay)
       |
       |-- Tab 0: DashboardView
       |     |-- CurrencyManager   (FAR 61.57 day/night currency)
       |     |-- ProgressTracker   (FAR 61.109 requirement tracking)
       |     +-- AddFlightView     (via sheet, with FlightRecommendation)
       |
       |-- Tab 1: PPLProgressView
       |     +-- ProgressTracker
       |
       +-- Tab 2: LogbookListView
             |-- CSVExporter       (logbook export)
             |-- AddFlightView     (via sheet, new + edit modes)
             |     |-- ICAODatabase (airport autocomplete)
             |     |-- FlightTemplate (@Query)
             |     +-- SignatureCaptureView (PencilKit bridge)
             +-- ExportView        (CSV preview/share)
```

### Services (stateless structs with pure business logic)

```
CurrencyManager         --> FlightLog[]  (FAR 61.57 rolling 90-day windows)
ProgressTracker         --> FlightLog[]  (FAR 61.109 requirements, 6 categories)
NotificationService     --> NotificationEvaluator --> FlightLog[]
  |-- Value Scorer      (0.0-1.0 heuristics by TrainingStage)
  |-- Rate Limiter      (per-category cooldown + daily cap of 2)
  +-- Dispatcher        (UNNotificationRequest scheduling)
CSVExporter             --> FlightLog[]  (RFC 4180 CSV)
ICAODatabase            (standalone, hardcoded + custom airports via UserDefaults)
```

### Notification Events

```
NotificationEvent (enum, 4 cases)
  |-- currencyCliff(kind, daysRemaining)    -- FAR 61.57 expiration warning
  |-- milestoneCrossed(title, farReference) -- PPL requirement newly met
  |-- checkrideReady                        -- All 6 requirements met (once-ever)
  +-- momentumStall(days, nextReq, hours)   -- 14+ days without a flight
```

### Theme

```
AppTheme.swift
  |-- AppTokens       (Spacing, Radius, Duration, Opacity, Size, Onboarding)
  |-- ScaledTokens     (@ScaledMetric for Dynamic Type, 17 dimensions)
  |-- Color extensions (skyBlue, currencyGreen, cautionYellow, warningRed, badges)
  |-- CurrencyState    (color, iconName extensions)
  |-- HapticService    (pre-allocated generators, compound patterns)
  +-- ViewModifiers    (CardStyle, SectionHeaderStyle, ReducedMotionAware)
```

---

## Data Models

### FlightLog (`@Model`, SwiftData)
**File**: `Models/FlightLog.swift`
- Core: `id`, `date`, `durationHobbs`, `durationTach`, `routeFrom`, `routeTo`
- Landings: `landingsDay`, `landingsNightFullStop`
- Categories: `isSolo`, `isDualReceived`, `isCrossCountry`, `isSimulatedInstrument`
- Signature: `instructorSignature` (Data?), `cfiNumber`, `signatureDate`, `isSignatureLocked`
- Metadata: `remarks`, `createdAt`
- Computed: `totalLandings`, `hasValidSignature`, `isEditable`, `formattedRoute`, `categoryTags`

### FlightTemplate (`@Model`, SwiftData)
**File**: `Models/FlightTemplate.swift`
- Route defaults, category flags, typical Hobbs, default landings, remarks, CFI number

### OnboardingManager (`@Observable`, `@MainActor`, UserDefaults-backed)
**File**: `Models/OnboardingProfile.swift`
- Enums: `TrainingStage` (preSolo/postSolo/checkridPrep), `GettingStartedIntent`, `CoachMarkStep`
- Persisted: `hasCompletedOnboarding`, `hasCompletedTour`, `trainingStage`, `gettingStartedIntent`
- Transient: `currentCoachStep`, `showOnboardingSheet`, `shouldOpenAddFlight`
- Actions: `completeOnboarding()`, `advanceTour()`, `completeTour()`, `skipTour()`, `resetOnboarding()`

---

## State Management

| Scope          | Mechanism                          | Example                                      |
|----------------|------------------------------------|----------------------------------------------|
| App-wide       | `@Observable` + `@Environment`     | `OnboardingManager`                          |
| Database       | `@Query` (SwiftData)               | `@Query var flights: [FlightLog]`            |
| View-local     | `@State`                           | `showingAddFlight`, `searchText`             |
| Form binding   | `@Binding`                         | SignatureCaptureView parameters              |
| Keyboard focus | `@FocusState`                      | AddFlightView field advancement              |
| Preferences    | `UserDefaults` (NotificationPrefs) | Cooldowns, opt-in flags, acknowledged milestones |
| Scene lifecycle| `@Environment(\.scenePhase)`       | NotificationCoordinator foreground detection |

---

## Module Map

```
SoloTrack/
|-- SoloTrackApp.swift               -- @main entry, ModelContainer + Environment setup
|-- Models/
|   |-- FlightLog.swift              -- @Model, 14 properties, computed categoryTags
|   |-- FlightTemplate.swift         -- @Model, quick-entry template
|   +-- OnboardingProfile.swift      -- TrainingStage, CoachMarkStep, OnboardingManager
|-- Views/
|   |-- ContentView.swift            -- Root TabView + coach mark overlay
|   |-- DashboardView.swift          -- Currency cards, progress nudge, quick stats
|   |-- ProgressView.swift           -- PPL requirements ring + requirement rows
|   |-- LogbookListView.swift        -- Flight list, search, filter, export
|   |-- AddFlightView.swift          -- Flight entry form (smart defaults, templates, quick-entry)
|   |-- FlightDetailView.swift       -- Full flight details + signature display
|   |-- FlightRow.swift              -- List item component
|   |-- OnboardingView.swift         -- 2-step persona + intent questionnaire
|   |-- ExportView.swift             -- CSV preview, share, clipboard copy
|   +-- Components/
|       |-- SignatureCaptureView.swift       -- PencilKit UIViewRepresentable bridge
|       |-- CoachMarkOverlay.swift           -- Interactive tour overlay
|       |-- PersonalizedEmptyDashboard.swift -- Stage-aware empty state
|       |-- ToastView.swift                  -- Confirmation/undo notifications
|       +-- KeyboardShortcutsView.swift      -- Cmd+1/2/3/? reference
|-- Services/
|   |-- CurrencyManager.swift        -- FAR 61.57 day/night currency calculations
|   |-- ProgressTracker.swift        -- FAR 61.109 PPL requirements tracking
|   |-- CSVExporter.swift            -- Logbook -> CSV conversion
|   |-- NotificationService.swift    -- Evaluator -> Scorer -> Rate-limiter -> Dispatch
|   |-- NotificationEvaluator.swift  -- Event detection heuristics
|   |-- NotificationCoordinator.swift-- SwiftUI lifecycle integration (ViewModifier)
|   +-- ICAODatabase.swift           -- Airport code reference data
|-- Theme/
|   +-- AppTheme.swift               -- AppTokens, Color ext, ViewModifiers, HapticService
+-- Tests/ (5 suites, ~115 tests, Swift Testing)
    |-- CSVExporterTests.swift
    |-- CurrencyManagerTests.swift
    |-- ProgressTrackerTests.swift
    |-- NotificationServiceTests.swift
    +-- OnboardingManagerTests.swift
```

---

## Key Design Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| `AppTokens` | `AppTheme.swift` | Design tokens (Spacing, Radius, Duration, Opacity, Size) |
| `ScaledTokens` | `AppTheme.swift` | `@ScaledMetric` wrappers for Dynamic Type responsive sizing |
| `HapticService` | `AppTheme.swift` | Pre-allocated UIFeedbackGenerators + compound patterns |
| `motionAwareAnimation` | `AppTheme.swift` | ViewModifier that suppresses animations when Reduce Motion enabled |
| `withMotionAwareAnimation` | `AppTheme.swift` | Imperative wrapper for `withAnimation` respecting Reduce Motion |
| `.task(id:)` | Multiple views | Auto-cancelling structured concurrency for toasts/timers |
| `cardStyle()` | `AppTheme.swift` | Standard card container modifier (padding + material + rounded) |
| `sectionHeaderStyle()` | `AppTheme.swift` | Uppercase tracking header text |
| Persona-driven defaults | `TrainingStage` | preSolo/postSolo/checkridPrep drives form defaults + dashboard emphasis |
| Smart focus skipping | `AddFlightView` | `firstEmptyRequiredField()` skips pre-filled fields |
| Route auto-swap | `AddFlightView` | XC return legs swap From/To within 24 hours |
