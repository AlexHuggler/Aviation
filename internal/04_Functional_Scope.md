# SoloTrack - Functional Scope

A code-aligned map of screens, extension surfaces, interactions, validation rules, and data flows implemented in SoloTrack as of April 18, 2026.

---

## 1. Screen and Surface Map

### 1.1 App Root (`SoloTrackApp`)

The app bootstraps five runtime resources before presenting UI:

| Resource | Type | Scope |
|----------|------|-------|
| `ModelContainer` | SwiftData container for `FlightLog` + `FlightTemplate` | App-wide |
| `OnboardingManager` | `@Observable` class | Environment |
| `SyncSettings` | `@Observable` class | Environment |
| `FlightSessionController` | `@Observable` class | Environment |
| `NotificationCoordinator` | View modifier | Root lifecycle integration |

Launch-time behavior includes:

- optional persistent-state reset
- optional seeded smoke data
- optional seeded active timer session
- migration of the older default store into the App Group container
- dynamic choice between local-only and CloudKit-backed model configuration

Root app behavior also includes `onOpenURL` deep-link handling for:

- `solotrack://add-flight`
- `solotrack://dashboard`

### 1.2 ContentView

`ContentView` now has two root layouts:

| Device Class | Layout |
|--------------|--------|
| **iPhone / compact width** | `TabView` |
| **iPad / regular width** | `NavigationSplitView` |

Phone tab model:

| Tab | Tag | View |
|-----|-----|------|
| Dashboard | `0` | `DashboardView` |
| Progress | `1` | `PPLProgressView` |
| Logbook | `2` | `LogbookListView` |

iPad sidebar model:

| Section | View |
|---------|------|
| Dashboard | `DashboardView` |
| Progress | `PPLProgressView` |
| Logbook | `LogbookListView` |

Root-level modal/overlay behaviors:

- presents `OnboardingView` if onboarding has not completed
- can immediately present `AddFlightView` after onboarding dismissal
- presents `KeyboardShortcutsView`
- overlays `CoachMarkOverlay` when `currentCoachStep != nil`
- consumes pending timer prefills on launch/foreground
- responds to deep-link notifications triggered by widgets or intents

Keyboard shortcuts:

- `Cmd-1`, `Cmd-2`, `Cmd-3` switch tabs or sidebar sections
- `Cmd-/` opens the shortcuts reference sheet

### 1.3 DashboardView

Dashboard has three high-level states:

| State | Result |
|-------|--------|
| No flights + onboarding incomplete | generic empty state |
| No flights + onboarding complete | personalized empty dashboard plus timer section |
| Flights exist | populated dashboard plus timer section |

Toolbar actions:

- leading gear button opens `SettingsView`
- trailing plus button opens `AddFlightView` when flights exist

Populated dashboard sections:

1. legal-to-fly header
2. flight session section
3. passenger currency section (day + night)
4. additional currency section (instrument + flight review)
5. quick stats
6. next-milestone recommendation card

Supporting interactions:

- pull-to-refresh affordance
- add-flight launch with optional recommendation defaults
- save toast overlay after successful logging
- start/stop timer directly from Dashboard
- stop-to-prefill handoff into Add Flight when the timer is stopped in-app

### 1.4 PPLProgressView

States:

| State | Result |
|-------|--------|
| No flights | actionable empty state |
| Flights exist | progress ring + requirement list + checklist |

Sections:

1. overall progress card
2. requirement rows for the six main FAR 61.109 buckets
3. detailed checklist rows for more specific experience requirements

When all six primary requirements become met, the overall card celebrates visually and haptically.

### 1.5 LogbookListView

Primary responsibilities:

- list historical flights
- support search and filters
- open detail, edit, import, export, and add-flight flows

Toolbar actions:

| Placement | Action |
|-----------|--------|
| leading | Import |
| leading | Export |
| trailing | Add Flight |

Modal flows:

- `AddFlightView`
- `ExportView`
- `ImportView`
- edit-mode `AddFlightView` bound to a selected flight

List behavior:

- grouped by month
- searchable by route, date, category, remarks, and CFI number
- filter chips above grouped sections
- swipe actions for edit, duplicate, and delete
- locked flights cannot be deleted until the signature is voided
- delete supports undo toast

### 1.6 AddFlightView

`AddFlightView` supports two modes:

| Mode | Trigger |
|------|---------|
| Create | new-flight entry points, deep-link entry, timer-prefill entry |
| Edit | from logbook/detail when flight is editable |

Top-level form layout:

1. Date & Route
2. Duration
3. Landings
4. Categories
5. `More Details` disclosure group

Modal/alert support inside the form:

- discard confirmation alert
- save custom airport alert
- save-as-template sheet

Toolbar actions:

- Cancel
- Quick Entry toggle (create mode only)
- Save

### 1.7 FlightDetailView

Displays one flight with:

- route/date header
- times
- landings
- category badges
- training details when present
- signature disclosure
- remarks disclosure

Toolbar actions:

- Duplicate
- Edit (unlocked flights only)

### 1.8 SettingsView

Settings contains two sections:

| Section | Purpose |
|---------|---------|
| Student Journey | pick training stage and optionally accept a suggested stage |
| Backup & Sync | toggle iCloud sync and explain current status |

The sync section explicitly communicates whether:

- local-only storage is active
- iCloud sync is active
- a relaunch is required to apply a desired mode change

### 1.9 ImportView

Import supports:

- preset selection
- CSV file picking
- auto-detected format feedback
- preview summary
- row-by-row validation preview
- selective row import

The confirmation toolbar action remains disabled until there is at least one valid selected row.

### 1.10 ExportView

Export supports two formats:

| Format | Output |
|--------|--------|
| CSV | raw data export and clipboard/share flow |
| PDF | printable logbook document written to a temporary file |

Common controls:

- format picker
- optional date-range toggle
- start/end date pickers when date filtering is on

Preview area changes by format:

- CSV: scrollable text preview
- PDF: summary and first rows preview

### 1.11 Supporting Components

- `CoachMarkOverlay`
- `PersonalizedEmptyDashboard`
- `SignatureCaptureView`
- `ToastView`
- `KeyboardShortcutsView`

### 1.12 Widget and Automation Surfaces

Current shipped extension surfaces:

- `CurrencyWidget`
- `PPLProgressWidget`
- `LastFlightWidget`
- `SoloTrackWidgetsControl`
- `SoloTrackWidgetsLiveActivity`
- App Intents for quick logging, status checks, deep-link open-add-flight, and timer control

---

## 2. Data and State Flows

### 2.1 Persistence Scope

SwiftData persists:

- `FlightLog`
- `FlightTemplate`

Shared App Group storage persists:

- the shared SwiftData store used by extensions
- timer state and pending timer-prefill state
- shared defaults used by extension surfaces

Local `UserDefaults`-backed behavior persists:

- onboarding state
- selected training stage
- desired sync mode
- notification memory / cooldown state
- custom airports

### 2.2 App Group and Shared Store Flow

1. On launch, `DataMigrator` checks whether an older default store needs to be copied into the App Group container.
2. `AppGroup.storeURL` provides the shared production store location when the entitlement is available.
3. The main app builds its production `ModelContainer` from that App Group store location when available.
4. Widget and App Intent surfaces read from the same App Group store through `SharedModelContainer`.
5. `SharedModelContainer` keeps CloudKit disabled in extension contexts to avoid extension-side sync conflicts.

### 2.3 Sync Mode Flow

1. User toggles iCloud Sync in Settings.
2. `SyncSettings.desiredMode` updates immediately.
3. Status text changes to a restart-required state if desired mode differs from active mode.
4. On next launch, `AppLaunchConfiguration` chooses a CloudKit-enabled or local-only `ModelConfiguration`.

Important current boundary:

- flights and templates are in sync scope
- onboarding state, notification memory, custom airports, and timer state are not

### 2.4 Onboarding Flow

1. `ContentView` checks `hasCompletedOnboarding`.
2. If false, it presents `OnboardingView`.
3. Completing onboarding:
   - stores stage + intent
   - dismisses the sheet
   - either starts the coach mark tour or requests the add-flight flow
