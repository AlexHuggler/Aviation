# SoloTrack — Feature Inventory

A comprehensive inventory of every feature currently implemented in the SoloTrack codebase, organized by functional domain.

---

## 1. Onboarding & Personalization

- **Training stage selection** — User selects their current training phase: Pre-Solo, Post-Solo, or Checkride Prep (`OnboardingView.swift`, `TrainingStage` enum)
- **Getting-started intent** — User selects their immediate goal: Log a Flight, Enter Past Flights, or Explore the App (`GettingStartedIntent` enum)
- **Intent-based routing** — Log Fresh/Backfill intents auto-open the Add Flight form; Explore intent launches the coach mark tour (`OnboardingManager.completeOnboarding()`)
- **Interactive coach mark tour** — 6-step guided overlay (Dashboard Welcome → Currency Cards → Progress Tab → Logbook Tab → Add Flight Button → Tour Complete) with skip and advance controls (`CoachMarkOverlay.swift`, `CoachMarkStep` enum)
- **Tab auto-switching during tour** — Coach mark steps automatically switch the active tab to match the feature being highlighted (`CoachMarkStep.associatedTab`)
- **Personalized empty dashboard** — Training-stage-specific empty state with tailored feature highlights and motivational messaging (`PersonalizedEmptyDashboard.swift`)
- **Persona-driven form defaults** — Flight category toggles (Solo/Dual) pre-set based on training stage (`TrainingStage.defaultIsSolo`, `.defaultIsDualReceived`)
- **Stage-specific welcome messages** — Motivational text displayed after onboarding completion, tailored to training phase (`TrainingStage.welcomeMessage`)
- **Onboarding state persistence** — Completion status, tour status, stage, and intent persisted across app launches via UserDefaults (`OnboardingManager`)
- **Development reset** — Full onboarding state reset available for testing (`OnboardingManager.resetOnboarding()`)

---

## 2. Flight Logging

- **Add new flight** — Form-based entry accessible from toolbar "+" button on all three tabs (`AddFlightView.swift`)
- **Edit existing flight** — Re-opens AddFlightView pre-populated with the selected flight's data (available when flight is not signature-locked)
- **Date picker** — Calendar-style date selection, restricted to prevent future dates (`.now` maximum)
- **ICAO route entry** — From/To airport code fields with monospaced font, auto-uppercasing, and 4-character visual checkmark
- **Route swap button** — Animated button to swap From and To fields for return flights
- **Recent route quick-pick** — Buttons showing routes from recent flights for one-tap reuse (`AddFlightView` recent routes query)
- **Hobbs time entry** — Direct decimal input for Hobbs duration (e.g., 1.5 hours)
- **Tach time entry** — Direct decimal input for Tach duration
- **Hobbs calculator** — Toggle to switch between direct entry and Start/End time calculator for computing duration
- **Day landings stepper** — Increment/decrement control for day landing count with sensory feedback
- **Night full-stop landings stepper** — Increment/decrement control for night full-stop landing count
- **Flight category toggles** — Solo, Dual Received, Cross-Country, Simulated Instrument — multi-select booleans
- **Remarks field** — Free-text notes field in the expandable "More Details" disclosure group
- **Smart defaults from recent flights** — Route fields pre-populated from the most recent logged flight
- **Training-stage defaults** — Category toggles pre-set based on the user's training stage persona
- **Keyboard navigation toolbar** — Previous/Next/Done buttons for moving between form fields (`@FocusState` tracking)
- **Form dirty detection** — Tracks whether the user has modified any fields from their initial state (`isFormDirty` computed property)
- **Discard confirmation** — Alert prompting "Discard Flight?" when dismissing a modified form (`.interactiveDismissDisabled`)
- **Save validation** — Validates Hobbs > 0 and at least 1 landing before allowing save
- **Duration warning** — Alert for Hobbs > 12 hours (likely data entry error, overridable)
- **Success haptic** — Haptic feedback on successful save (`UINotificationFeedbackGenerator`)
- **Save toast notification** — Overlay confirmation "Flight saved" after successful save (`SavedToastView`)

