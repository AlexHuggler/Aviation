# SoloTrack - Feature Inventory

A current inventory of user-facing and product-shaping capabilities implemented in SoloTrack as of April 18, 2026.

---

## 1. Onboarding, Personalization, and Navigation

- **Training stage selection** - Pre-Solo, Post-Solo, or Checkride Prep
- **Getting-started intent selection** - Log a flight, backfill past flights, or explore the app
- **Intent-based routing** - can immediately open the add-flight flow or start the coach mark tour
- **Persisted onboarding state** - onboarding completion, tour completion, stage, and intent stored across launches
- **Coach mark tour** - guided overlay that walks across Dashboard, Progress, Logbook, and add-flight entry
- **Navigation-aware coach marks** - tabs on iPhone and sidebar sections on iPad are switched automatically during the tour
- **iPhone tab layout** - Dashboard, Progress, and Logbook in a `TabView`
- **iPad sidebar layout** - `NavigationSplitView` driven by `NavigationSection`
- **Personalized empty dashboard** - stage-specific messaging and highlighted capabilities after onboarding
- **Stage-aware form defaults** - Solo/Dual toggles prefilled from the selected training stage
- **Training-stage welcome messaging** - stage-specific copy reinforces progress context
- **Training-stage suggestion engine** - Settings can suggest moving from pre-solo to post-solo or checkride-prep mode
- **Onboarding reset support** - development/test reset path for onboarding state

---

## 2. Dashboard, Status, and Flight Session Control

- **Dashboard empty-state variants** - separate pre-onboarding and post-onboarding empty states
- **Legal-to-fly header** - overall currency emphasis at the top of the populated dashboard
- **Day currency card** - rolling 90-day day landing compliance
- **Night currency card** - rolling 90-day night landing compliance
- **Instrument currency card** - FAR 61.57(c)-style recency surface from approaches/holding/tracking
- **Flight review currency card** - FAR 61.56-style recency surface
- **Quick stats section** - totals for hours, flights, and requirements met
- **Next milestone card** - closest unmet PPL requirement with remaining-hours messaging
- **Recommended flight nudge** - dashboard can launch Add Flight with a suggested training configuration
- **Dashboard settings entry** - gear button opens Settings
- **Dashboard add-flight entry** - plus button opens Add Flight when flights exist
- **Save toast feedback** - dashboard shows confirmation after a successful save
- **Flight session card** - start or stop the single active timer directly from Dashboard
- **In-app timer elapsed display** - running timer is shown live on the Dashboard
- **In-app timer stop-to-prefill handoff** - stopping the timer in-app opens Add Flight with prefilled Hobbs and Tach
- **Pull-to-refresh polish** - lightweight refresh animation/haptic pattern

---

## 3. PPL Progress and Checklist Tracking

- **Overall progress ring** - percent complete across six top-level FAR 61.109 requirements
- **Requirements met counter** - X of 6 requirements met
- **Requirement cards** - title, FAR citation, progress bar, percent, and remaining hours
- **Milestone tick marks** - progress bars show 25/50/75 percent markers
- **Met-state celebration** - visual and haptic celebration when requirements are newly completed
- **Detailed checklist section** - beyond the six buckets, SoloTrack tracks specific experience requirements
- **Night dual training checklist item**
- **Night cross-country checklist item**
- **Night towered landings checklist item**
- **Instrument instruction checklist item**
- **Checkride-prep-in-last-two-calendar-months checklist item**
- **Solo 150 NM cross-country checklist item**
- **Solo towered landings checklist item**
- **Actionable empty state** - empty progress screen can open Add Flight directly

---

## 4. Flight Logging Core

