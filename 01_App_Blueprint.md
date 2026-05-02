# SoloTrack - App Blueprint

## 1. Overview

SoloTrack is a native iOS flight logbook for student pilots working toward a Private Pilot License (PPL). The shipped product now spans more than the core app UI: it includes the main SoloTrack app, a shared data layer for extension targets, Home Screen widgets, a control widget, App Shortcuts / App Intents, and a local Live Activity for a single active flight session timer.

The product remains local-first. Daily use works on-device without an account or network connection, while optional iCloud sync can keep flights and templates available across devices through SwiftData + CloudKit. Shared extension surfaces use an App Group container so widgets, Shortcuts, and timer features can read or hand off data without requiring the main app to be foregrounded.

As of April 18, 2026, the shipped product includes:

- Expanded flight-training detail fields for checkride and instrument tracking
- Flight templates and quick-entry flows for repeated logging
- CSV import from multiple formats with duplicate detection
- Dual export modes: raw CSV and printable PDF
- Optional iCloud sync with a local-only fallback
- Lifecycle-driven notifications for currency, milestones, and momentum
- iPhone tab navigation plus iPad `NavigationSplitView`
- Home Screen widgets for currency, PPL progress, and last flight
- App Shortcuts / App Intents for logging, status checks, and timer control
- A single active flight-session timer with control-widget and Live Activity support

---

## 2. Product Surface Map

SoloTrack currently ships four user-facing layers:

| Surface | Role |
|---------|------|
| **Main app (`SoloTrack`)** | Primary logging, progress, settings, import/export, signatures, timer control |
| **Shared support layer (`SoloTrackShared`)** | Shared models, shared store access, widget data, timer state, deep links |
| **Widget extension (`SoloTrackWidgets`)** | Currency, progress, last-flight widgets, control widget, Live Activity |
| **App Intents / Shortcuts (`SoloTrack/Intents`)** | Quick logging, status queries, open-add-flight deep link, timer start/stop |

`docs/product_specs` should now be read as documenting the full shipped SoloTrack product, not only the main app target.

`SoloTrackShared` is the bridge that keeps those targets aligned. `AppGroup`, `SharedModelContainer`, and `SoloTrackDeepLink` let widgets and intents read current logbook state and route the user back into the right app surface, while timer state remains device-local even when flights and templates sync through iCloud.

---

## 3. Tech Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| **UI** | SwiftUI | Main app, widgets, and Live Activity UI |
| **Persistence** | SwiftData | `FlightLog` and `FlightTemplate` schema |
| **Cloud Sync** | CloudKit via SwiftData | Optional, user-controlled, restart required after mode change |
| **Cross-surface storage** | App Groups + shared `UserDefaults` | Widgets, App Intents, and timer state |
| **Widgets** | WidgetKit | Currency, progress, last-flight, and control widget |
| **Automation** | App Intents / App Shortcuts | Logging, status checks, timer control, deep-link entry |
| **Live status** | ActivityKit | Single active flight-session Live Activity |
| **User Preferences** | UserDefaults | Onboarding, sync preference, notification memory, custom airports, timer state |
| **Signature Capture** | PencilKit | `PKCanvasView` bridged through `UIViewRepresentable` |
| **Notifications** | UserNotifications | Authorization + high-value event dispatch pipeline |
| **Export** | Foundation + UIKit | RFC 4180 CSV and paginated PDF generation |
| **Import** | Foundation | CSV parser with presets and preview validation |
| **Testing** | Swift Testing + UI Tests | 13 unit suites plus UI automation |
| **Dependencies** | Apple frameworks only | No third-party packages |

### UIKit Surface Area

SoloTrack remains mostly SwiftUI, with small first-party bridges for:

- PencilKit signature capture
- UIKit-based PDF rendering
- `UIPasteboard` clipboard copy
- `UIImage(data:)` rendering for signatures in detail and export surfaces
- `UIApplication.open(_:)` for deep-link based open-add-flight behavior
- Centralized feedback generators in `HapticService`

