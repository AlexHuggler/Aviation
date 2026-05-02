# SoloTrack - Customer Journeys

End-to-end journeys for the major user flows currently supported in SoloTrack as of April 18, 2026.

---

## Journey 1: First Launch to First Logged Flight

### Actor

- Student pilot on a fresh install

### Preconditions

- No flights
- No templates
- Onboarding not completed

### Flow

1. App launches and builds the model container, onboarding manager, sync settings, flight-session controller, and notification coordinator.
2. On first launch, SoloTrack also checks whether older local data needs migration into the App Group store.
3. `ContentView` appears and presents `OnboardingView`.
4. User selects a training stage:
   - Pre-Solo
   - Post-Solo
   - Checkride Prep
5. User selects how to get started:
   - Log a flight
   - Enter past flights
   - Explore the app
6. SoloTrack persists stage + intent and dismisses onboarding.
7. If the user chose Log a flight or Enter past flights:
   - Dashboard becomes the active root destination
   - `AddFlightView` is presented immediately
8. In Add Flight, the user enters:
   - date
   - route
   - Hobbs
   - at least one landing
9. Stage-aware defaults prefill Solo/Dual where appropriate.
10. User taps Save.
11. Flight is inserted into SwiftData, widget timelines are refreshed, and the presenting surface shows save confirmation.
12. Dashboard, Progress, Logbook, and widget surfaces now have live data.

### Outcome

- User has completed onboarding
- First flight is stored
- Dashboard, Progress, Logbook, and shared data surfaces are active

---

## Journey 2: Explore-First Onboarding Tour

### Actor

- Student pilot who chooses "Explore the app"

### Preconditions

- Fresh install
- Onboarding incomplete

### Flow

1. User completes onboarding with intent set to Explore.
2. Instead of opening Add Flight, `currentCoachStep` is set to `.dashboardWelcome`.
3. `CoachMarkOverlay` appears above the root navigation.
4. The tour advances through:
   - Dashboard welcome
   - currency cards
   - Progress
   - Logbook
   - add-flight button
   - completion state
5. As the user advances:
   - on iPhone, `TabView` selection changes
   - on iPad, sidebar `NavigationSection` changes
6. User can continue through the tour or skip it.
7. Completing or skipping the tour marks `hasCompletedTour = true`.

### Outcome

- User understands the main information architecture before logging data
- Future launches skip the coach mark flow

---

## Journey 3: Log a Flight With Advanced Details and Save as Template

### Actor

- Student pilot logging a typical lesson or repeated route

### Preconditions

- User is already onboarded
- May already have prior flights or templates

### Flow

1. User opens Add Flight from Dashboard, Logbook, Progress, or a deep-link entry.
2. SoloTrack preloads:
   - stage-based Solo/Dual defaults
   - most recent route when available
   - template options when they exist
3. User may apply a saved template to populate route, categories, Hobbs, remarks, and CFI number.
4. User enters or edits:
   - date
   - route
   - Hobbs or Hobbs start/end
   - Tach
   - landings
   - category toggles
5. User expands `More Details`.
6. User can add advanced training detail such as:
   - flight review
   - instrument approaches
   - holding / tracking
   - XC distance
   - longest leg
   - full-stop airports
   - towered operations
   - checkride prep
7. User may open the template action and save the current configuration as a reusable template.
8. User taps Save.

### Validations and Decision Points

- Hobbs must be valid and greater than zero
- At least one landing is required
- Hobbs over 12 hours shows a warning but can still be saved
- Cancelling after edits triggers discard confirmation

### Outcome

- Flight is saved
- Optional template is stored for later reuse
- If Quick Entry is off, the sheet dismisses normally

---

## Journey 4: Quick Entry Backfill Session

### Actor

- Student pilot entering multiple historical flights

### Preconditions

- Add Flight opened in create mode

### Flow

1. User opens Add Flight.
2. User enables Quick Entry from the toolbar.
3. User logs the first flight and taps Save.
4. SoloTrack:
   - inserts the flight
   - keeps the form open
   - shows quick-entry confirmation
   - increments the quick-entry count and running Hobbs total
5. Form resets for the next entry.
6. User repeats the process for additional flights.
7. User exits the flow by tapping Cancel once they are done.

### Outcome

- Multiple flights are logged rapidly without reopening the sheet
- User receives session-level feedback on how many flights and hours were entered

---

## Journey 5: Start and Stop a Flight Session in the App

### Actor

- Student pilot who wants to time a live flight before finishing the log entry

### Preconditions

- User is on Dashboard
- No active timer session exists yet

### Flow

