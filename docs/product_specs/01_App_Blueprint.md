# SoloTrack — App Blueprint

## 1. Overview

SoloTrack is a native iOS flight logbook application purpose-built for student pilots pursuing their Private Pilot License (PPL). It provides FAR-compliant flight logging, automatic currency tracking under FAR 61.57, and progress visualization against FAR 61.109 PPL aeronautical experience requirements.

The app is entirely offline — no network calls, no cloud backend, no user accounts. All data lives on-device using Apple's SwiftData framework. This architecture prioritizes privacy, simplicity, and reliability in environments where connectivity is not guaranteed (airports, flight schools, cockpits).

---

## 2. Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **UI** | SwiftUI (pure) | No UIKit views except PencilKit bridge |
| **Persistence** | SwiftData | `@Model` on `FlightLog`, `@Query` in views |
| **User Preferences** | UserDefaults | Onboarding state via `OnboardingManager` |
| **Signature Capture** | PencilKit | `UIViewRepresentable` bridge in `SignatureCaptureView` |
| **Haptics** | UIKit + SwiftUI | `UINotificationFeedbackGenerator` and `.sensoryFeedback` |
| **Testing** | Swift Testing | 4 test suites, ~521 lines |
| **Dependency Management** | None | Zero third-party dependencies |

**UIKit surface area** (minimal): `UIViewRepresentable` for `PKCanvasView`, `UIImage(data:)` for signature rendering, `UINotificationFeedbackGenerator` for haptics, `UIPasteboard` for clipboard, `UIScreen.main.scale` (deprecated in iOS 16).

---

## 3. Architecture Pattern

**MVVM-Lite / View-Service Hybrid** — a pragmatic pattern aligned with Apple's recommended SwiftUI + SwiftData approach:

- **Views** own `@Query` (SwiftData) and `@State` for local UI state. No formal ViewModel layer.
- **Services** (`CurrencyManager`, `ProgressTracker`, `CSVExporter`) are stateless structs that encapsulate business logic. Views instantiate them as `private let` properties or call static functions.
- **Models** are SwiftData `@Model` classes (`FlightLog`) and plain structs (`PPLRequirement`).
- **Shared observable state** (`OnboardingManager`) is an `@Observable` class injected via SwiftUI's environment at the app root.

This is not Clean Architecture, TCA (The Composable Architecture), or strict MVVM. The stateless service pattern keeps business logic testable without mocking, while views remain thin consumers of reactive data.

---

## 4. Core Data Models

### 4.1 FlightLog (`SoloTrack/Models/FlightLog.swift`)

The primary persisted entity. A SwiftData `@Model` class with 15 stored properties:

| Group | Field | Type | Default |
|-------|-------|------|---------|
| **Core** | `id` | `UUID` | Auto-generated |
| | `date` | `Date` | `.now` |
| | `durationHobbs` | `Double` | `0.0` |
| | `durationTach` | `Double` | `0.0` |
| | `routeFrom` | `String` | `""` |
| | `routeTo` | `String` | `""` |
| **Landings** | `landingsDay` | `Int` | `0` |
| | `landingsNightFullStop` | `Int` | `0` |
| **Categories** | `isSolo` | `Bool` | `false` |
| | `isDualReceived` | `Bool` | `false` |
| | `isCrossCountry` | `Bool` | `false` |
| | `isSimulatedInstrument` | `Bool` | `false` |
| **Signature** | `instructorSignature` | `Data?` | `nil` |
| | `cfiNumber` | `String` | `""` |
| | `signatureDate` | `Date?` | `nil` |
| | `isSignatureLocked` | `Bool` | `false` |
| **Metadata** | `remarks` | `String` | `""` |
| | `createdAt` | `Date` | `.now` |

**Computed properties**: `totalLandings`, `hasValidSignature`, `isEditable`, `formattedRoute`, `formattedDuration`, `categoryTags`.

**Signature methods**: `lockSignature(signatureData:cfi:)` and `voidSignature()` manage the CFI endorsement lifecycle.

### 4.2 OnboardingManager (`SoloTrack/Models/OnboardingProfile.swift`)

An `@Observable @MainActor` class managing onboarding and tour state. Persisted properties use `didSet` to sync to UserDefaults; restored in `init()`.