---

## 4. Architecture Pattern

SoloTrack follows a practical SwiftUI + SwiftData architecture that is closest to MVVM-lite / view-service hybrid, now extended across app and extension targets:

- **Views** own reactive UI state via `@State`, `@Query`, `@FocusState`, and environment-backed observable objects.
- **Models** are SwiftData `@Model` classes for persisted data plus plain structs for derived business outputs and timer/session state.
- **Services** are mostly stateless structs that compute progress, currency, imports, exports, widget data, notifications, deep-link support, and app launch behavior.
- **Shared observable state** is carried by small `@Observable` classes such as `OnboardingManager`, `SyncSettings`, and `FlightSessionController`.
- **Shared target code** in `SoloTrackShared` gives extensions stable access to the same domain concepts without depending on the main app runtime.

This keeps the app lightweight while still allowing widgets, App Intents, and Live Activity surfaces to reflect the same core product model.

---

## 5. Core Models and Shared Domain Types

### 5.1 FlightLog

`FlightLog` is the primary persisted record and now captures both base logging data and richer training-compliance metadata.

| Group | Fields |
|-------|--------|
| **Core** | `id`, `date`, `durationHobbs`, `durationTach`, `routeFrom`, `routeTo` |
| **Landings** | `landingsDay`, `landingsNightFullStop` |
| **Core Categories** | `isSolo`, `isDualReceived`, `isCrossCountry`, `isSimulatedInstrument` |
| **Training Detail** | `isFlightReview`, `instrumentApproaches`, `performedHoldingProcedures`, `performedCourseTracking`, `crossCountryDistanceNM`, `longestCrossCountryLegNM`, `fullStopAirportsCount`, `isToweredAirportOperations`, `isCheckridePrepFlight` |
| **Endorsement** | `instructorSignature`, `cfiNumber`, `signatureDate`, `isSignatureLocked` |
| **Metadata** | `remarks`, `createdAt` |

Important computed behavior:

- `formattedRoute` normalizes empty/local route displays
- `totalLandings` aggregates day + night landing counts
- `hasValidSignature` and `isEditable` drive endorsement UI and edit permissions
- `duplicateIdentityKey` powers import duplicate detection
- `categoryTags` feeds logbook rows, detail badges, PDF exports, and widget summaries

### 5.2 FlightTemplate

`FlightTemplate` is a first-class SwiftData model for repeated logging patterns.

Stored fields:

- `id`, `name`, `routeFrom`, `routeTo`
- `typicalHobbs`
- `isSolo`, `isDualReceived`, `isCrossCountry`, `isSimulatedInstrument`
- `defaultLandingsDay`
- `remarks`, `cfiNumber`, `createdAt`

Templates are available in new-flight flows and reduce repeated entry for common lessons and route pairs.

### 5.3 Onboarding and Navigation State

`OnboardingManager` persists:

- `hasCompletedOnboarding`
- `hasCompletedTour`
- `trainingStage`
- `gettingStartedIntent`

It also carries transient routing state such as:

- `currentCoachStep`
- `showOnboardingSheet`
- `shouldOpenAddFlight`

`NavigationSection` defines the iPad sidebar model and mirrors the iPhone tab structure.

### 5.4 Sync and Session State

`SyncSettings` tracks:

- the active storage mode (`localOnly` or `iCloud`)
- the user’s desired next mode
- whether relaunch is required to apply the change

The flight-session feature is represented through shared session types:

- `FlightSession`
- `FlightSessionPrefill`
- `FlightSessionSource`

These types allow a single active timer to be started from the app, a control widget, or a Shortcut, then converted into a prefilled Add Flight form.

### 5.5 Derived Domain Types

Non-persisted domain types that shape product behavior include:

