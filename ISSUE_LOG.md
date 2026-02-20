# SoloTrack — Issue Log

Findings from deep-dive technical review, ranked by severity.

---

## Critical (Crashes / Data Loss)

### C-1: Onboarding sheet never dismisses after completion
**File**: `OnboardingProfile.swift:242-253`, `ContentView.swift:41`
**Impact**: The onboarding sheet is permanently stuck open after the user taps "Get Started."

`completeOnboarding()` sets `hasCompletedOnboarding = true` and updates intent-driven state, but never sets `showOnboardingSheet = false`. The sheet is bound to `$onboarding.showOnboardingSheet` in `ContentView`, so it remains presented indefinitely. The user cannot reach the app.

### C-2: `isFormDirty` false positive when persona defaults pre-set Solo/Dual
**File**: `AddFlightView.swift:63-78`, `AddFlightView.swift:181-184`
**Impact**: Brand-new AddFlightView is immediately "dirty," blocking swipe-to-dismiss and showing a misleading "Discard Flight?" alert on Cancel.

When `applyDefaults()` sets `isSolo` or `isDualReceived` based on the user's training stage, `isFormDirty` returns `true` because it checks `|| isSolo || isDualReceived`. Combined with `.interactiveDismissDisabled(isFormDirty)` (line 141), the user cannot dismiss a form they haven't touched.

### C-3: `PPLRequirement.id` generates a new UUID on every instantiation
**File**: `ProgressTracker.swift:6`
**Impact**: O(n) view destruction/recreation on every SwiftData query update; potential animation glitches.

`PPLRequirement` is a struct with `let id = UUID()`. Since `computeRequirements()` is called on every body evaluation, each call produces 6 new `PPLRequirement` values with fresh UUIDs. SwiftUI's `ForEach` treats every item as new, defeating diffing. All `RequirementRow` views are torn down and recreated instead of updated in-place.

### C-4: Force-unwraps on `Calendar.date(byAdding:)` throughout CurrencyManager
**File**: `CurrencyManager.swift:74, 102, 145, 158`
**Impact**: Theoretical crash if Calendar returns nil (extremely unlikely for simple day additions, but violates defensive coding).

Four instances of `calendar.date(byAdding: .day, value: ..., to: ...)!`. Also in `LogbookListView.swift:209`: `calendar.date(from: calendar.dateComponents(...))!`.

---

## High (Performance / UX)

### H-1: `@Observable` computed properties backed by UserDefaults bypass observation tracking
**File**: `OnboardingProfile.swift:198-227`
**Impact**: Views reading `hasCompletedOnboarding`, `trainingStage`, etc. won't re-render if these properties change in isolation.

The `@Observable` macro only synthesizes observation tracking for stored properties. Computed properties that delegate to `UserDefaults` don't trigger `withMutation(keyPath:)`. Currently this works by coincidence because `completeOnboarding()` also mutates stored properties (`shouldOpenAddFlight`, `currentCoachStep`), which triggers a re-render that picks up the UserDefaults changes. But any future code that modifies only these UserDefaults-backed properties will silently fail to update the UI.

### H-2: `computeRequirements` called 3 times per Dashboard body evaluation
**File**: `DashboardView.swift:141, 236`
**Impact**: Redundant O(n) array scans on every body evaluation.

`progressNudgeSection` calls `computeRequirements(from:)` directly. `quickStatsSection` calls `requirementsMet(from:)` which internally calls `computeRequirements(from:)` again. `totalRequirements()` is a third call (though trivially O(1)). The full requirements array is computed twice per render.

### H-3: Duplicate flight sheet in LogbookListView is a no-op
**File**: `LogbookListView.swift:82-91`
**Impact**: The duplicate-from-detail-view sheet opens but doesn't pre-fill from the source flight.

The `.sheet(item: $duplicatingFlight)` creates an `AddFlightView(editingFlight: nil, ...)` and has an `.onAppear` block that's an empty comment. The duplicate flow from swipe actions (line 264) works correctly by inserting directly, but the detail-view duplicate path is broken.