---

## 3. CFI Signature & Endorsement

- **CFI number entry** — Text field for instructor certificate number (required before signature capture)
- **PencilKit signature canvas** — Full drawing surface for CFI signature capture via `PKCanvasView` (`SignatureCaptureView.swift`)
- **Signature undo** — Undo last stroke on the signature canvas
- **Signature clear** — Clear entire signature canvas
- **Signature locking** — On save with valid signature, flight becomes read-only (`FlightLog.lockSignature()`)
- **Signature date tracking** — Automatic timestamp when signature is captured
- **Signature display** — Rendered signature image in flight detail view (`UIImage(data:)`)
- **Void signature** — Explicit action to remove signature and unlock flight, with confirmation alert (`FlightLog.voidSignature()`)
- **Lock indicator** — Lock icon displayed on flight rows in the logbook when a flight is signature-locked
- **Signature icon** — Signature indicator icon on flight rows when a valid signature exists

---

## 4. Currency Compliance (FAR 61.57)

- **Day currency calculation** — Determines if pilot has 3 takeoffs and landings in the preceding 90 days (`CurrencyManager.dayCurrency()`)
- **Night currency calculation** — Determines if pilot has 3 full-stop night landings in the preceding 90 days (`CurrencyManager.nightCurrency()`)
- **90-day rolling window** — Currency expires based on the oldest of the 3 most recent qualifying landings, plus 90 days
- **Three-state display** — Currency shown as Valid (green), Caution (yellow, ≤30 days remaining), or Expired (red) (`CurrencyState` enum)
- **Days remaining countdown** — Shows exact days until currency expires
- **Days since expiration** — Shows how long ago currency expired
- **Absolute expiration date** — Shows the calendar date of expiration (e.g., "Mar 15") (`CurrencyState.absoluteDateLabel`)
- **"Legal to Fly?" header** — Dashboard header with airplane icon indicating overall currency status
- **Day currency card** — Dashboard card showing day currency state with icon, label, and color coding (`CurrencyCard`)
- **Night currency card** — Dashboard card showing night currency state with icon, label, and color coding
- **Currency state icons** — Checkmark shield (valid), exclamation triangle (caution), X shield (expired)

---

## 5. PPL Progress Tracking (FAR 61.109)

- **Six requirement categories tracked**:
  - Total Flight Time (40 hours) — FAR 61.109(a)
  - Dual Instruction (20 hours) — FAR 61.109(a)(1)
  - Solo Flight (10 hours) — FAR 61.109(a)(2)
  - Solo Cross-Country (5 hours) — FAR 61.109(a)(2)(i)
  - Night Training (3 hours) — FAR 61.109(a)(2)(ii)
  - Instrument Training (3 hours) — FAR 61.109(a)(3)
- **Overall progress ring** — Circular progress indicator showing aggregate completion percentage across all 6 requirements (`PPLProgressView.swift`)
- **Individual requirement rows** — Each requirement displayed with title, FAR reference, progress bar, and status
- **Progress bars with milestone ticks** — Visual progress bars with markers at 25%, 50%, and 75%
- **Color-coded progress** — Yellow (<50%), blue (50–99%), green (100% met)
- **Requirements met counter** — "X of 6 requirements met" summary
- **Remaining hours display** — "X.X hrs to go" for each unmet requirement
- **Progress nudge** — Dashboard section showing the next unmet requirement and hours remaining as a motivational prompt
- **Quick stats** — Dashboard display of total hours, total flights, and requirements met count (`StatCard`)
- **Empty state** — "No Progress Yet" with call-to-action to log first flight when no flights exist

---

## 6. Digital Logbook