- `CurrencyState`
- `PPLRequirement`
- `PPLChecklistItem`
- `FlightRecommendation`
- `ImportSession`, `ImportPreviewRow`, `ImportedFlightData`
- `PDFExportDocument`, `PDFExportSummary`, `PDFLogbookRow`
- `NotificationEvent`, `ScoredEvent`
- `WidgetData`

---

## 6. Runtime Architecture

### 6.1 App Launch

`SoloTrackApp` performs several important startup actions:

1. Reads `AppLaunchConfiguration.current`
2. Resets persistent state when launch arguments request it
3. Migrates an older default SwiftData store into the App Group container via `DataMigrator`
4. Builds the SwiftData `ModelContainer`
5. Seeds optional smoke-test data
6. Seeds an optional active timer session for test scenarios

The app root injects:

- `.modelContainer(...)` for `FlightLog` and `FlightTemplate`
- `OnboardingManager`
- `SyncSettings`
- `FlightSessionController`
- `notificationCoordinator()`

It also handles deep links via:

- `solotrack://add-flight`
- `solotrack://dashboard`

### 6.2 Root Navigation

`ContentView` now has dual layouts:

| Device Class | Root Navigation |
|--------------|-----------------|
| **iPhone / compact width** | `TabView` with Dashboard, Progress, Logbook |
| **iPad / regular width** | `NavigationSplitView` sidebar using `NavigationSection` |

Root-level modals and overlays:

- `OnboardingView`
- post-onboarding `AddFlightView`
- `KeyboardShortcutsView`
- `CoachMarkOverlay`

Root-level behaviors:

- deep-link handling for add-flight and dashboard return
- pending timer-prefill consumption on foreground / launch
- app-wide tab and sidebar synchronization

### 6.3 Dashboard Runtime Role

`DashboardView` is now both a status screen and an active control surface. In addition to currency, stats, and the next milestone, it owns:

- the settings entry point
- direct Add Flight launch
- the flight-session card for starting or stopping the single active timer
- timer-prefill handoff into Add Flight when a session stops in-app

---

## 7. Shared Storage, Sync, and Cross-Surface Access

### 7.1 App Group Strategy

SoloTrack now uses an App Group for extension-safe shared storage:

- shared SwiftData store location
- shared `UserDefaults`
- timer state handoff
- deep-link entry coordination

`AppGroup.storeURL` and `AppGroup.sharedDefaults` provide the base storage handles used across targets.

### 7.2 SharedModelContainer

Widgets and App Intents do not use the main app’s runtime `ModelContainer` directly. Instead they use `SharedModelContainer`, which:

- points at the App Group store
- disables CloudKit in extension contexts
- can create isolated or in-memory containers for tests
- fetches flights for widget and Shortcut calculations

### 7.3 Sync Boundaries

SoloTrack supports two operating modes:

| Mode | Behavior |
|------|----------|
| **Local Only** | Flights and templates stay on-device only |
| **iCloud Sync** | Flights and templates sync via SwiftData + CloudKit |

Important boundaries:

- flights and templates are the only sync-scoped data
- onboarding state stays local
- notification history and milestone memory stay local
- custom ICAO airport entries stay local
- timer state and pending timer-prefill state stay local and device-scoped through the App Group
- changing sync mode updates the desired state immediately, but the active model container changes only after relaunch

---

## 8. Major Service Layer

### 8.1 Progress and Compliance

- `CurrencyManager`
  - day currency under FAR 61.57(a)
  - night currency under FAR 61.57(b)
  - instrument currency under FAR 61.57(c)
  - flight review recency under FAR 61.56
- `ProgressTracker`
  - six top-level FAR 61.109 requirement buckets
  - checklist-style training requirements
  - training-stage suggestions
  - dashboard flight recommendations

### 8.2 Import / Export

- `CSVExporter`
  - generates chronologically sorted CSV with 22 columns
  - escapes commas, quotes, and newlines
