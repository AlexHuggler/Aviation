# SoloTrack — Functional Scope

A complete mapping of every screen, interaction, data flow, and validation rule implemented in SoloTrack.

---

## 1. Screen Map

### 1.1 App Root (`SoloTrackApp`)

The entry point creates two shared resources and injects them into the SwiftUI hierarchy:

| Resource | Type | Scope |
|----------|------|-------|
| `OnboardingManager` | `@Observable` class | Environment object, app-wide |
| `ModelContainer(for: FlightLog.self)` | SwiftData container | Implicit environment, app-wide |

Root view: `ContentView`

### 1.2 ContentView — Tab Navigation

A `TabView` with three tabs, wrapped in a `ZStack` that conditionally overlays the coach mark tour.

| Tab | Index | View | System Image | Label |
|-----|-------|------|-------------|-------|
| Dashboard | 0 | `DashboardView` | `gauge.with.dots.needle.33percent` | Dashboard |
| Progress | 1 | `PPLProgressView` | `chart.bar.fill` | Progress |
| Logbook | 2 | `LogbookListView` | `book.closed.fill` | Logbook |

**Overlay**: `CoachMarkOverlay` (z-index 100) appears when `onboarding.currentCoachStep != nil`.

**Sheet**: `OnboardingView` presented on appear when `!onboarding.hasCompletedOnboarding`.

**Tab auto-switching**: When the coach mark tour is active, tab selection is driven by `CoachMarkStep.associatedTab`, animated with a motion-aware spring.

### 1.3 DashboardView (Tab 0)

**Purpose**: At-a-glance flight status — currency compliance, quick stats, and progress nudge.

**Data sources**: `@Query` on `FlightLog` (reverse chronological), `CurrencyManager`, `ProgressTracker`, `OnboardingManager`.

| State | Layout |
|-------|--------|
| No flights + onboarded | `PersonalizedEmptyDashboard` (persona-specific) |
| No flights + not onboarded | Generic empty state with feature list |
| Has flights | Full dashboard with 4 sections |

**Populated sections**:

1. **"LEGAL TO FLY?" header** — Airplane icon + status text. Green airplane for current, red airplane.slash for not current. Animated on state change.
2. **"PASSENGER CURRENCY" cards** — Two side-by-side `CurrencyCard` components (Day / Night). Each shows icon, title, state icon (checkmark/warning/X), relative label, and absolute expiration date.
3. **Quick Stats** — 3-column grid: Total Hours, Total Flights, PPL Reqs Met (X/6).
4. **Progress Nudge** — Shows the closest unmet PPL requirement with remaining hours, percentage, and target icon.

**Toolbar**: Navigation title "SoloTrack". Plus button opens `AddFlightView` sheet (visible only when flights exist).

**Auto-open**: If `onboarding.shouldOpenAddFlight` is true, opens `AddFlightView` after a 0.5-second delay.

### 1.4 PPLProgressView (Tab 1)

**Purpose**: FAR 61.109 aeronautical experience tracking with visual progress indicators.

**Data sources**: `@Query` on `FlightLog`, `ProgressTracker`.

| State | Layout |
|-------|--------|
| No flights | `ContentUnavailableView` — "No Progress Yet" with "Log Your First Flight" action button |
| Has flights | Progress ring + 6 requirement rows |

**Populated sections**:

1. **Overall Progress Ring** — 160pt circular indicator with animated fill. Center shows percentage and "X of 6 met". Animates over 0.8s with easeInOut.
2. **Requirements List** — 6 `RequirementRow` components, one per FAR 61.109 category. Each shows title, FAR reference, progress bar with milestone ticks (25/50/75%), percentage or green checkmark (with bounce), and remaining hours text.

**Color coding**: Green (met), Sky Blue (≥50%), Yellow (<50%).

**Toolbar**: Plus button opens `AddFlightView` sheet.

### 1.5 LogbookListView (Tab 2)

**Purpose**: Chronological flight record with search, export, edit, duplicate, and delete.

**Data sources**: `@Query` on `FlightLog` (reverse chronological), `ModelContext`.

| State | Layout |
|-------|--------|
| No flights | `ContentUnavailableView` — "No Flights Logged" with "Add Flight" action button |
| Has flights | Summary header + grouped flight list |