- **New flight entry** - accessible from Dashboard, Progress empty state, Logbook, onboarding routing, and deep-link entry
- **Edit existing flight** - available for unlocked flights
- **Date selection** - bounded to current/past dates
- **Route entry** - separate From/To fields with route formatting support
- **Route swap control** - quick reversal for return legs
- **Recent route defaults** - form starts from the most recent flight when available
- **Recent route quick-picks** - reusable recent routes visible in the form
- **ICAO code suggestions** - prefix-matched airport recommendations while typing
- **Known-airport indicator** - visual state for known vs unknown ICAO codes
- **Custom airport save flow** - unknown four-letter codes can be saved to the personal airport list
- **Direct Hobbs entry**
- **Hobbs calculator mode** - start/end entry calculates Hobbs automatically
- **Tach entry**
- **Session-prefill handoff** - timer-based Hobbs/Tach values can prefill Add Flight once
- **Day landing stepper**
- **Night full-stop landing stepper**
- **Core category toggles** - Solo, Dual Received, Cross-Country, Simulated Instrument
- **Inline validation** - Hobbs and landing requirements validated before save
- **Soft warning for unusually long flights** - >12 hour Hobbs warning
- **Discard protection** - unsaved changes trigger confirmation before dismissal
- **Dirty-state tracking** - form compares against initialized defaults
- **Save keyboard shortcut** - `Cmd-S`
- **Field-to-field keyboard navigation** - Previous/Next/Done toolbar and focus management

---

## 5. Advanced Flight Detail, Templates, and Endorsements

- **Progressive disclosure** - advanced fields live under "More Details"
- **Remarks entry**
- **Flight review flag**
- **Instrument approaches count**
- **Holding procedures flag**
- **Course tracking flag**
- **Cross-country distance entry**
- **Longest cross-country leg entry**
- **Full-stop airports count**
- **Towered airport operations flag**
- **Checkride prep flight flag**
- **Advanced-content dot indicator** - disclosure label indicates hidden filled fields
- **Recommendation-aware defaults** - dashboard nudge can preconfigure advanced toggles when relevant
- **Flight templates** - saved reusable flight defaults backed by SwiftData
- **Apply template to new flight** - fills route, toggles, Hobbs, landings, remarks, and CFI number
- **Template list in add-flight flow** - shown only in create mode
- **Save current form as template**
- **Delete template from picker**
- **Auto-expand advanced section for template data** - remarks or CFI template content reveals details automatically
- **Quick Entry mode** - keep logging multiple flights without dismissing the form
- **Quick Entry running tally** - shows count and total Hobbs saved in the quick-entry session
- **CFI number capture** - direct entry or template-prefill support
- **PencilKit signature canvas**
- **Signature undo**
- **Signature clear**
- **Signature locking on save** - signed flights become read-only
- **Signature date capture**
- **Signature display in flight detail**
- **Void signature flow** - signed flights can be unlocked with confirmation
- **Lock indicators in list/detail**
- **Digital endorsement retained in PDF export**
- **Endorsement templates** - preset training-note templates can populate remarks and related toggles

---

## 6. Logbook Management and Flight Detail

- **Chronological logbook list** - reverse chronological data grouped by month
- **Search across route, date, categories, remarks, and CFI number**
- **Filter chips** - Solo, Dual, Cross-Country, Instrument, Night, This Month, Last 90 Days
- **Filter conflict handling** - mutually exclusive recency filters
- **Summary header** - high-level totals before the list
- **Navigation into Flight Detail**
- **Swipe to edit** - unlocked flights
- **Swipe to duplicate**
- **Swipe to delete**
- **Delete protection for locked flights**
- **Undo delete toast**
- **Add-flight toolbar action**
- **Import toolbar action**
- **Export toolbar action**
- **Keyboard shortcuts for logbook actions** - import, export, and new flight
- **Formatted route header in detail**
- **Time and landing summary cards in detail**
- **Category badges in detail**
- **Training-details section when advanced fields exist**
- **Signature disclosure section**
- **Remarks disclosure section**
- **Duplicate action from detail view**
- **Edit action for unlocked flights**
- **Void-signature action for signed flights**

---

## 7. Import and Export

### Import

- **Dedicated Import sheet**
- **Preset picker** - Auto Detect, SoloTrack CSV, ForeFlight-style, LogTen-style, MyFlightBook-style, Generic CSV
- **File picker integration**
- **Detected format feedback**
- **Import preview summary** - ready rows, duplicates, error counts
- **Per-row preview cards**
- **Per-row warnings**
- **Per-row hard errors**
- **Duplicate detection** - based on date + route + Hobbs identity key
- **Selective import toggles per valid row**
- **Security-scoped file access handling**
- **Import completion toast**

### Export

- **Dedicated Export sheet**
- **Dual export formats** - CSV and PDF
- **Format picker**
- **Optional date-range filtering**
- **CSV preview**
- **PDF preview summary**
- **PDF temporary file generation**
- **PDF page count and file-size summary**
- **CSV share action**
- **PDF share action**
- **CSV copy-to-clipboard**
- **Copy confirmation state**

