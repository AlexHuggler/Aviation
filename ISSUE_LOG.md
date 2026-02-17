# SoloTrack — Issue Log

Technical review conducted against all 13 source files (~2,189 LOC).
Ranked by severity: **Critical** (crashes/data loss), **High** (performance/UX), **Medium** (tech debt).

---

## Critical (Crashes / Data Loss)

### C-1: No SwiftData `VersionedSchema` — Silent Data Loss on Schema Change

**File**: `FlightLog.swift`, `SoloTrackApp.swift:10`
**Issue**: The model container is created with `.modelContainer(for: FlightLog.self)` and no migration plan. If any stored property is added, renamed, or removed in `FlightLog`, SwiftData will fail to open the existing store. Depending on the OS version, this manifests as:
- A crash on launch (`NSInternalInconsistencyException`)
- Silent store reset (all flights deleted)

**Risk**: Any future schema evolution destroys user data. This is the single most dangerous defect in the codebase.
**Fix**: Introduce `VersionedSchema` + `SchemaMigrationPlan` with a `V1` schema snapshot.

---

### C-2: Force-Unwrapped `Calendar.date(byAdding:)` in Currency Calculations

**File**: `CurrencyManager.swift:69, 97, 140, 153`
**Issue**: Four force-unwraps (`!`) on `Calendar.date(byAdding:to:)` results. While `Calendar.date(byAdding: .day, ...)` is practically infallible, the contract returns `Date?`. If the system calendar or locale produces `nil` (edge case with exotic calendar systems or corrupt date data), the app crashes.
**Pattern**:
```swift
let windowStart = calendar.date(byAdding: .day, value: -lookbackDays, to: referenceDate)! // line 69
```
**Fix**: Guard-let with a sensible fallback or use a helper that fatalErrors with diagnostic info in DEBUG but returns a safe default in RELEASE.

---

### C-3: `PPLRequirement.id` is Regenerated on Every Computation — SwiftUI Identity Instability

**File**: `ProgressTracker.swift:6`
**Issue**: `let id = UUID()` in `PPLRequirement` means every call to `computeRequirements(from:)` generates new UUIDs. Since `PPLProgressView` recomputes requirements on every `@Query` change, `ForEach(requirements)` sees entirely new identities each render. This causes:
- Full view teardown/rebuild instead of diffing (performance)
- Loss of in-flight animations and scroll position
- Potential phantom state if SwiftUI caches by ID

**Fix**: Use a stable, deterministic ID (e.g., `farReference` which is unique per requirement).

---

## High (Performance / UX)

### H-1: `UIScreen.main.scale` Deprecated — Warning Accumulation

**File**: `SignatureCaptureView.swift:121`
**Issue**: `UIScreen.main` is deprecated in iOS 16+ and will generate a compiler warning. In multi-screen environments (iPad + external display), it returns the wrong scale factor.
**Fix**: Pass the trait collection's `displayScale` from the view's environment or use `@Environment(\.displayScale)`.

---

### H-2: `ProgressTracker` Recomputes Requirements 3× Per Dashboard Render

**File**: `DashboardView.swift:138-139, 148`
**Issue**: `quickStatsSection` calls both `requirementsMet(from:)` and `totalRequirements()`. Internally, `requirementsMet` calls `computeRequirements(from:)` which iterates all flights 6 times (once per requirement). The `populatedDashboard` also calls `currencyManager` methods that iterate flights. The dashboard body thus iterates the flights array **14+ times** per render.
**Impact**: Negligible at <100 flights, but O(n) × 14 becomes visible at 500+ flights.
**Fix**: Compute requirements once and pass the result down, or cache in a computed property.

---

### H-3: `DateFormatter` Allocated Inside `CurrencyState.absoluteDateLabel` Computed Property

**File**: `CurrencyManager.swift:46-47`
**Issue**: Every access to `absoluteDateLabel` allocates a new `DateFormatter`. This property is called from `CurrencyCard.body`, which can re-evaluate on every frame during animation (`.animation(.smooth(duration: 0.4), value: state)`).
**Fix**: Use a static `DateFormatter` or `Date.FormatStyle`.

---

### H-4: `PKCanvasView` Stored as `@State` Value Type — Potential Drawing Loss

**File**: `SignatureCaptureView.swift:26`
**Issue**: `@State private var canvasView = PKCanvasView()` stores a UIKit reference type in `@State`. While this works for simple cases, SwiftUI's `@State` is designed for value types. If SwiftUI recreates the view's state storage (e.g., during tab switching or memory pressure), the `PKCanvasView` instance and its drawing data can be silently replaced with a fresh instance, losing the user's signature mid-drawing.
**Fix**: Move `PKCanvasView` management into the `UIViewRepresentable` coordinator, or use `@StateObject` with an `ObservableObject` wrapper.

---

### H-5: No Dynamic Type Support on Fixed-Width Elements

**File**: `AddFlightView.swift:182,196` (`frame(width: 80)`), `FlightRow` (`.frame(width: 44)`)
**Issue**: Hobbs/Tach text fields have `frame(width: 80)` and the date circle has `frame(width: 44)`. At accessibility text sizes (AX1–AX5), these clips truncate content.
**Fix**: Use `minWidth` instead of fixed `width`, or adopt `.fixedSize()` with layout priority.

---

### H-6: `LogbookListView` Contains 545 Lines — God View