4. Post-dismiss handler can open `AddFlightView` immediately.

### 2.5 Flight Session Flow

1. A user starts a session from Dashboard, the control widget, or a Shortcut.
2. `FlightSessionStore` creates a single active session if one does not already exist.
3. The session is mirrored into the main app UI and, on supported devices, into the Live Activity.
4. When the session stops:
   - in-app stop opens Add Flight immediately with a session prefill
   - Shortcut/control-widget stop stores a pending prefill in shared state
5. On next foreground or launch, `ContentView` consumes the pending prefill once and opens Add Flight.

### 2.6 Deep-Link and Re-entry Flow

`SoloTrackDeepLink` currently supports two destinations:

- `solotrack://add-flight`
- `solotrack://dashboard`

Deep links are used by:

- `OpenAddFlightIntent`
- widgets
- the Live Activity
- internal app re-entry surfaces

### 2.7 Notification Evaluation Flow

`NotificationCoordinator` attaches at the root and runs in two situations:

1. when flight count increases
2. when the scene becomes active and onboarding is complete

Evaluation pipeline:

1. `NotificationEvaluator.detectEvents(...)`
2. `NotificationService.evaluate(...)`
3. scoring, cooldown, and preference filtering
4. dispatch through `UNUserNotificationCenter`

---

## 3. Add Flight Functional Scope

### 3.1 Initialization Rules

When creating a new flight, the form may derive defaults from:

- current training stage
- most recent flight
- dashboard recommendation
- selected template
- session prefill handed off from the flight-session timer

When editing a flight, the form is populated from the existing record and the flight is treated as dirty by default because it represents a mutable persisted item.

### 3.2 Date and Route

Date/route behavior:

- date cannot exceed today
- route fields uppercase user input
- route swap button reverses origin/destination
- recent route chips allow one-tap reuse
- focused route field can show ICAO suggestions
- unknown four-letter codes can trigger a save-to-custom-airports prompt

### 3.3 Duration Entry

Supported modes:

- direct Hobbs text entry
- Hobbs start/end calculator mode
- Tach entry
- session-prefill insertion of Hobbs and Tach after a timer stop

Validation rules:

- Hobbs must parse to a value strictly greater than zero (hard blocker; `Save` disabled)
- unparseable or zero Hobbs shows an inline error in red ("Enter a valid Hobbs time")
- Hobbs strictly greater than 12 hours surfaces a soft caution-yellow warning ("Hobbs exceeds 12 hours — verify before saving") but does not block save
- in calculator mode, `hobbsEnd` must be strictly greater than `hobbsStart` for the computed duration to be valid
- Tach auto-fills from Hobbs when Tach is empty and direct-entry mode is active

### 3.4 Landing and Category Rules

- At least one landing is required to save (day + night together must be ≥ 1)
- Day landings default to 1 on new flights; night full-stop defaults to 0
- Day and night full-stop landings are stored separately
- Each landing counter is capped at 99 via the +/- stepper buttons
- Solo and Dual Received are mutually exclusive toggles (enabling one auto-disables the other)
- Defaults for Solo/Dual are training-stage dependent

### 3.5 Advanced Details

The `More Details` disclosure contains:

- endorsement templates
- training detail toggles and numeric fields
- remarks
- signature capture

Advanced training details currently include:

- instrument approaches (stepper, 0–12)
- holding procedures
- intercept / course tracking
- towered airport operations
- checkride prep flight
- cross-country distance (shown only when XC is on)
- longest leg (shown only when XC is on)
- full-stop airports count (stepper, 0–10, shown only when XC is on)

The Flight Review toggle lives in the Categories section, not in advanced training details.

### 3.6 Signature Rules

- CFI number is captured separately from the signature drawing
- signed flights are locked on save
- locked flights cannot be edited from standard flows
- signature can later be voided from detail view to unlock the flight

### 3.7 Quick Entry Rules

Quick Entry applies only to new-flight mode:

- form stays open after save
- save feedback changes to session-style quick-entry toast
- count and total Hobbs for the session are tracked
- the form is reset for the next entry