**Populated sections**:

1. **Logbook Summary** — 3 `SummaryPill` components: Total Hours, Total Flights, This Month hours.
2. **Grouped Flight List** — Flights grouped by month ("MMMM yyyy" headers), reverse chronological. Each `FlightRow` shows date circle, formatted route, category badges, duration, and signature/lock icons.

**Search**: Filters flights by route (From/To), category tags, remarks, and CFI number.

**Toolbar**: Export button (left, disabled when empty), Plus button (right).

### 1.6 AddFlightView (Modal Sheet)

**Purpose**: Create or edit a flight log entry with smart defaults and validation.

**Initialization modes**:
- **New flight**: `editingFlight = nil`. Smart defaults from most recent flight or persona.
- **Edit flight**: `editingFlight` populated. All fields pre-filled from existing entry.

**Form sections**:

1. **Date & Route** — DatePicker (max: today), recent route quick-picks (up to 5), From/To ICAO fields with 4-character checkmark indicator, animated swap button.
2. **Duration** — Toggle between direct entry (Hobbs/Tach fields) and calculator mode (Hobbs Start/End with live computation). Tach always visible.
3. **Landings** — Day landings stepper (0–99, default 1), Night full-stop stepper (0–99, default 0). Sensory feedback on change.
4. **Categories** — Solo/Dual (mutually exclusive toggles), Cross-Country, Simulated Instrument.
5. **More Details** (disclosure group) — Remarks text field (3–6 lines), `SignatureCaptureView` for CFI endorsement.

**Keyboard**: Focus state tracking with Previous/Next/Done toolbar buttons.

### 1.7 FlightDetailView (Push Navigation)

**Purpose**: Read-only display of a single flight's complete data.

**Accessed from**: Tapping a `FlightRow` in LogbookListView.

**Sections**: Route, dates, duration (Hobbs + Tach), landings, categories, CFI endorsement (signature image + CFI number + date), remarks.

**Actions**:
- **Edit** (toolbar): Opens `AddFlightView` in edit mode. Disabled for signature-locked flights.
- **Void Signature**: Removes signature, unlocks flight. Requires confirmation alert.

### 1.8 OnboardingView (Modal Sheet)

**Purpose**: Two-step persona profiling for first-time users.

**Step 0 — Training Stage**: Welcome header with animated airplane icon. Three selectable cards: Pre-Solo, Post-Solo, Checkride Prep. Haptic feedback on selection.

**Step 1 — Getting Started Intent**: Header with selected stage icon. Three selectable cards: Log a Flight, Enter Past Flights, Explore the App.

**Navigation**: Progress dots (2), Continue button (disabled until selection). Spring animations between steps. Success haptic on completion.

### 1.9 ExportView (Modal Sheet)

**Purpose**: CSV preview, share, and copy interface.

**Layout**: Document icon + title, description text, scrollable CSV preview (monospaced, 200pt max), Share button (system ShareLink), Copy button (toggles to "Copied!" with green background, auto-reverts after 2s).

### 1.10 CoachMarkOverlay (Full-Screen Overlay)

**Purpose**: 6-step interactive tour introducing app features.

**Layout**: Dimmed backdrop (black 0.4 opacity), centered card (max 340pt) with step dots, icon (bounces on change), title, body text, Skip Tour / Next buttons.

**Steps**: Dashboard Welcome → Currency Cards → Progress Tab → Logbook Tab → Add Flight Button → Tour Complete.

**Interaction**: Tap backdrop or Next to advance. Skip Tour dismisses entirely. Final step shows "Start Logging" button.

### 1.11 PersonalizedEmptyDashboard (Component)

**Purpose**: Post-onboarding empty state tailored to training stage.

**Sections**: Stage-specific greeting + welcome message, stage badge, 3 feature highlights (stage-specific), CTA button (intent-specific label), contextual tip for backfill users.

### 1.12 SignatureCaptureView (Component)

**Purpose**: PencilKit-based CFI signature capture.

**Layout**: CFI number text field, PencilKit canvas (120pt, finger + pencil input), eraser button, capture button (disabled without CFI number). Confirmation state shows green checkmark + "Signature captured".

---

## 2. User Interactions

### 2.1 Navigation