### CSV Export Details

- **22-column output**
- **Chronological sorting**
- **Escaped commas, quotes, and newlines**
- **Includes advanced training-detail fields**

### PDF Export Details

- **Printable logbook layout**
- **Date range header**
- **Flight and hour totals**
- **Category and endorsement columns**
- **Remarks column**
- **Embedded signature thumbnails when available**
- **Pagination support**

---

## 8. Settings, Sync, and Shared Storage

- **Settings sheet**
- **Training stage picker**
- **Suggested training-stage upgrade card**
- **iCloud sync toggle**
- **Local-only vs iCloud status messaging**
- **Relaunch-required sync transition messaging**
- **Explicit sync boundary explanation** - flights and templates sync; onboarding, notification memory, custom airports, and timer state remain local
- **App Group shared store** - widgets and intents read current data without requiring the app UI
- **`SharedModelContainer` extension reads** - extension targets use the App Group-backed store with CloudKit disabled in extension contexts
- **Data migration to App Group container** - older local store is migrated forward on launch when needed
- **Device-local timer boundary** - flight-session state and pending prefills stay on-device even when flights/templates sync

---

## 9. Notifications and Lifecycle Intelligence

- **Authorization request on app lifecycle startup**
- **Currency cliff detection**
- **Milestone crossed detection**
- **Checkride-ready detection**
- **Momentum stall detection**
- **Per-category cooldowns**
- **Daily notification cap**
- **Once-ever checkride-ready memory**
- **Acknowledged milestone memory**
- **Foreground re-evaluation**
- **Post-save re-evaluation when flight count increases**

Note: notification opt-in flags and memory are persisted internally, but the current product does not expose a dedicated notification settings UI yet.

---

## 10. App Shortcuts and App Intents

- **Quick flight logging via Shortcut** - `LogQuickFlightIntent`
- **Currency status query via Shortcut/Siri** - `CheckCurrencyIntent`
- **Next milestone query via Shortcut/Siri** - `NextMilestoneIntent`
- **Open Add Flight deep link intent** - `OpenAddFlightIntent`
- **Start timer from Shortcut** - `StartFlightSessionIntent`
- **Stop timer from Shortcut** - `StopFlightSessionIntent`
- **Registered app shortcuts provider** - `SoloTrackShortcutsProvider`
- **Shared deep-link contract** - `SoloTrackDeepLink` standardizes dashboard/add-flight re-entry
- **Deep-link return path into the app** - `solotrack://add-flight` and `solotrack://dashboard`

---

## 11. Widgets, Control Widget, and Live Activity

- **Currency widget** - current day, night, instrument, and flight-review status
- **PPL progress widget** - overall progress and next milestone
- **Last flight widget** - most recent flight summary with tap-through to Add Flight
- **Widget data provider** - shared derived-state loader for extension surfaces
- **Control widget** - start or stop the flight session timer from Control Center or the Lock Screen
- **Single active Live Activity** - running flight-session timer mirrored on supported system surfaces
- **Live Activity dashboard return path** - tapping the activity returns the user to SoloTrack
- **Widget deep links** - widgets open Dashboard or Add Flight depending on the surface
- **Widget bundle registration** - `SoloTrackWidgetBundle` ships the glanceable, control, and live-timer surfaces together

---

## 12. Productivity, Accessibility, and Support Features

- **Keyboard shortcuts help sheet**
- **Tab and sidebar navigation shortcuts**
- **Toast feedback pattern reused across flows**
- **Motion-aware animations**
- **Dynamic Type token scaling**
- **Haptic service with success, warning, error, and milestone patterns**
- **UI test accessibility identifiers**
- **Seed-data and state-reset launch hooks for automation**

---

## 13. Current Constraints Still Present

- **No account system** - sync relies on the user’s iCloud environment rather than an app-specific identity model
- **No dedicated instructor mode** - CFI interactions remain embedded in the student workflow
- **No external flight-service integrations yet** - no ForeFlight, Garmin, or FAA-connected sync
- **No exposed notification preference controls yet**
- **Single active timer only** - the live flight-session flow is intentionally one session at a time
