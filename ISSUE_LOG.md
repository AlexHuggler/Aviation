# SoloTrack — Issue Log

Findings from deep-dive technical review, ranked by severity.
Status: **FIXED** = resolved, **OPEN** = pending, **N/A** = no longer applicable.

---

## Critical (Crashes / Data Loss)

### C-1: Onboarding sheet never dismisses after completion — FIXED
**File**: `OnboardingProfile.swift`, `ContentView.swift`
**Resolution**: `completeOnboarding()` now sets `showOnboardingSheet = false`.

### C-2: `isFormDirty` false positive when persona defaults pre-set Solo/Dual — FIXED
**File**: `AddFlightView.swift`
**Resolution**: `isFormDirty` now accounts for persona-driven default values.

### C-3: `PPLRequirement.id` generates a new UUID on every instantiation — FIXED
**File**: `ProgressTracker.swift`
**Resolution**: Changed to deterministic ID based on `farReference`.

### C-4: Force-unwraps on `Calendar.date(byAdding:)` throughout CurrencyManager — FIXED
**File**: `CurrencyManager.swift`
**Resolution**: Replaced `!` with `?? Date()` fallback.

---

## High (Performance / UX)

### H-1: `@Observable` computed properties backed by UserDefaults bypass observation tracking — FIXED
**File**: `OnboardingProfile.swift`
**Resolution**: Properties now use stored properties with `didSet` syncing to UserDefaults.

### H-2: `computeRequirements` called 3 times per Dashboard body evaluation — FIXED
**File**: `DashboardView.swift`
**Resolution**: Cached requirements in a single `let` binding.

### H-3: Duplicate flight sheet in LogbookListView is a no-op — FIXED
**File**: `LogbookListView.swift`
**Resolution**: Removed broken `.sheet(item:)` approach. FlightDetailView's `onDuplicate` now calls working `duplicateFlight()` directly. Added duplicate button to detail toolbar.

### H-4: `UIScreen.main.scale` is deprecated — FIXED
**File**: `SignatureCaptureView.swift`
**Resolution**: Replaced with `UITraitCollection.current.displayScale`.

### H-5: `DispatchQueue.main.asyncAfter` for delayed UI state changes — FIXED
**File**: `DashboardView.swift`, `LogbookListView.swift`, `ExportView.swift`, `ProgressView.swift`
**Resolution**: All 4 sites replaced with `.task(id:)` structured concurrency pattern.

### H-6: Missing `@MainActor` on `OnboardingManager` — FIXED
**File**: `OnboardingProfile.swift`
**Resolution**: Added `@MainActor` annotation.

### H-7: Hardcoded `.frame(width: 80)` clips on Dynamic Type — FIXED
**File**: `AddFlightView.swift` (lines 419, 429, 453, 466)
**Impact**: 4 TextFields used fixed `.frame(width: 80)` which clips content at larger Dynamic Type sizes.
**Resolution**: Replaced with `.frame(minWidth: 60, idealWidth: 80, maxWidth: 100)` for flexible sizing.

### H-8: Silent notification dispatch failure — FIXED
**File**: `NotificationService.swift` (line 383)
**Impact**: `try? await center.add(request)` silently swallowed errors. If dispatch failed, `recordDelivery` still ran, corrupting rate-limit state.
**Resolution**: `dispatch()` now returns `Bool`. Call site guards on success before calling `recordDelivery`. Failures are logged via `print()`.

### H-9: Missing accessibility labels on FlightRow and CategoryBadge — FIXED
**File**: `LogbookListView.swift` (lines 316, 370)
**Impact**: VoiceOver read raw layout structure instead of meaningful content.
**Resolution**: Added `.accessibilityElement(children: .combine)` and `.accessibilityLabel` to FlightRow. Added `.accessibilityLabel(tag)` to CategoryBadge.

---

## Medium (Tech Debt)

### M-1: `LogbookListView.swift` is 563 lines — God File — OPEN
**File**: `LogbookListView.swift`
**Impact**: Maintainability; contains 7 distinct view types in a single file. `FlightDetailView`, `FlightRow`, `CategoryBadge`, `DetailItem`, `SummaryPill`, `SavedToastView` all inline.

### M-2: `DashboardFocus` enum is defined but never read — FIXED
**File**: `OnboardingProfile.swift`
**Resolution**: Removed `DashboardFocus` enum and `TrainingStage.primaryDashboardFocus` computed property. Confirmed zero consumers — `PersonalizedEmptyDashboard` uses hardcoded per-stage arrays.

### M-3: Missing `OnboardingManager` environment in Previews — FIXED
**File**: `PPLProgressView.swift`, `LogbookListView.swift`
**Resolution**: Added `.environment(OnboardingManager())` to `#Preview` blocks.

### M-4: `recentRoutes` ForEach uses `\.from` as id — collisions — FIXED
**File**: `AddFlightView.swift`
**Resolution**: Changed to use full route string as identifier.

### M-5: No test infrastructure — FIXED
**Resolution**: Added 5 test suites (~115 tests) using Swift Testing framework: `CSVExporterTests`, `CurrencyManagerTests`, `ProgressTrackerTests`, `NotificationServiceTests`, `OnboardingManagerTests`.

### M-6: `CoachMarkStep.body` property name shadows View protocol — FIXED
**File**: `OnboardingProfile.swift` (line 147)
**Impact**: `body` on any type in a SwiftUI codebase causes autocomplete confusion.
**Resolution**: Renamed to `CoachMarkStep.message`. Updated 2 call sites in `CoachMarkOverlay.swift`.

### M-7: Hardcoded frame sizes don't scale with Dynamic Type — OPEN
**File**: `SignatureCaptureView.swift` (`.frame(height: 120)`), `ExportView.swift` (`.frame(maxHeight: 200)`)
**Impact**: At XXL or AX Dynamic Type sizes, fixed containers may clip content. Note: AddFlightView TextFields (H-7) are now fixed.

### M-8: `UINotificationFeedbackGenerator` instantiated inline per trigger — FIXED
**File**: 11+ call sites across codebase
**Resolution**: Centralized via `HapticService` enum in `AppTheme.swift` with pre-allocated generators.

### M-9: Last remaining `DispatchQueue.main.asyncAfter` in celebration reset — FIXED
**File**: `ProgressView.swift` (line 190)
**Impact**: Un-cancellable timer for celebration animation reset.
**Resolution**: Replaced with `.task(id: celebrating)` structured concurrency. All `DispatchQueue.main.asyncAfter` calls now eliminated from codebase.

### M-10: `SignatureCaptureView` has no `#Preview` macro — FIXED
**File**: `SignatureCaptureView.swift`
**Resolution**: Added `#Preview` with `@Previewable @State` bindings for `signatureData` and `cfiNumber`.