| Interaction | Source | Target |
|------------|--------|--------|
| Tab selection | ContentView TabView | Dashboard / Progress / Logbook |
| Tap flight row | LogbookListView | FlightDetailView (push) |
| Plus button (toolbar) | Any tab | AddFlightView (sheet) |
| Export button | LogbookListView toolbar | ExportView (sheet) |
| "Log Your First Flight" | Empty state CTA | AddFlightView (sheet) |
| Back navigation | FlightDetailView | LogbookListView (pop) |
| Sheet dismiss | Any sheet | Parent view (drag or button) |

### 2.2 Gestures

| Gesture | View | Action |
|---------|------|--------|
| Swipe left on flight row | LogbookListView | Reveal Duplicate button |
| Swipe right on flight row | LogbookListView | Reveal Delete button |
| Long press on flight row | LogbookListView | Context menu with Duplicate option |
| Tap dimmed backdrop | CoachMarkOverlay | Advance to next tour step |
| Drag to dismiss sheet | AddFlightView | Blocked if form dirty; shows discard alert |
| Draw on canvas | SignatureCaptureView | Capture signature strokes |
| Tap route swap | AddFlightView | Swap From/To with rotation animation |
| Tap recent route pill | AddFlightView | Fill From/To from recent flight |

### 2.3 Form Inputs

| Input | Type | Validation |
|-------|------|------------|
| Date | DatePicker | Max: `.now` (no future dates) |
| Route From/To | TextField | Auto-uppercase, 4-char ICAO indicator |
| Hobbs duration | Decimal field | Must be > 0; warning if > 12 hours |
| Tach duration | Decimal field | Optional |
| Hobbs Start/End | Decimal fields | End must be > Start (implied) |
| Day landings | Stepper | 0–99, default 1 |
| Night landings | Stepper | 0–99, default 0 |
| Solo toggle | Toggle | Mutually exclusive with Dual |
| Dual toggle | Toggle | Mutually exclusive with Solo |
| Cross-Country toggle | Toggle | Independent |
| Instrument toggle | Toggle | Independent |
| Remarks | TextEditor | Free text, 3–6 lines |
| CFI number | TextField | Required before signature capture |
| Signature canvas | PKCanvasView | Free drawing, any input method |
| Search | TextField | Filters by route, category, remarks, CFI |

---

## 3. State Transitions

### 3.1 Onboarding State Machine

```
App Launch
  │
  ├── hasCompletedOnboarding == true
  │     └── Main App (Dashboard)
  │
  └── hasCompletedOnboarding == false
        └── OnboardingView (sheet)
              │
              Step 0: Select Training Stage
              │
              Step 1: Select Getting Started Intent
              │
              ├── intent == .logFresh or .backfill
              │     └── shouldOpenAddFlight = true
              │           └── Dashboard → auto-opens AddFlightView (0.5s delay)
              │
              └── intent == .explore
                    └── currentCoachStep = .dashboardWelcome
                          └── Coach Mark Tour (6 steps)
                                │
                                ├── User taps "Next" / backdrop → advanceTour()
                                ├── User taps "Skip Tour" → skipTour()
                                └── Final step → completeTour()
```

### 3.2 Flight Entry State Machine

```
AddFlightView Opens
  │
  ├── editingFlight != nil → Pre-fill from existing flight
  ├── recentFlights.count > 0 → Smart defaults from most recent
  └── No history → Persona defaults (Solo/Dual based on stage)
  │
  User fills form...
  │
  ├── Tap Cancel / Dismiss
  │     ├── isFormDirty == false → Dismiss immediately
  │     └── isFormDirty == true → "Discard Flight?" alert
  │           ├── Discard → Dismiss
  │           └── Keep Editing → Return to form
  │
  └── Tap Save
        │
        ├── Hobbs == 0 → Validation error (no save)
        ├── Hobbs > 12 → Duration warning alert (overridable)
        ├── Total landings == 0 → Validation error (no save)
        │
        └── Validation passes
              │
              ├── New flight → Insert into ModelContext
              └── Editing → Update existing FlightLog
              │
              ├── Has signature + CFI number → lockSignature()
              └── No signature → Flight remains editable
              │
              Success haptic → onSave callback → Dismiss
```

