# SoloTrack — Project Architecture Map

## 1. Primary Frameworks

| Layer       | Framework   | Version Target | Notes                          |
|-------------|-------------|----------------|--------------------------------|
| UI          | **SwiftUI** | iOS 17+        | Pure SwiftUI; no UIKit views except `PKCanvasView` bridge |
| UIKit Bridge| PencilKit   | iOS 17+        | `UIViewRepresentable` wrapper for signature capture |
| Persistence | **SwiftData**| iOS 17+       | `@Model`-based, single-entity schema (`FlightLog`) |
| Networking  | _None_      | —              | Fully offline, local-only app  |

**Hybrid Surface Area**: The only UIKit touchpoint is `SignatureCanvasView` (a `UIViewRepresentable` wrapping `PKCanvasView`). Everything else is declarative SwiftUI.

## 2. Dependency Management

**None / Zero dependencies.** The project has no `Package.swift`, `Podfile`, or `Cartfile`. All functionality is built on Apple first-party frameworks (SwiftUI, SwiftData, PencilKit, Foundation). There is no `.xcodeproj` or `.xcworkspace` in the repository — this is a single-target Swift package or Xcode project generated from the directory structure.

## 3. Pattern Strategy

**Standard MVC / "SwiftUI Vanilla"** — No MVVM, TCA, or Clean Architecture.

| Concern         | Implementation              | Assessment           |
|-----------------|-----------------------------|----------------------|
| Model           | `FlightLog` (`@Model`)      | Single entity, domain logic embedded |
| View            | 7 SwiftUI views             | Contains business logic directly (currency checks, aggregations) |
| ViewModel       | _None_                      | Views read `@Query` directly; no intermediate ViewModel layer |
| Services        | 3 service structs            | Stateless logic helpers, instantiated inline per-view |
| Navigation      | Per-view `NavigationStack`   | No coordinator pattern |
| State mgmt      | `@State` / `@Query` only    | No `@Observable`, no shared app state object |

The architecture is a **View-first pattern** where SwiftUI views own both presentation and orchestration. Services (`CurrencyManager`, `ProgressTracker`, `CSVExporter`) are pure-function stateless helpers instantiated as local `let` constants inside views.

## 4. Persistence Layer

| Component         | Detail                              |
|-------------------|-------------------------------------|
| Framework         | SwiftData                           |
| Container setup   | `SoloTrackApp.swift` line 10: `.modelContainer(for: FlightLog.self)` |
| Schema            | Single entity: `FlightLog` (21 stored properties) |
| Relationships     | None                                |
| Migrations        | None configured (no `VersionedSchema`) |
| Queries           | `@Query` macros in views (3 locations) |

**Networking Stack**: None. The app is entirely offline. Export is via `ShareLink` (local share sheet) and `UIPasteboard`.

## 5. Module Dependency Graph

```
┌─────────────────────────────────────────────────────┐
│                   SoloTrackApp                      │
│                  (Entry Point)                      │
│            @main / WindowGroup                      │
│         .modelContainer(for: FlightLog)             │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
              ┌────────────────┐
              │  ContentView   │
              │  (TabView)     │
              └───┬────┬────┬──┘
                  │    │    │
         ┌────────┘    │    └────────┐
         ▼             ▼             ▼
  ┌──────────┐  ┌────────────┐  ┌──────────────┐
  │Dashboard │  │PPLProgress │  │LogbookList   │
  │  View    │  │   View     │  │   View       │
  └──┬───┬───┘  └─────┬──────┘  └──┬───┬───┬───┘
     │   │            │            │   │   │
     │   │            ▼            │   │   │
     │   │    ┌───────────────┐    │   │   │
     │   │    │ProgressTracker│    │   │   │
     │   │    └───────────────┘    │   │   │
     │   │                         │   │   │
     │   ▼                         │   │   ▼
     │ ┌───────────────┐           │   │ ┌──────────┐
     │ │CurrencyManager│           │   │ │ExportView│
     │ └───────────────┘           │   │ └──────────┘
     │                             │   │      │
     ▼                             ▼   │      ▼
  ┌──────────────┐          ┌──────────┤  ┌───────────┐
  │ProgressTracker│          │AddFlight │  │CSVExporter│
  └──────────────┘          │  View    │  └───────────┘
                            └────┬─────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │SignatureCapture   │
                        │  View            │
                        │(UIViewRepresentable│
                        │ → PKCanvasView)  │
                        └──────────────────┘

  ═══════════════════════════════════════════
        Shared / Cross-Cutting Modules
  ═══════════════════════════════════════════

  ┌──────────────┐    ┌──────────────────┐
  │  FlightLog   │    │   AppTheme       │
  │  (@Model)    │    │ (Colors, Styles, │
  │              │    │  ViewModifiers)  │
  └──────────────┘    └──────────────────┘
      ▲ read by              ▲ used by
    every view             every view
   + all services
```

## 6. Entry Point

**`SoloTrackApp.swift`** — The `@main` struct. Creates a `WindowGroup` containing `ContentView` and attaches the SwiftData `.modelContainer(for: FlightLog.self)`.

## 7. File Inventory

| File | Lines | Role |
|------|-------|------|
| `SoloTrackApp.swift` | 13 | App entry point, model container |
| `ContentView.swift` | 26 | Tab navigation (Dashboard / Progress / Logbook) |
| `FlightLog.swift` | 121 | SwiftData model + computed properties |
| `CurrencyManager.swift` | 175 | FAR 61.57 currency calculations |
| `ProgressTracker.swift` | 104 | FAR 61.109 requirement tracking |
| `CSVExporter.swift` | 43 | CSV generation |
| `AppTheme.swift` | 67 | Colors, view modifiers |
| `DashboardView.swift` | 253 | Currency status + quick stats |
| `LogbookListView.swift` | 545 | Flight list, detail, search, row, badge |
| `AddFlightView.swift` | 425 | Flight entry/edit form |
| `ProgressView.swift` | 189 | PPL requirements progress |
| `ExportView.swift` | 102 | CSV export + share |
| `SignatureCaptureView.swift` | 126 | PencilKit signature pad |
| **Total** | **~2,189** | |