1. User sees the `FLIGHT SESSION` card on Dashboard.
2. User taps `Start`.
3. `FlightSessionController` starts a single active session through the shared store.
4. Dashboard updates to show:
   - session-running status
   - elapsed timer
   - `Stop` as the primary action
5. If supported, the Live Activity is started.
6. After the flight, user returns to Dashboard and taps `Stop`.
7. SoloTrack ends the timer, builds a session-prefill payload, and immediately presents Add Flight.
8. Add Flight prepopulates:
   - date
   - Hobbs
   - Tach
9. User completes the remaining details and saves the flight.

### Outcome

- A timed flight becomes a partially completed log entry with minimal extra typing

---

## Journey 6: Stop the Timer From Shortcuts or the Control Widget and Re-enter the App

### Actor

- Student pilot using a system surface instead of the main app UI

### Preconditions

- A single active timer session exists

### Flow

1. User stops the session from one of these surfaces:
   - `StopFlightSessionIntent`
   - `SoloTrackWidgetsControl`
2. The shared timer store:
   - ends the active session
   - creates a `FlightSessionPrefill`
   - stores that prefill as pending shared state
3. The Live Activity ends and widget timelines refresh.
4. Later, the user reopens SoloTrack.
5. On launch or foreground, `ContentView` checks for a pending prefill.
6. SoloTrack consumes the pending prefill once and opens Add Flight automatically.
7. Add Flight shows prefilled Hobbs and Tach based on the timer session.
8. User finishes the record and saves.

### Outcome

- Timer-driven logging still works even when the timer was controlled outside the main app
- Pending prefills behave like a one-shot handoff, not a persistent draft queue

---

## Journey 7: CFI Endorsement, Locking, and Voiding

### Actor

- Student pilot and instructor during or after a lesson

### Preconditions

- A flight is being created or edited

### Flow

1. In Add Flight, user expands `More Details`.
2. User enters the instructor’s CFI number.
3. Instructor signs in the PencilKit canvas.
4. User saves the flight.
5. SoloTrack stores:
   - signature image data
   - CFI number
   - signature date
   - `isSignatureLocked = true`
6. The flight becomes non-editable in standard edit flows.
7. Later, from `FlightDetailView`, the user can inspect the endorsement block and see the lock state.
8. If the signature needs to be removed, the user taps `Void Signature`.
9. SoloTrack confirms the destructive action, then clears endorsement data and unlocks the flight.

### Outcome

- Endorsed flights are protected from accidental editing
- Users still have a deliberate recovery path when a signature must be re-collected

---

## Journey 8: CSV Import From Another Logbook

### Actor

- Student pilot migrating data into SoloTrack

### Preconditions

- Existing flights may or may not already exist
- User is in Logbook

### Flow

1. User taps Import in the Logbook toolbar or presses `Cmd-I`.
2. `ImportView` opens.
3. User chooses either:
   - Auto Detect
   - SoloTrack CSV
   - ForeFlight-style CSV
   - LogTen-style CSV
   - MyFlightBook-style CSV
   - Generic CSV
4. User selects a file from the system file picker.
5. SoloTrack parses headers and rows using `ImportParser`.
6. The sheet shows:
   - detected format
   - selected filename
   - ready-to-import row count
   - duplicates flagged
   - rows with errors
7. User reviews each row:
   - valid rows can be toggled on/off
   - duplicates are flagged with warnings
   - invalid rows show hard errors
8. User taps Import.
9. SoloTrack inserts only valid, selected rows into SwiftData and refreshes widget timelines.
10. Import sheet dismisses and Logbook shows an "Import complete" toast.

### Outcome

- User migrates historical flight data without manual re-entry
- Duplicate risk is reduced before commit

---

## Journey 9: Export Logbook as CSV or PDF

### Actor

- Student pilot exporting records for backup, transfer, or review

### Preconditions

- At least one flight exists
- User is in Logbook

### Flow

1. User taps Export in the Logbook toolbar or presses `Cmd-E`.
2. `ExportView` opens with PDF selected by default.
3. User chooses either:
   - CSV
   - PDF
4. User optionally enables `Use Date Range` and picks start/end dates.

### Path A: CSV

5. SoloTrack generates CSV from the filtered flights.
6. User previews the raw CSV text.
7. User can:
   - share the CSV
   - copy it to the clipboard
8. If the user copies it, the button changes to the confirmation state.

### Path B: PDF

5. SoloTrack filters flights by date range and generates a temporary PDF file.
6. User sees:
   - selected flight count
   - file size
   - page count
   - short preview rows
7. User shares the PDF through the system share sheet.