| Property | Type | Persistence | Purpose |
|----------|------|-------------|---------|
| `hasCompletedOnboarding` | `Bool` | UserDefaults | Gates onboarding sheet |
| `hasCompletedTour` | `Bool` | UserDefaults | Gates coach mark overlay |
| `trainingStage` | `TrainingStage` | UserDefaults | Persona selection |
| `gettingStartedIntent` | `GettingStartedIntent` | UserDefaults | Post-onboarding routing |
| `currentCoachStep` | `CoachMarkStep?` | In-memory | Active tour step |
| `showOnboardingSheet` | `Bool` | In-memory | Sheet presentation |
| `shouldOpenAddFlight` | `Bool` | In-memory | Auto-open flight form |

### 4.3 PPLRequirement (`SoloTrack/Services/ProgressTracker.swift`)

A transient struct computed from flight data on each view evaluation. Not persisted.

| Field | Type | Purpose |
|-------|------|---------|
| `id` | `String` (derived from `farReference`) | Stable identity for SwiftUI diffing |
| `title` | `String` | Display name (e.g., "Total Flight Time") |
| `farReference` | `String` | FAR citation (e.g., "61.109(a)") |
| `goalHours` | `Double` | Required hours |
| `loggedHours` | `Double` | Accumulated hours from flights |

**Computed**: `progress`, `percentComplete`, `isMet`, `remainingHours`, `formattedProgress`, `formattedRemaining`.

### 4.4 Supporting Enums

| Enum | File | Values | Purpose |
|------|------|--------|---------|
| `TrainingStage` | `OnboardingProfile.swift` | `preSolo`, `postSolo`, `checkridPrep` | Persona-driven defaults and dashboard emphasis |
| `GettingStartedIntent` | `OnboardingProfile.swift` | `logFresh`, `backfill`, `explore` | Post-onboarding routing |
| `CoachMarkStep` | `OnboardingProfile.swift` | 6 steps (0–5) | Interactive tour sequence |
| `CurrencyState` | `CurrencyManager.swift` | `valid(daysRemaining)`, `caution(daysRemaining)`, `expired(daysSince)` | FAR 61.57 compliance status |
| `DashboardFocus` | `OnboardingProfile.swift` | `currency`, `progress`, `progressGaps` | Dashboard emphasis per persona (currently unused) |

---

## 5. Module Dependency Graph

```
@main SoloTrackApp
  ├── Creates: OnboardingManager, ModelContainer(FlightLog)
  │
  └── ContentView (TabView, 3 tabs)
       ├── Reads: OnboardingManager
       ├── Presents: OnboardingView (sheet), CoachMarkOverlay (ZStack)
       │
       ├── Tab 0: DashboardView (NavigationStack)
       │    ├── Queries: FlightLog (@Query)
       │    ├── Uses: CurrencyManager, ProgressTracker
       │    ├── Presents: AddFlightView (sheet)
       │    └── Contains: CurrencyCard, StatCard, PersonalizedEmptyDashboard
       │
       ├── Tab 1: PPLProgressView (NavigationStack)
       │    ├── Queries: FlightLog (@Query)
       │    ├── Uses: ProgressTracker
       │    ├── Presents: AddFlightView (sheet)
       │    └── Contains: RequirementRow
       │
       └── Tab 2: LogbookListView (NavigationStack)
            ├── Queries: FlightLog (@Query)
            ├── Mutates: ModelContext (insert, delete)
            ├── Uses: CSVExporter
            ├── Presents: AddFlightView (sheet), ExportView (sheet)
            └── Contains: FlightRow, FlightDetailView, CategoryBadge,
                          DetailItem, SummaryPill, SavedToastView

AddFlightView
  ├── Queries: FlightLog (recent flights for smart defaults)
  ├── Mutates: ModelContext (insert/update)
  ├── Reads: OnboardingManager
  └── Contains: SignatureCaptureView (PencilKit bridge)

Services (stateless structs)
  ├── CurrencyManager  → [FlightLog] → CurrencyState
  ├── ProgressTracker   → [FlightLog] → [PPLRequirement]
  └── CSVExporter       → [FlightLog] → String (CSV)
```

---

## 6. Third-Party Integrations

**None.** SoloTrack has zero external dependencies. There is no `Package.swift` (SPM), `Podfile` (CocoaPods), `Cartfile` (Carthage), or any third-party library.

The app uses exclusively Apple first-party frameworks:
- **SwiftUI** — UI layer
- **SwiftData** — Local persistence
- **PencilKit** — Signature capture
- **Foundation** — Date math, formatting, string processing
- **UIKit** — Minimal bridging (haptics, clipboard, image rendering)

There is no networking stack — no REST clients, no GraphQL, no CloudKit, no Firebase, no analytics SDKs.

---

## 7. Design System

The app uses a token-based design system defined in `SoloTrack/Theme/AppTheme.swift`.