- **Chronological flight list** — All flights displayed in reverse chronological order (`LogbookListView.swift`)
- **Month grouping** — Flights grouped by month with section headers
- **Flight row display** — Date circle, route, category badges, duration, signature/lock indicators (`FlightRow`)
- **Category badges** — Color-coded pills showing Solo, Dual, XC, Inst tags (`CategoryBadge`)
- **Search** — Searchable text field filtering flights by route (From/To), category tags, remarks, and CFI number
- **Flight detail view** — Full read-only display of all flight data including route, times, landings, categories, CFI endorsement, and remarks (`FlightDetailView`)
- **Edit flight** — Opens AddFlightView in edit mode for unlocked flights (toolbar button in detail view)
- **Swipe-to-duplicate** — Swipe action creates a new flight with the same data and today's date
- **Swipe-to-delete** — Swipe action deletes a flight (blocked with haptic error feedback for signature-locked flights)
- **Context menu duplicate** — Alternative duplicate discovery via long-press context menu
- **Logbook summary header** — Summary pills showing total hours, total flights, and this-month stats (`SummaryPill`)
- **Saved toast** — Overlay notification confirming successful edit save

---

## 7. Data Export

- **CSV generation** — Exports all flights as comma-separated values with 13 columns (`CSVExporter.swift`)
- **CSV preview** — Scrollable preview of the generated CSV text in the export sheet (`ExportView.swift`)
- **Share sheet** — System share sheet for sending CSV via AirDrop, email, Messages, etc. (`ShareLink`)
- **Copy to clipboard** — One-tap copy of CSV to clipboard with confirmation state change (`UIPasteboard`)
- **Export fields**: Date, From, To, Hobbs, Tach, Day Landings, Night FS Landings, Solo, Dual, XC, Instrument, CFI Number, Remarks
- **Chronological sort** — Exported flights sorted by date (oldest first)
- **CSV field escaping** — Proper handling of commas, quotes, and newlines in field values

---

## 8. Dashboard & Analytics

- **Three-tab navigation** — Dashboard, Progress, Logbook tabs in a TabView (`ContentView.swift`)
- **"Legal to Fly?" status header** — Airplane icon with current/not-current status based on combined day+night currency
- **Currency cards section** — Day and night currency status cards with traffic-light color coding
- **Quick stats section** — Total hours, total flights, and requirements met displayed as stat cards
- **Progress nudge section** — Shows the next unmet PPL requirement with remaining hours as a motivational prompt
- **Auto-open flight form** — Automatically presents AddFlightView after onboarding for Log Fresh/Backfill users
- **Empty state handling** — Personalized empty dashboard (post-onboarding) or generic empty state (fallback)

---

## 9. Design System & Accessibility

- **Token-based spacing** — Consistent spacing scale from 2pt to 24pt applied across all views (`AppTokens.Spacing`)
- **Token-based corner radii** — Consistent radius scale from 8pt to 16pt (`AppTokens.Radius`)
- **Token-based animations** — Consistent duration scale from 0.3s to 2.0s (`AppTokens.Duration`)
- **Token-based opacity** — Consistent opacity scale from 8% to 60% (`AppTokens.Opacity`)
- **Aviation color palette** — Sky Blue primary, currency traffic-light colors (green/yellow/red)
- **Card style modifier** — Reusable `.cardStyle()` with material background and rounded corners
- **Section header style** — Reusable `.sectionHeaderStyle()` with uppercase tracking
- **Reduced motion support** — `.motionAwareAnimation()` modifier respects system `accessibilityReduceMotion` setting
- **Haptic feedback** — `UINotificationFeedbackGenerator` and `.sensoryFeedback` for save, error, toggle, and selection events
- **VoiceOver labels** — Accessibility labels on key interactive elements
- **Monospaced ICAO fields** — Route fields use monospaced font design for airport code readability

---

## 10. Data Persistence

- **SwiftData local storage** — `FlightLog` persisted via SwiftData `@Model` with automatic schema management
- **UserDefaults preferences** — Onboarding completion, tour state, training stage, and intent persisted as key-value pairs
- **In-memory transient state** — Coach mark step, sheet presentation, and form fields as `@State`/`@Observable` properties
- **Offline-first architecture** — All features work without network connectivity
- **No data sync** — Single-device storage only; no CloudKit, iCloud, or remote backup
- **SwiftData auto-migration** — Schema changes handled automatically for basic model evolution
