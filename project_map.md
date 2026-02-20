# SoloTrack — Project Architecture Map

## 1. Primary Frameworks

| Layer | Technology | Notes |
|-------|-----------|-------|
| **UI** | **SwiftUI** (pure) | No UIKit views except PencilKit bridge |
| **Persistence** | **SwiftData** | `@Model` on `FlightLog`, `@Query` in views |
| **User Preferences** | **UserDefaults** | Onboarding state via `OnboardingManager` |
| **Signature Capture** | **PencilKit** | `UIViewRepresentable` bridge in `SignatureCaptureView` |
| **Haptics** | **UIKit** (`UINotificationFeedbackGenerator`) + SwiftUI `.sensoryFeedback` | Mixed usage |

**UIKit surface area**: `UIViewRepresentable` for `PKCanvasView`, `UIImage(data:)` for signature rendering, `UINotificationFeedbackGenerator` for haptics, `UIPasteboard` for clipboard, `UIScreen.main.scale` (deprecated).

## 2. Dependency Management

**None.** No `Package.swift` (SPM), `Podfile` (CocoaPods), `Cartfile` (Carthage), or `.xcodeproj` present in the repository. The project uses only Apple first-party frameworks. No third-party dependencies.

## 3. Pattern Strategy

**MVVM-Lite / View-Service** — a pragmatic hybrid:

- **Views** own `@Query` (SwiftData) and `@State` for UI state. No formal ViewModel layer.
- **Services** (`CurrencyManager`, `ProgressTracker`, `CSVExporter`) are stateless structs that encapsulate business logic. Views instantiate them as `private let` properties or call them as static functions.
- **Models** are SwiftData `@Model` classes (`FlightLog`) and plain structs (`PPLRequirement`).
- **Observable state** (`OnboardingManager`) is an `@Observable` class injected via SwiftUI's environment at the app root — acts as a lightweight shared state coordinator.

This is **not** Clean Architecture, TCA (The Composable Architecture), or strict MVVM. It's closer to Apple's recommended SwiftUI+SwiftData pattern where views directly query the model layer and delegate complex computations to service types.

## 4. Persistence Layer

| Store | What | How |
|-------|------|-----|
| **SwiftData** | Flight log entries | `@Model FlightLog`, `ModelContainer` on `WindowGroup` |
| **UserDefaults** | Onboarding completion, training stage, getting-started intent, tour state | `OnboardingManager` computed properties |
| **In-Memory** | Transient UI state (coach step, sheet presentation, form fields) | `@State`, `@FocusState`, `@Observable` stored properties |

**No networking stack.** The app is entirely offline. No REST/GraphQL clients, no CloudKit sync, no remote persistence.

## 5. Entry Point & Navigation

```
@main SoloTrackApp
  └─ WindowGroup
       ├─ .modelContainer(for: FlightLog.self)
       └─ .environment(OnboardingManager)
            └─ ContentView (TabView, 3 tabs)
                 ├─ Tab 0: DashboardView (NavigationStack)
                 ├─ Tab 1: PPLProgressView (NavigationStack)
                 └─ Tab 2: LogbookListView (NavigationStack)
```

## 6. Module Dependency Graph

```
SoloTrackApp.swift ─────────────────────────────────────────────────
  │  Creates: OnboardingManager, ModelContainer
  │
  └─► ContentView.swift
       │  Reads: OnboardingManager
       │  Presents: OnboardingView (sheet), CoachMarkOverlay (ZStack)
       │
       ├─► DashboardView.swift
       │    │  Queries: FlightLog (SwiftData)
       │    │  Reads: OnboardingManager
       │    │  Uses: CurrencyManager, ProgressTracker
       │    │  Presents: AddFlightView (sheet)
       │    │  Contains: CurrencyCard, StatCard, OnboardingRow (private)
       │    │
       │    └─► PersonalizedEmptyDashboard.swift
       │         Reads: OnboardingManager
       │         Contains: FeatureHighlightRow (private)
       │
       ├─► PPLProgressView.swift
       │    │  Queries: FlightLog (SwiftData)
       │    │  Uses: ProgressTracker
       │    │  Presents: AddFlightView (sheet)
       │    │  Contains: RequirementRow
       │    │
       │    └─► (no child components)
       │
       └─► LogbookListView.swift
            │  Queries: FlightLog (SwiftData)
            │  Mutates: ModelContext (delete, insert)
            │  Uses: CSVExporter
            │  Presents: AddFlightView (sheet), ExportView (sheet)
            │  Contains: FlightRow, CategoryBadge, FlightDetailView,
            │            DetailItem, SummaryPill (private), SavedToastView (private)
            │
            └─► FlightDetailView.swift (inline in LogbookListView.swift)
                 Presents: AddFlightView (sheet, edit mode)

AddFlightView.swift ──────────────────────────────────────────────
  │  Queries: FlightLog (recent, for smart defaults)
  │  Mutates: ModelContext (insert/update)
  │  Reads: OnboardingManager
  │  Contains: SignatureCaptureView
  │
  └─► SignatureCaptureView.swift
       Bridge: PKCanvasView (UIViewRepresentable)

OnboardingView.swift ─────────────────────────────────────────────
  │  Reads/Writes: OnboardingManager
  │  Contains: OnboardingOptionCard (private)

CoachMarkOverlay.swift ───────────────────────────────────────────
  │  Reads/Writes: OnboardingManager

Services (stateless) ─────────────────────────────────────────────
  CurrencyManager.swift    → Pure functions on [FlightLog] → CurrencyState
  ProgressTracker.swift    → Pure functions on [FlightLog] → [PPLRequirement]
  CSVExporter.swift        → Static function [FlightLog] → String

Models ───────────────────────────────────────────────────────────
  FlightLog.swift          → @Model (SwiftData), 15 persisted properties
  OnboardingProfile.swift  → TrainingStage, GettingStartedIntent, CoachMarkStep (enums)
                             OnboardingManager (@Observable class)

Theme ────────────────────────────────────────────────────────────
  AppTheme.swift           → AppTokens (design tokens), Color extensions,
                             CurrencyState+Color, ViewModifiers (CardStyle,
                             SectionHeaderStyle, ReducedMotionAware)
```

## 7. Test Infrastructure

**None.** No XCTest targets, no Swift Testing files, no test directories. The three service types (`CurrencyManager`, `ProgressTracker`, `CSVExporter`) contain pure business logic that is highly testable without any mocking.