### Design Tokens (`AppTokens`)

| Scale | Values |
|-------|--------|
| **Spacing** | `xxs`(2), `xs`(4), `sm`(6), `md`(8), `lg`(12), `xl`(16), `xxl`(20), `section`(24) |
| **Corner Radius** | `sm`(8), `md`(10), `lg`(12), `xl`(14), `card`(16) |
| **Animation Duration** | `quick`(0.3s), `normal`(0.4s), `slow`(0.6s), `ring`(0.8s), `toast`(2.0s) |
| **Opacity** | `subtle`(0.08), `light`(0.15), `medium`(0.30), `strong`(0.60) |
| **Sizes** | `dateCircle`(44), `progressRing`(160), `strokeWidth`(12), `signatureHeight`(80), `inputWidth`(80), `onboardingIcon`(56), `coachMarkMaxWidth`(340) |

### Color Palette

| Name | RGB | Usage |
|------|-----|-------|
| Sky Blue | (0.40, 0.73, 0.94) | Primary accent, buttons, selected states |
| Currency Green | (0.18, 0.80, 0.44) | Valid/current status |
| Caution Yellow | (1.0, 0.76, 0.03) | Expiring soon (≤30 days) |
| Warning Red | (0.91, 0.22, 0.22) | Expired/not current |

### View Modifiers

| Modifier | Effect |
|----------|--------|
| `CardStyle` | 16pt padding, `.ultraThinMaterial` background, 16pt corner radius |
| `SectionHeaderStyle` | Caption font, rounded design, uppercase, 1.2pt letter spacing, secondary color |
| `ReducedMotionAware` | Disables animations when `accessibilityReduceMotion` is enabled |

---

## 8. Security & Compliance

### Data Security
- **Local-only storage**: All flight data stored on-device via SwiftData. No data leaves the device.
- **No network surface**: Zero API calls, no analytics, no telemetry. No attack surface for network-based threats.
- **Device-level encryption**: SwiftData inherits iOS Data Protection (encrypted at rest when device is locked).
- **No user authentication**: Single-user app model — the device owner is the user. No passwords, no biometrics at the app level.

### Signature Integrity
- **Signature locking**: Once a CFI signs a flight (`lockSignature()`), the flight becomes read-only. No fields can be modified.
- **Void with intent**: Signatures can only be voided through an explicit `voidSignature()` action with a confirmation alert.
- **Signature data**: Stored as PNG `Data` blob in SwiftData alongside the CFI certificate number and signature date.

### Regulatory Compliance
- **FAR 61.57**: Day and night currency calculations implement the 90-day rolling window with 3-landing requirement per the Federal Aviation Regulations.
- **FAR 61.109**: PPL aeronautical experience requirements tracked for all 6 categories defined in the regulation.
- **Note**: SoloTrack is a tracking tool — it does not replace official FAA records. The app does not validate ICAO codes, cross-reference with ATC records, or interface with FAA systems.

---

## 9. Known Architectural Gaps

### Missing Infrastructure
- **No CI/CD pipeline**: No GitHub Actions, Jenkins, or automated build/test configuration.
- **No Xcode project file**: The repository contains only Swift source files — no `.xcodeproj` or `.xcworkspace`. Build configuration is not version-controlled.
- **No CloudKit sync**: Data exists only on the local device. Device loss, damage, or reset means complete data loss.
- **No data backup/restore**: No export-to-backup or import-from-backup capability beyond CSV export.

### Critical Bugs (from ISSUE_LOG.md)
- **C-1**: Onboarding sheet never dismisses after completion — blocks first-time users from reaching the app.
- **C-2**: `isFormDirty` false positive when persona defaults pre-set Solo/Dual toggles — misleading "Discard?" alert.
- **C-3**: `PPLRequirement.id` was regenerating UUID on every instantiation (has since been fixed with `farReference`-based stable ID).
- **C-4**: Force-unwraps on `Calendar.date(byAdding:)` in CurrencyManager — 4 locations.

### Performance Concerns
- **H-2**: `computeRequirements()` called 2–3 times per Dashboard body evaluation — redundant O(n) array scans.
- **H-5**: `DispatchQueue.main.asyncAfter` used for delayed UI state changes — no cancellation on view dismissal.
- **M-1**: `LogbookListView.swift` is 563 lines containing 7 distinct view types (God File pattern).

### Test Coverage
- 4 test suites exist covering `CurrencyManager`, `ProgressTracker`, `CSVExporter`, and `OnboardingManager`.
- ~521 lines of test code (~14.8% of codebase by LOC).
- No UI tests or integration tests.