- `PDFExporter`
  - filters flights by optional date range
  - builds a printable, paginated logbook PDF
  - includes totals, endorsements, notes, and page count
- `ImportParser`
  - supports preset or auto-detected CSV import flows
  - parses SoloTrack, ForeFlight-style, LogTen-style, MyFlightBook-style, and generic CSV layouts
  - flags duplicates, warnings, and hard errors before import

### 8.3 Notifications

- `NotificationEvaluator` identifies high-value moments:
  - currency cliffs
  - newly met milestones
  - checkride-ready state
  - momentum stalls
- `NotificationService` scores events, applies cooldown rules, honors stored opt-in flags, and schedules notifications
- `NotificationCoordinator` wires evaluation into app lifecycle transitions

### 8.4 Flight Session and Multi-Surface Handoff

- `FlightSessionStore`
  - persists the single active timer session
  - stores a one-time pending prefill when timer surfaces stop outside the app
- `FlightSessionController`
  - synchronizes main-app UI with the shared timer store
  - starts and stops the active session
  - consumes pending prefills into Add Flight
- `FlightSessionActivityManager`
  - starts, syncs, and ends the Live Activity
- `SoloTrackDeepLink`
  - generates deep links for `add-flight` and `dashboard`

### 8.5 Shared Surface Data

- `WidgetDataProvider`
  - loads flights from the shared store
  - computes current currency, progress, and last-flight summaries for widgets
- `ICAODatabase`
  - built-in airport reference data
  - custom airport persistence
  - prefix suggestions and known-airport checks

---

## 9. Shipped Extension Surfaces

### 9.1 App Shortcuts / App Intents

Current shipped intents:

- `LogQuickFlightIntent`
- `CheckCurrencyIntent`
- `NextMilestoneIntent`
- `OpenAddFlightIntent`
- `StartFlightSessionIntent`
- `StopFlightSessionIntent`

These intents support quick logging, status queries, direct app entry, and timer control without navigating the full app UI first.

### 9.2 Widget Bundle

`SoloTrackWidgetBundle` currently ships:

- `CurrencyWidget`
- `PPLProgressWidget`
- `LastFlightWidget`
- `SoloTrackWidgetsControl`
- `SoloTrackWidgetsLiveActivity`

The widget/control/live-activity layer gives users glanceable access to:

- current flight currency
- PPL progress
- their most recent flight
- timer start/stop from Control Center or Lock Screen
- in-flight elapsed time with a return path back into SoloTrack

---

## 10. Testing and QA Shape

The current automated test surface spans the main app target, shared support layer, App Intents, widget data derivation, and UI automation through 13 unit suites plus UI tests.

Unit suites currently cover:

- route autocomplete
- CSV export
- currency calculations
- data migration
- flight-session storage
- import parsing
- intents
- notification service
- onboarding manager
- PDF export
- progress tracking
- shared model container behavior
- widget data provider behavior

The app also includes launch hooks for:

- isolated `UserDefaults` suites
- custom store URLs
- smoke seed data
- persistent-state reset for test runs
- active-session seeding
- skipping notification authorization during automation

---

## 11. Product Strengths and Constraints

### Current Strengths

- Fast, student-focused logging experience with more structure than a general-purpose logbook
- Regulatory interpretation built directly into the product surface
- Offline-capable daily workflow with optional cloud backup/sync
- Strong import/export posture for migration, backup, and checkride prep
- Glanceable and automation-friendly system surfaces through widgets, Shortcuts, and a timer Live Activity
- No third-party dependency surface

### Current Constraints

- iOS-only product with no watchOS or macOS companion app
- Notification preferences exist in storage/service logic but are not exposed in a dedicated settings UI
- Cloud sync is limited to flights and templates rather than every preference and support artifact
- The flight-session timer supports a single active session only
- No external flight-tracker integrations yet
- No multi-user instructor dashboard or collaboration model