### 3.3 Signature Lifecycle

```
Flight Created (isSignatureLocked = false)
  │
  ├── User adds signature in AddFlightView
  │     ├── Enter CFI number
  │     ├── Draw on PencilKit canvas
  │     └── Tap "Capture Signature"
  │           └── signatureData = PNG bytes
  │
  └── Save with valid signature
        └── lockSignature(signatureData:cfi:)
              ├── instructorSignature = PNG data
              ├── cfiNumber = CFI certificate number
              ├── signatureDate = Date.now
              └── isSignatureLocked = true
                    │
                    ├── Flight row shows lock icon
                    ├── Edit button disabled in detail view
                    ├── Swipe-to-delete blocked (haptic error)
                    │
                    └── User taps "Void Signature" in detail view
                          └── Confirmation alert
                                ├── Void → voidSignature()
                                │     ├── instructorSignature = nil
                                │     ├── cfiNumber = ""
                                │     ├── signatureDate = nil
                                │     └── isSignatureLocked = false
                                └── Cancel → No change
```

### 3.4 Currency State Transitions

```
CurrencyManager.dayCurrency(flights:asOf:) / nightCurrency(flights:asOf:)
  │
  ├── Qualifying landings in 90-day window < 3
  │     └── .expired(daysSince: N)
  │           └── Red shield icon, "Expired X days ago"
  │
  └── Qualifying landings ≥ 3
        │
        Calculate expiration: oldest-qualifying-flight.date + 90 days
        │
        ├── Days remaining > 30
        │     └── .valid(daysRemaining: N)
        │           └── Green checkmark, "Current — N days remaining"
        │
        └── Days remaining ≤ 30
              └── .caution(daysRemaining: N)
                    └── Yellow warning, "Expiring in N days"
```

---

## 4. FAR Regulation Implementation

### 4.1 FAR 61.57 — Recent Flight Experience (Currency)

**Implementation**: `CurrencyManager` (stateless struct)

| Requirement | Code Method | Qualifying Criteria | Window |
|------------|-------------|-------------------|--------|
| Day passenger currency | `dayCurrency(flights:asOf:)` | 3 takeoffs and landings (day) | Rolling 90 days |
| Night passenger currency | `nightCurrency(flights:asOf:)` | 3 full-stop night landings | Rolling 90 days |

**Algorithm**:
1. Filter flights within the 90-day lookback window from the reference date.
2. Sum qualifying landings (`landingsDay` for day, `landingsNightFullStop` for night).
3. If total < 3: return `.expired` with days since the last would-have-been expiration.
4. If total ≥ 3: find the oldest flight contributing to the required 3 landings. Expiration = that flight's date + 90 days.
5. If days remaining > 30: `.valid`. If ≤ 30: `.caution`. If ≤ 0: `.expired`.

**Caution threshold**: 30 days (configurable as `cautionThreshold` constant).

**Known gap**: Does not implement FAR 61.57(c) instrument currency or FAR 61.56 flight review.

### 4.2 FAR 61.109 — Aeronautical Experience (PPL Requirements)

**Implementation**: `ProgressTracker` (stateless struct)

| # | Requirement | FAR Reference | Goal | Logged From |
|---|------------|---------------|------|-------------|
| 1 | Total Flight Time | 61.109(a) | 40 hours | Sum of all `durationHobbs` |
| 2 | Dual Instruction | 61.109(a)(1) | 20 hours | Sum where `isDualReceived == true` |
| 3 | Solo Flight | 61.109(a)(2) | 10 hours | Sum where `isSolo == true` |
| 4 | Solo Cross-Country | 61.109(a)(2)(i) | 5 hours | Sum where `isSolo && isCrossCountry` |
| 5 | Night Training | 61.109(a)(2)(ii) | 3 hours | Sum where `landingsNightFullStop > 0` |
| 6 | Instrument Training | 61.109(a)(3) | 3 hours | Sum where `isSimulatedInstrument == true` |

**Output**: Array of `PPLRequirement` structs with computed progress, percentage, remaining hours, and met/unmet status.

**Known gap**: Does not track specific sub-requirements within each category (e.g., the specific 3-hour night dual cross-country flight, or the 150nm solo cross-country with full-stop landings at 3 airports).

---