### H-4: `UIScreen.main.scale` is deprecated
**File**: `SignatureCaptureView.swift:121`
**Impact**: Deprecation warning; will be removed in a future iOS version.

`UIScreen.main.scale` was deprecated in iOS 16. The signature capture should use the canvas view's trait collection `displayScale` instead.

### H-5: `DispatchQueue.main.asyncAfter` for delayed UI state changes
**File**: `DashboardView.swift:47`, `LogbookListView.swift:106`, `ExportView.swift:66`
**Impact**: No cancellation on view dismissal; potential state updates on deallocated views.

If a toast's auto-dismiss timer fires after the parent view has been removed from the hierarchy, the `@State` mutation is a no-op (SwiftUI handles this gracefully), but it's still an unstructured concurrency pattern that should be replaced with `.task`/`try await Task.sleep`.

### H-6: Missing `@MainActor` on `OnboardingManager`
**File**: `OnboardingProfile.swift:193`
**Impact**: No compile-time guarantee that UserDefaults access and UI state mutations happen on the main thread.

`OnboardingManager` is always accessed from SwiftUI views (main actor) in practice, but lacks the explicit annotation. Adding `@MainActor` prevents future callers from accidentally accessing it from background threads.

---

## Medium (Tech Debt)

### M-1: `LogbookListView.swift` is 563 lines — God File
**File**: `LogbookListView.swift`
**Impact**: Maintainability; contains 7 distinct view types in a single file.

`FlightDetailView` (130+ lines), `FlightRow`, `CategoryBadge`, `DetailItem`, `SummaryPill`, and `SavedToastView` are all defined inline. `FlightDetailView` in particular has its own sheet, alert, and toolbar logic.

### M-2: `DashboardFocus` enum is defined but never read
**File**: `OnboardingProfile.swift:80-86`
**Impact**: Dead code.

`TrainingStage.primaryDashboardFocus` returns a `DashboardFocus` value, but no view consumes it. The feature highlights in `PersonalizedEmptyDashboard` use hardcoded per-stage arrays instead.

### M-3: Missing `OnboardingManager` environment in Previews
**File**: `PPLProgressView.swift:197-200`, `LogbookListView.swift:560-563`
**Impact**: Preview crashes when presenting AddFlightView as a sheet (which requires `@Environment(OnboardingManager.self)`).

### M-4: `recentRoutes` ForEach uses `\.from` as id — collisions
**File**: `AddFlightView.swift:227`
**Impact**: Routes sharing the same departure airport are deduplicated incorrectly. `KSJC→KRHV` and `KSJC→KPAO` — only one would render.

### M-5: No test infrastructure
**Impact**: Zero automated validation of business logic.

`CurrencyManager`, `ProgressTracker`, and `CSVExporter` are pure functions/structs with no external dependencies — ideal for unit testing. Currency calculations involve date math and rolling windows that are particularly error-prone without tests.

### M-6: `CoachMarkStep.body` property name shadows View protocol
**File**: `OnboardingProfile.swift:147`
**Impact**: Readability confusion. `CoachMarkStep` is an enum (not a View), so no compile error, but a `body` property on any type in a SwiftUI codebase is easily misread.

### M-7: Hardcoded frame sizes don't scale with Dynamic Type
**File**: `SignatureCaptureView.swift:56` (`.frame(height: 120)`), `ExportView.swift:33` (`.frame(maxHeight: 200)`), `AppTokens.Size` values
**Impact**: At XXL or AX Dynamic Type sizes, fixed containers may clip content.

### M-8: `UINotificationFeedbackGenerator` instantiated inline per trigger
**File**: 11+ call sites across the codebase
**Impact**: Apple recommends creating the generator once and calling `.prepare()` before triggering for optimal haptic latency. Current pattern adds ~50ms latency to each haptic.