### 3.8 Template Rules

- templates are shown only in create mode
- applying a template updates the route, toggles, typical Hobbs, landings, remarks, and CFI number
- users can save the current form as a new template
- users can delete existing templates from the picker UI

### 3.9 Save and Dismiss Rules

- `Save` is disabled until hard validation passes
- `Cmd-S` is wired to save
- Cancel checks dirty state and may show discard confirmation
- save success triggers the optional `onSave` callback supplied by the presenting view

---

## 4. Logbook and Detail Scope

### 4.1 Search and Filters

Search matches:

- route origin/destination
- formatted route
- category tags
- remarks
- CFI number
- abbreviated and long date formats

Filter chips:

- Solo
- Dual
- Cross-Country
- Instrument
- Night
- This Month
- Last 90 Days

### 4.2 Duplicate Flow

Duplicate can be launched from:

- swipe action in Logbook
- detail toolbar button

It creates a new editable flight based on the source record rather than mutating the original.

### 4.3 Delete Flow

1. User invokes delete on a row.
2. If the flight is signature locked, deletion is blocked and an alert explains the constraint.
3. Otherwise the flight is deleted.
4. Undo toast appears for a limited time.

### 4.4 Flight Detail Rules

Detail view progressively reveals:

- signature block when a valid signature exists
- remarks block when remarks exist
- training details only when advanced fields are populated

If the signature is voided:

- signature data and CFI number are cleared
- signature date is cleared
- `isSignatureLocked` becomes `false`
- widget timelines are refreshed

---

## 5. Progress, Currency, and Recommendation Scope

### 5.1 Currency Coverage

Dashboard and widgets currently expose four recency surfaces:

- Day currency
- Night currency
- Instrument currency
- Flight review currency

State model (`CurrencyState`):

- `valid(daysRemaining:)` when more than 30 days remain
- `caution(daysRemaining:)` when 0–30 days remain
- `expired(daysSince:)` once the rolling 90-day window (day/night) or the trailing 6 calendar months (instrument) has lapsed

Day and night currency use a 3-landings-in-90-days rolling window (FAR 61.57(a) and 61.57(b)); instrument currency requires 6 approaches plus holding and course tracking in the trailing 6 calendar months (FAR 61.57(c)); flight review currency uses a 24-calendar-month window from the most recent flight-review entry (FAR 61.56).

### 5.2 PPL Progress Coverage

Primary requirements computed today (`ProgressTracker.computeRequirements`):

1. Total Flight Time — 40 hours (FAR 61.109(a))
2. Dual Instruction — 20 hours (FAR 61.109(a)(1))
3. Solo Flight — 10 hours (FAR 61.109(a)(2))
4. Solo Cross-Country — 5 hours (FAR 61.109(a)(2)(i))
5. Night Training — 3 hours (FAR 61.109(a)(2)(ii))
6. Instrument Training — 3 hours (FAR 61.109(a)(3))

Checklist coverage extends to specific regulatory-style sub-requirements:

- 3 hours dual night training (61.109(a)(2)(ii))
- one night dual XC ≥ 100 NM total (61.109(a)(2)(ii))
- 10 night takeoffs and landings at a towered airport (61.109(a)(2)(ii))
- 3 hours of dual instrument instruction (61.109(a)(3))
- 3 hours of checkride prep within the preceding 2 calendar months (61.109(a)(4))
- solo long XC: 150 NM total, 3 airports, one leg over 50 NM (61.109(a)(5))
- 3 solo takeoffs and landings at a towered airport (61.109(a)(5))

### 5.3 Recommendation Logic

Dashboard recommendation logic chooses the nearest unmet primary requirement and can suggest a likely next flight profile to accelerate progress.

---

## 6. Import, Export, Widgets, and App Intents

### 6.1 Import Rules

Import accepts text/CSV files and:

- parses the header row
- auto-detects or respects the selected preset
- maps fields into SoloTrack’s expanded schema
- computes warnings and hard errors
- compares rows against existing-flight duplicate keys
- allows users to exclude individual valid rows before import

Supported presets (`ImportPreset`):