**File**: `LogbookListView.swift`
**Issue**: This file contains `LogbookListView`, `SummaryPill`, `SavedToastView`, `FlightRow`, `CategoryBadge`, `FlightDetailView`, and `DetailItem` — 7 view types in one file. This makes the file hard to navigate, test, and review. `FlightDetailView` alone is ~130 lines of complex signature/void logic.
**Impact**: Maintainability, not runtime.
**Fix**: Extract `FlightDetailView`, `FlightRow`, and `CategoryBadge` into their own files.

---

### H-7: Missing `Sendable` Conformance on `CurrencyManager` and `ProgressTracker`

**File**: `CurrencyManager.swift:60`, `ProgressTracker.swift:41`
**Issue**: Both structs are instantiated in SwiftUI view bodies and could potentially be captured in concurrent contexts (e.g., `.task {}` modifiers). Under strict concurrency checking (Swift 6 mode), these will produce warnings because `Calendar` stored properties aren't explicitly `Sendable`-safe.
**Impact**: Future Swift 6 migration blocker.
**Fix**: Mark both as `struct ... : Sendable` (they already satisfy the requirements since all stored properties are value types).

---

## Medium (Tech Debt)

### M-1: Inline `UINotificationFeedbackGenerator()` Instantiation (9 Call Sites)

**Files**: `AddFlightView.swift` (4×), `LogbookListView.swift` (3×), `SignatureCaptureView.swift` (1×), `ExportView.swift` (1×)
**Issue**: Each haptic trigger instantiates a new `UINotificationFeedbackGenerator()`. Per Apple docs, generators should be prepared in advance with `.prepare()` for lower-latency feedback.
**Fix**: Centralize into a `HapticEngine` singleton or create generators once per view lifecycle.

---

### M-2: `CurrencyState` Conforms to `Comparable` Without Explicit Implementation

**File**: `CurrencyManager.swift:5`
**Issue**: `enum CurrencyState: Comparable, Hashable` — the `Comparable` conformance is synthesized by the compiler based on case declaration order. This means `.valid < .caution < .expired`, which may be semantically backwards (is "valid" less than "expired"?). Any sorting or comparison using `<` will produce counter-intuitive results.
**Fix**: Either remove `Comparable` if unused, or provide an explicit `static func < ` implementation with clear semantics.

---

### M-3: `ExportView` CSV Preview Has Hardcoded Max Height

**File**: `ExportView.swift:33`
**Issue**: `.frame(maxHeight: 200)` on the CSV preview scroll view. On smaller iPhones (SE) with large text, this leaves minimal room for the buttons below. On iPads, it wastes screen real estate.
**Fix**: Use a proportional height or `GeometryReader`-based fraction.

---

### M-4: No Unit Tests Exist

**Issue**: Zero test targets. `CurrencyManager`, `ProgressTracker`, and `CSVExporter` are all pure-function services that are trivially testable but have no tests. The currency calculation logic (FAR 61.57 rolling window, edge cases around exactly 3 landings, expiration boundary) is safety-critical for a pilot app and absolutely must be validated.
**Fix**: Add a test target with unit tests for all three services.

---

### M-5: `FlightLog.init` Default `landingsDay` is 0, But `AddFlightView` Defaults to 1

**File**: `FlightLog.swift:40` vs `AddFlightView.swift:32`
**Issue**: The model's `init` parameter defaults `landingsDay` to `0`, while the form defaults to `1`. Any code path that creates a `FlightLog` without explicitly passing `landingsDay` (e.g., the `duplicateFlight` function, tests, or future migration code) will get the model's default of 0, not the UI's default of 1. The two defaults are inconsistent.
**Fix**: Align the model default to `1`, or document the discrepancy.

---

### M-6: Logbook `duplicateFlight` Bypasses `AddFlightView` Validation

**File**: `LogbookListView.swift:245-263`
**Issue**: `duplicateFlight` directly inserts a `FlightLog` via `modelContext.insert()` without going through the validation logic in `AddFlightView.saveFlight()`. This means a duplicated flight could have 0 landings, >12hr Hobbs, or other values that the form would reject.
**Fix**: Either validate in the model layer, or route duplicates through the form.

---

### M-7: `FlightDetailView.onDuplicate` Callback is Declared But Never Connected

**File**: `LogbookListView.swift:391`
**Issue**: `FlightDetailView` accepts `var onDuplicate: ((FlightLog) -> Void)?` and it's passed from `LogbookListView`, but `FlightDetailView.body` never calls `onDuplicate`. There is no "Duplicate" button in the detail view, so the callback is dead code.
**Fix**: Either add a duplicate button in the detail view, or remove the callback.

---

### M-8: `duplicatingFlight` Sheet Doesn't Actually Pre-Fill the Form

**File**: `LogbookListView.swift:82-91`
**Issue**: The `.sheet(item: $duplicatingFlight)` creates an `AddFlightView(editingFlight: nil, ...)`. Since `editingFlight` is `nil`, the form won't pre-populate from the duplicated flight. The `.onAppear` block is empty with a comment saying "handled by creating a temporary flight and passing values" but no implementation exists. The actual duplication is done by `duplicateFlight()` which inserts directly.
**Fix**: Remove the dead sheet, since `duplicateFlight()` handles the action directly via `modelContext.insert()`.

---

### Summary

| Severity | Count | Key Themes |
|----------|-------|------------|
| **Critical** | 3 | Data loss risk, crash-prone force unwraps, identity instability |
| **High** | 7 | Deprecated APIs, performance waste, god views, Swift 6 readiness |
| **Medium** | 8 | No tests, inconsistent defaults, dead code, haptic allocation waste |
| **Total** | **18** | |