### Outcome

- User leaves with either machine-readable CSV or presentation-ready PDF

---

## Journey 10: Use App Shortcuts for Fast Logging and Status Checks

### Actor

- Student pilot interacting through Siri or the Shortcuts app

### Preconditions

- SoloTrack App Shortcuts are available on the device

### Flow

1. `SoloTrackShortcutsProvider` exposes the shipped Shortcut actions on the device.
2. User invokes one of those actions:
   - `LogQuickFlightIntent`
   - `CheckCurrencyIntent`
   - `NextMilestoneIntent`
   - `OpenAddFlightIntent`
   - `StartFlightSessionIntent`
   - `StopFlightSessionIntent`
3. If the action is read-only, SoloTrack responds with spoken/dialog status:
   - current currency
   - next milestone and remaining hours
4. If the action logs a quick flight, SoloTrack writes the flight directly to the shared store and refreshes widget timelines.
5. If the action opens Add Flight, the app is deep-linked into the add-flight flow.
6. If the action starts or stops the timer, shared timer state updates and the Live Activity/widgets are refreshed.

### Outcome

- The user can act on the logbook or query key status without navigating the full app first

---

## Journey 11: Adjust Training Stage and Enable iCloud Sync

### Actor

- Student pilot refining app behavior after initial usage

### Preconditions

- User has flights logged
- User is on Dashboard

### Flow

1. User taps the gear icon on Dashboard.
2. `SettingsView` opens.
3. In `Student Journey`, user can manually select a different training stage.
4. If the logged-flight history suggests a better stage, SoloTrack shows a recommendation card.
5. User can accept the suggestion with `Use Suggested Stage`.
6. In `Backup & Sync`, user toggles `Enable iCloud Sync`.
7. `SyncSettings.desiredMode` updates immediately.
8. The status row changes to explain that relaunch is required if the desired mode differs from the active mode.
9. User closes Settings and later relaunches the app.
10. On next launch, the app builds the model container in the newly selected storage mode.

### Outcome

- Stage-aware defaults and messaging can evolve with the student’s journey
- Core logbook data can move from local-only to iCloud-backed storage

---

## Journey 12: Re-enter Through Widgets, Live Activity, or Notifications

### Actor

- Student pilot returning because a system surface surfaced something important

### Preconditions

- At least one supporting surface is active:
   - widget
   - Live Activity
   - notification

### Flow

1. User sees a SoloTrack surface outside the main app:
   - currency widget
   - progress widget
   - last-flight widget
   - active timer Live Activity
   - notification about currency, milestones, or momentum
2. The user taps through or reopens SoloTrack.
3. Depending on the surface:
   - widgets route through `solotrack://dashboard` or `solotrack://add-flight`
   - the Live Activity routes through `solotrack://dashboard`
   - notifications re-enter the app with the relevant context already visible in Dashboard / Progress
4. User can then:
   - log a flight
   - inspect current currency
   - review the next milestone
   - stop or continue the timer session

### Outcome

- SoloTrack works as a multi-surface product, not just an app that must always be opened first

---

## Journey Summary Matrix

| Journey | User Goal | Primary Surface | Supporting Surfaces | End State |
|--------|-----------|-----------------|---------------------|-----------|
| 1. First Launch | Start using the product | Onboarding | Dashboard, Add Flight | First flight logged |
| 2. Explore Tour | Learn layout before logging | Coach marks | Tabs or sidebar | Tour completed |
| 3. Log With Details | Capture a rich training flight | Add Flight | Templates | Flight saved |
| 4. Quick Entry | Backfill multiple flights fast | Add Flight | Toast feedback | Several flights saved |
| 5. In-App Timer | Time a live flight and log it | Dashboard | Add Flight, Live Activity | Prefilled log entry |
| 6. External Timer Stop | Stop timer from a system surface | Shortcut / Control Widget | App re-entry, Add Flight | Pending prefill consumed |
| 7. Endorsement | Capture or remove CFI signoff | Add Flight / Detail | Signature view | Locked or unlocked flight |
| 8. Import | Bring outside records in | Import | Logbook | Imported flights saved |
| 9. Export | Share or back up records | Export | Share sheet | CSV or PDF delivered |
| 10. App Shortcuts | Query or act quickly | Shortcuts / Siri | Shared store, widgets, timer | Action completed |
| 11. Settings / Sync | Adjust stage or storage mode | Settings | Dashboard relaunch cycle | Mode or stage updated |
| 12. System Re-entry | Return because something matters | Widget / Live Activity / Notification | Dashboard, Progress, Add Flight | User re-engaged |