- Auto Detect (scores headers against every other preset)
- SoloTrack CSV
- ForeFlight-style CSV
- LogTen-style CSV
- MyFlightBook-style CSV
- Generic CSV

Row severities:

- hard error (excludes the row from import): missing/unparseable date, or Hobbs not parseable as > 0
- warning (row still importable): no landings parsed, or row matches an existing flight by duplicate key (defaults `shouldImport` to `false` for duplicates)

Duplicate detection key combines:

- flight date (ISO yyyy-MM-dd)
- uppercased route from
- uppercased route to
- Hobbs duration formatted to one decimal

### 6.2 Export Rules

CSV export currently includes the expanded flight schema. PDF export supports date filtering, totals, notes, signatures, and printable pagination.

### 6.3 Widget Rules

These surfaces ship together in `SoloTrackWidgetBundle` and read current logbook state through `SharedModelContainer`.

`CurrencyWidget`:

- shows currency states
- links back to Dashboard
- refreshes on a timeline cadence

`PPLProgressWidget`:

- shows overall PPL progress
- shows next milestone when available
- links back to Dashboard

`LastFlightWidget`:

- shows the most recent flight
- links directly to Add Flight

`SoloTrackWidgetsControl`:

- starts or stops the single active flight-session timer
- stores a pending prefill when it stops the timer

`SoloTrackWidgetsLiveActivity`:

- mirrors the active timer state
- returns users to Dashboard when tapped

### 6.4 App Intent Rules

Current shipped intents are registered through `SoloTrackShortcutsProvider`:

- `LogQuickFlightIntent` logs a flight directly into the shared store
- `CheckCurrencyIntent` returns current recency status
- `NextMilestoneIntent` returns the next PPL milestone summary
- `OpenAddFlightIntent` routes into Add Flight via `SoloTrackDeepLink`
- `StartFlightSessionIntent` starts the single active timer without foregrounding the app
- `StopFlightSessionIntent` stops the timer and stores a pending prefill for next app re-entry

---

## 7. Notification Scope

The notification system is intentionally narrow and event-driven.

Currently supported event classes:

- currency cliff (day or night only; instrument and flight-review currency do not emit cliff notifications)
- milestone crossed
- checkride ready
- momentum stall

Value scoring (`NotificationService`):

- send threshold is `0.5`
- currency cliff scores `0.95` at ≤3 days, `0.85` at ≤7 days, `0.6` under 30 days
- milestone crossed scores `0.75`, boosted by `0.1` for checkride-prep students
- checkride ready scores `1.0`
- momentum stall scores `0.55` (`0.75` for checkride-prep), plus `0.1` when days since last flight ≥ 30

Rate limits:

- daily cap of `2` notifications per calendar day
- global cooldown of `4 hours` between any two notifications
- per-category cooldowns: currency cliff `7 days`, milestone crossed `24 hours`, momentum stall `14 days`, checkride ready once ever
- milestones are deduped by FAR reference in `acknowledgedMilestones`
- checkride ready is gated by `hasNotifiedCheckrideReady`

Current constraints:

- `NotificationPreferences` stores opt-in flags for currency, milestone, and momentum alerts, but no settings screen currently exposes them
- no generic scheduled reminder system
- no user-authored recurring alert rules

---

## 8. Keyboard, Motion, Accessibility, and Automation

### 8.1 Keyboard Support

- tab and sidebar switching from the root view
- logbook actions for import/export/new
- save shortcut in Add Flight
- shortcuts help sheet

### 8.2 Motion and Feedback

- motion-aware animations respect reduced-motion patterns
- save, warning, error, milestone, and selection feedback use shared haptic helpers

### 8.3 Accessibility and Automation

- explicit identifiers on important controls for UI tests
- combined accessibility labels on progress and checklist rows
- scaled design tokens for Dynamic Type behavior
- widget and timer surfaces refresh after important data changes

---

## 9. Out-of-Scope or Not Yet Exposed

These are not current product surfaces:

- no user-facing notification preferences screen
- no instructor multi-user dashboard
- no external flight-service integrations
- no app-owned account system
- no multi-session timer model