## 5. Validation Rules

### 5.1 Flight Save Validation

| Rule | Condition | Behavior |
|------|-----------|----------|
| Hobbs required | `durationHobbs <= 0` | Save blocked, validation error |
| Duration warning | `durationHobbs > 12` | Alert shown; user can override |
| Landing required | `landingsDay + landingsNightFullStop == 0` | Save blocked, validation error |
| Solo/Dual exclusion | Both toggled on | Mutually exclusive — toggling one disables the other |
| Signature requires CFI | Signature captured without CFI number | Capture button disabled |
| Future date blocked | Date > today | DatePicker max set to `.now` |

### 5.2 Delete Validation

| Rule | Condition | Behavior |
|------|-----------|----------|
| Locked signature | `isSignatureLocked == true` | Delete blocked, haptic error, alert shown |
| Unlocked flight | `isSignatureLocked == false` | Delete proceeds via swipe action |

### 5.3 Edit Validation

| Rule | Condition | Behavior |
|------|-----------|----------|
| Locked signature | `isSignatureLocked == true` | Edit button disabled in detail view |
| Unlocked flight | `isSignatureLocked == false` | Edit button enabled, opens AddFlightView |

### 5.4 Form Dirty Detection

The `isFormDirty` computed property compares every current field value against the initial state captured at form open. Used to gate the discard confirmation alert and `interactiveDismissDisabled`.

**Known issue (C-2)**: When persona defaults pre-set Solo/Dual toggles, `isFormDirty` may return true on a pristine form because the initial state captures the pre-toggle values.

---

## 6. Data Export Specification

### 6.1 CSV Format

**Generator**: `CSVExporter.generateCSV(from:)` (static method)

**Columns** (13 total):

```
Date,From,To,Hobbs,Tach,Day Landings,Night FS Landings,Solo,Dual,XC,Instrument,CFI Number,Remarks
```

| Column | Format | Example |
|--------|--------|---------|
| Date | `yyyy-MM-dd` | `2025-01-15` |
| From | String | `KSJC` |
| To | String | `KRHV` |
| Hobbs | Decimal (1 place) | `1.5` |
| Tach | Decimal (1 place) | `1.3` |
| Day Landings | Integer | `3` |
| Night FS Landings | Integer | `1` |
| Solo | `Y` / `N` | `Y` |
| Dual | `Y` / `N` | `N` |
| XC | `Y` / `N` | `Y` |
| Instrument | `Y` / `N` | `N` |
| CFI Number | String | `1234567` |
| Remarks | String (escaped) | `"Great flight, smooth air"` |

**Sort order**: Ascending by date (oldest first).

**Field escaping**: Fields containing commas, double quotes, or newlines are wrapped in double quotes. Internal double quotes are doubled (`""` escaping).

---

## 7. Haptic Feedback Map

| Event | Generator | Feedback Type |
|-------|-----------|--------------|
| Flight saved | `UINotificationFeedbackGenerator` | `.success` |
| Onboarding option selected | `UINotificationFeedbackGenerator` | `.success` |
| Onboarding completed | `UINotificationFeedbackGenerator` | `.success` |
| Signature captured | `UINotificationFeedbackGenerator` | `.success` |
| CSV copied to clipboard | `UINotificationFeedbackGenerator` | `.success` |
| Delete locked flight | `UINotificationFeedbackGenerator` | `.error` |
| Landing stepper change | `.sensoryFeedback` | `.selection` |
| Category toggle change | `.sensoryFeedback` | `.selection` |

---

## 8. Accessibility

| Feature | Implementation |
|---------|---------------|
| Reduced motion | `ReducedMotionAware` view modifier checks `accessibilityReduceMotion`; `.motionAwareAnimation()` conditionally disables animations |
| VoiceOver labels | Currency status header, progress ring, stat cards, and coach marks have explicit accessibility labels |
| Coach mark modal trait | `.accessibilityAddTraits(.isModal)` prevents VoiceOver from reading background content |
| Combined children | Coach mark card uses `.accessibilityElement(children: .combine)` for linear reading |
| Monospaced ICAO fields | Route fields use `.monospaced` font design for consistent character width |
| Color + icon redundancy | Currency states use both color and icon (checkmark/warning/X) — not color alone |
