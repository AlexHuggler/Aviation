# SoloTrack iOS App — Comprehensive Manual Test Plan

**App Version:** Pre-submission
**Platform:** iOS 17+
**Test Environment:** iPhone (various models), iPad
**Build Configuration:** Release
**Date:** February 2026

---

## Overview

SoloTrack is a Private Pilot License (PPL) training logbook and progress tracker for student pilots pursuing their certificate under FAA regulations (FAR 61.109). This test plan covers all manual test cases required prior to App Store submission.

**Key App Characteristics:**
- Fully offline (zero networking/API calls)
- Single permission: Notifications (.alert, .sound, .badge)
- No In-App Purchases, no authentication
- Zero third-party dependencies — Apple frameworks only (SwiftUI, SwiftData, PencilKit, UserNotifications)
- Data: SwiftData (FlightLog) + UserDefaults (onboarding state, notification preferences)

---

## Test Case Summary

| # | Category | Test IDs | Count |
|---|----------|----------|-------|
| 1 | Onboarding — Happy Path | TC-001 to TC-005 | 5 |
| 2 | Onboarding — Edge Cases | TC-006 to TC-009 | 4 |
| 3 | Flight Logging — Happy Path | TC-010 to TC-017 | 8 |
| 4 | Flight Logging — Negative | TC-018 to TC-030 | 13 |
| 5 | CFI Signature | TC-031 to TC-036 | 6 |
| 6 | Dashboard | TC-037 to TC-041 | 5 |
| 7 | PPL Progress Tracking | TC-042 to TC-045 | 4 |
| 8 | Logbook | TC-046 to TC-054 | 9 |
| 9 | CSV Export | TC-055 to TC-058 | 4 |
| 10 | Notifications | TC-059 to TC-064 | 6 |
| 11 | iOS Specific — Network & State Restoration | TC-065 to TC-070 | 6 |
| 12 | iOS Specific — Permission Handling | TC-071 to TC-073 | 3 |
| 13 | iOS Specific — UI Adaptability & Accessibility | TC-074 to TC-079 | 6 |
| 14 | Data Integrity & Persistence | TC-080 to TC-082 | 3 |
| 15 | App Store Review Specifics | TC-083 to TC-090 | 8 |
| | **Total** | | **90** |

---

## 1. Onboarding — Happy Path

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-001 | Happy Path | Complete onboarding with Pre-Solo stage and "Log a flight" intent | Fresh install (no UserDefaults data) | 1. Launch app for the first time. 2. Verify onboarding sheet appears. 3. Select "Pre-Solo" on Step 1. 4. Tap "Continue". 5. Select "Log a flight" on Step 2. 6. Tap "Get Started". | Onboarding sheet dismisses. After ~0.5s delay, AddFlightView sheet opens automatically. Dashboard shows personalized empty state for Pre-Solo. Solo toggle defaults to OFF, Dual toggle defaults to ON in the flight form. |
| TC-002 | Happy Path | Complete onboarding with Post-Solo stage and "Enter past flights" intent | Fresh install | 1. Launch app. 2. Select "Post-Solo". 3. Tap "Continue". 4. Select "Enter past flights". 5. Tap "Get Started". | Onboarding completes. AddFlightView opens. Dashboard personalized empty state shows Post-Solo messaging. Backfill tip visible on empty dashboard. Solo toggle defaults to ON, Dual defaults to OFF. |
| TC-003 | Happy Path | Complete onboarding with Checkride Prep and "Explore the app" intent | Fresh install | 1. Launch app. 2. Select "Checkride Prep". 3. Tap "Continue". 4. Select "Explore the app". 5. Tap "Get Started". | Onboarding dismisses. Coach mark tour begins at step 0 ("Your Home Base") with a dimmed overlay and floating card. Tab bar visible beneath overlay. |
| TC-004 | Happy Path | Complete the full 6-step coach mark tour | TC-003 completed; tour at step 0 | 1. Tap "Next" through each of the 6 steps: dashboardWelcome, currencyCards, progressTab, logbookTab, addFlightButton, tourComplete. 2. On final step tap "Start Logging". | Tab changes automatically: stays on Dashboard for steps 0–1, switches to Progress for step 2, Logbook for step 3, back to Dashboard for steps 4–5. Tour completes; overlay disappears. `hasCompletedTour` persists as true. |
| TC-005 | Happy Path | Skip the coach mark tour mid-way | Tour active at any step before tourComplete | 1. Tap "Skip Tour" link during any coach mark step. | Tour immediately dismisses. `hasCompletedTour` set to true. No coach mark overlay on subsequent app launches. |

---

## 2. Onboarding — Edge Cases

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-006 | Edge Case | Attempt to dismiss onboarding sheet via swipe-down gesture | Onboarding sheet is presented | 1. Attempt to drag the onboarding sheet downward to dismiss it. | Sheet does NOT dismiss (`.interactiveDismissDisabled()` is active). User must complete both steps. |
| TC-007 | Edge Case | Tap "Continue" on Step 1 without selecting a training stage | Onboarding sheet visible at Step 1 | 1. Do NOT select any training stage card. 2. Observe the "Continue" button state. | "Continue" button is disabled (grayed out). Cannot proceed without a selection. |
| TC-008 | Edge Case | Tap "Get Started" on Step 2 without selecting an intent | On Step 2 of onboarding | 1. Do NOT select any intent card. 2. Observe "Get Started" button state. | "Get Started" button is disabled. Cannot complete onboarding without a selection. |
| TC-009 | Edge Case | Tap backdrop during coach mark tour to advance | Tour active at any step | 1. Tap the dimmed area outside the coach mark card. | Tour advances to the next step (same behavior as tapping "Next"). |

---

## 3. Flight Logging — Happy Path

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-010 | Happy Path | Log a basic flight with minimum required fields | Onboarding complete; AddFlightView open | 1. Enter "KSJC" in From field. 2. Enter "KRHV" in To field. 3. Enter "1.5" in Hobbs field. 4. Verify Day Landings shows 1 (default). 5. Tap "Save". | Flight saves successfully. Toast "Flight saved" appears. Sheet dismisses. Flight appears in Logbook with route "KSJC → KRHV", 1.5h, 1 day landing. Success haptic fires. |
| TC-011 | Happy Path | Smart defaults populate from most recent flight | At least one flight logged (e.g., KSJC to KRHV, Solo) | 1. Tap + to add a new flight. 2. Observe pre-populated fields. | From field = "KSJC", To field = "KRHV", Solo toggle matches last flight. Focus auto-advances to Hobbs field. |
| TC-012 | Happy Path | Log a flight using the Hobbs calculator (start/end) | AddFlightView open | 1. Tap "Calculator" link in the Duration section header. 2. Enter Hobbs Start = "1234.5". 3. Enter Hobbs End = "1236.0". 4. Observe computed duration. 5. Tap Save. | Duration section switches to Start/End fields. Computed "Duration: 1.5 hrs" displays below in blue. Flight saves with durationHobbs = 1.5. |
| TC-013 | Happy Path | Swap route From/To using swap button | AddFlightView with From = "KSJC", To = "KPAO" | 1. Tap the circular arrow swap button between From and To fields. | From field changes to "KPAO", To field changes to "KSJC". Swap icon rotates 180° with animation. Selection haptic fires. |
| TC-014 | Happy Path | Quick-Entry mode for rapid backfill | AddFlightView open, Quick Entry off | 1. Tap the bolt icon in the toolbar to enable Quick Entry. 2. Fill in Hobbs = "1.2", leave defaults. 3. Tap Save. 4. Observe form reset. 5. Log another flight. 6. Tap Save. | After first save: inline toast "Saved! (1)" appears, form resets (Hobbs cleared, landings reset to 1/0), date advances by 1 day, route and categories preserved, focus moves to Hobbs. After second save: counter shows "Saved! (2)". Form stays open (does not dismiss). |
| TC-015 | Happy Path | Select a recent route from the quick-pick pills | At least 2 different routes logged previously | 1. Open AddFlightView. 2. Observe horizontal scroll of recent route pills. 3. Tap a route pill (e.g., "KPAO → KSJC"). | From and To fields populate with the selected route. Pill highlights with blue tint. Focus advances to Hobbs field. |
| TC-016 | Happy Path | Auto-fill Tach from Hobbs | AddFlightView open, Tach field empty | 1. Leave Tach field empty. 2. Type "1.5" in Hobbs field. 3. Observe Tach field. | Tach field auto-fills with "1.5" (matching Hobbs value). |
| TC-017 | Happy Path | Toggle between Solo and Dual (mutual exclusivity) | AddFlightView open | 1. Toggle "Solo" ON. 2. Observe "Dual Received" state. 3. Toggle "Dual Received" ON. 4. Observe "Solo" state. | When Solo is toggled ON, Dual Received automatically turns OFF. When Dual Received is toggled ON, Solo automatically turns OFF. They are mutually exclusive. |

---

## 4. Flight Logging — Negative Testing

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-018 | Negative | Attempt to save with empty Hobbs (zero duration) | AddFlightView open | 1. Leave Hobbs field empty. 2. Observe Save button state. 3. Try tapping Save anyway. | Save button is disabled (grayed out). `saveEnabled` returns false because parsedHobbs is nil. |
| TC-019 | Negative | Attempt to save with Hobbs = "0" | AddFlightView open | 1. Enter "0" in Hobbs field. 2. Observe Save button and inline error. | Save button is disabled. `hobbsHasError` is true (parsedHobbs == 0). Hobbs label turns red. |
| TC-020 | Negative | Enter non-numeric text in Hobbs field | AddFlightView open | 1. Enter "abc" in Hobbs field. 2. Observe Save button and inline error. | Save button is disabled. Hobbs label turns red (`hobbsHasError` is true because parsedHobbs is nil). |
| TC-021 | Negative | Attempt to save with zero landings (both Day and Night = 0) | AddFlightView open | 1. Decrement Day Landings to 0. 2. Leave Night Full-Stop at 0. 3. Enter valid Hobbs = "1.0". 4. Observe. | Save button is disabled. Inline error "Every flight needs at least one landing" appears in red below the landing steppers. |
| TC-022 | Negative | Hobbs exceeding 12 hours triggers soft warning | AddFlightView open | 1. Enter "13.0" in Hobbs. 2. Set day landings to 1. 3. Tap Save. | Validation alert appears: "Hobbs time exceeds 12 hours. Please verify this is correct." Warning haptic fires. |
| TC-023 | Negative | Future date selection is prevented | AddFlightView open | 1. Tap the date picker. 2. Attempt to select a date in the future. | Date picker constrains to `...Date.now`. Future dates are not selectable (grayed out in the picker UI). |
| TC-024 | Negative | Cancel with unsaved changes triggers discard alert | AddFlightView with dirty form (Hobbs entered) | 1. Enter "1.5" in Hobbs. 2. Tap "Cancel". | Alert appears: "Discard Flight?" with "Keep Editing" and "Discard" buttons. Tapping "Keep Editing" returns to form. Tapping "Discard" dismisses the sheet. |
| TC-025 | Negative | Cancel with clean form dismisses immediately | AddFlightView with no modifications | 1. Open AddFlightView (smart defaults load). 2. Make NO changes. 3. Tap "Cancel". | Sheet dismisses immediately without a discard alert. `isFormDirty` is false. |
| TC-026 | Negative | Swipe-to-dismiss is blocked when form is dirty | AddFlightView with data entered | 1. Enter "1.0" in Hobbs. 2. Attempt to swipe the sheet down to dismiss. | Sheet does NOT dismiss (`.interactiveDismissDisabled(isFormDirty)` blocks it). User must use the Cancel button. |
| TC-027 | Negative | Hobbs calculator with End less than Start | Calculator mode active | 1. Switch to calculator mode. 2. Enter Start = "1236.0", End = "1234.5". 3. Observe. | No duration row appears (guard `end > start` fails). `parsedHobbs` returns nil. Save button is disabled. |
| TC-028 | Negative | Hobbs calculator with identical start and end times | Calculator mode active | 1. Enter Start = "500.0", End = "500.0". 2. Observe computed duration and Save button state. | Calculator computes 0.0 duration. Hobbs field shows red text. Save button is disabled. |
| TC-029 | Edge Case | Log a flight with only night full-stop landings (Day = 0, Night = 3) | AddFlightView open | 1. Set Day Landings to 0. 2. Set Night Full-Stop to 3. 3. Enter Hobbs = "1.5". 4. Save. | Flight saves successfully. Total landings = 3. Night currency updated accordingly. |
| TC-030 | Edge Case | Landing stepper boundary values (0 and 99) | AddFlightView open | 1. Tap Day Landings stepper down to 0. 2. Try to decrement further. 3. Set to 99. 4. Try to increment further. | Stepper clamps at 0 (lower) and 99 (upper) per `in: 0...99`. Values never go below 0 or above 99. |

---

## 5. CFI Signature

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-031 | Happy Path | Capture a CFI signature and save the flight | AddFlightView open, "More Details" disclosure expanded | 1. Expand "More Details" disclosure. 2. Enter CFI Number = "1234567". 3. Draw a signature on the PencilKit canvas. 4. Tap "Capture Signature". 5. Observe confirmation. 6. Save the flight. | "Signature captured" confirmation with green checkmark appears. Flight saves with `isSignatureLocked = true`, signature PNG data stored, `signatureDate` set. Flight detail view shows "CFI ENDORSEMENT" section with rendered signature image and lock icon. |
| TC-032 | Negative | Attempt to capture signature without entering CFI number | Signature canvas has a drawing, CFI Number field is empty | 1. Draw on canvas. 2. Observe "Capture Signature" button state. | "Capture Signature" button is disabled (`.disabled(cfiNumber.isEmpty)`). Cannot capture without a CFI number. |
| TC-033 | Happy Path | Clear signature using eraser button | Signature drawn on canvas | 1. Tap the eraser icon button. | Canvas clears. `signatureData` resets to nil. "Sign here" placeholder text reappears. |
| TC-034 | Edge Case | Signature-locked flight cannot be deleted via swipe | Flight with locked signature exists in logbook | 1. Go to Logbook tab. 2. Swipe left on the signed flight. 3. Tap "Delete". | Alert: "Cannot Delete — This flight has a locked CFI signature and cannot be deleted. Void the signature first to enable deletion." Error haptic fires. Flight is NOT deleted. |
| TC-035 | Happy Path | Void a locked signature from flight detail | Flight detail view for a signed/locked flight | 1. Navigate to flight detail view. 2. Tap "Void Signature" (red destructive button). 3. Confirm in the alert by tapping "Void". | Signature data is cleared. Lock icon disappears. Flight becomes editable again. "Edit" button appears in toolbar. Warning haptic fires. |
| TC-036 | Edge Case | Edit button is hidden for signature-locked flights | Flight detail view for a locked flight | 1. Navigate to detail view of a flight with `isSignatureLocked = true`. 2. Observe toolbar. | "Edit" button is NOT shown in the toolbar. Only the "Void Signature" option is available. |

---

## 6. Dashboard

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-037 | Happy Path | Dashboard displays correct currency and stats after logging flights | 3+ flights logged with day landings within the last 90 days | 1. Navigate to Dashboard tab. 2. Observe currency cards, quick stats, and progress nudge. | "LEGAL TO FLY?" shows green "You are current" with airplane icon. Day currency card shows green shield with days remaining. Quick Stats show correct Total Hours, Flights count, and PPL Reqs Met (x/6). Next Milestone section shows the closest unmet requirement. |
| TC-038 | Happy Path | Dashboard shows expired currency correctly | All day landings are older than 90 days | 1. Ensure only flights older than 90 days exist. 2. Navigate to Dashboard. | "LEGAL TO FLY?" shows red "NOT CURRENT" with airplane.slash icon. Day currency card shows red shield, "Expired Xd ago" label. |
| TC-039 | Edge Case | Dashboard personalized empty state after onboarding (no flights) | Onboarding completed as Post-Solo / Backfill; zero flights | 1. Complete onboarding with Post-Solo + Backfill. 2. Observe Dashboard. | Personalized empty state: "Building Toward the Checkride" greeting, Post-Solo welcome message, persona-specific feature highlights, CTA says "Start Entering Past Flights", backfill tip visible. |
| TC-040 | Edge Case | Dashboard generic empty state before any persona selection | Fresh install, onboarding just completed with no flights | 1. Complete onboarding. 2. Close AddFlightView without saving. 3. Observe Dashboard. | Empty state with: airplane.circle icon with pulse animation, "Welcome to SoloTrack" title, feature list, and "Log Your First Flight" CTA button. |
| TC-041 | Happy Path | Currency caution state (≤30 days remaining) | Day currency has between 1–30 days remaining | 1. Log flights such that the oldest necessary day landing is ~60+ days old. 2. Observe Day currency card. | Day currency card shows yellow/orange exclamation triangle icon, "Expires in Xd" label, caution gradient border. Warning haptic fires when state transitions to caution. |

---

## 7. PPL Progress Tracking

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-042 | Happy Path | Progress rings and requirement rows update after logging a flight | Some flights logged; Progress tab active | 1. Log a new dual instruction flight for 2.0 hours. 2. Switch to Progress tab. 3. Observe overall progress ring and individual requirement rows. | Overall progress ring percentage increases. "Dual Instruction" row shows updated hours. Progress bar width increases. Remaining hours decrease accordingly. |
| TC-043 | Happy Path | Requirement shows "Complete" with green checkmark when met | Enough flights to meet one requirement (e.g., 3.0+ instrument hours) | 1. Log flights totaling 3.0+ hours with "Simulated Instrument" toggle ON. 2. Open Progress tab. | "Instrument Training" row shows green checkmark icon (replacing percentage), progress bar fully filled, remaining text says "Complete". Celebration scale animation and success haptic fire. |
| TC-044 | Edge Case | Progress view empty state | No flights logged | 1. Navigate to Progress tab with zero flights. | ContentUnavailableView: "No Progress Yet" label, description about FAR 61.109, and "Log Your First Flight" CTA button. Tapping the button opens AddFlightView. |
| TC-045 | Edge Case | Progress exceeding 100% for a single requirement | Total flight time exceeds 40 hours | 1. Log flights totaling 50+ Hobbs hours. 2. Open Progress tab. | "Total Flight Time" row clamps at 100% progress. Shows "50.0 / 40.0 hours" text. Green checkmark displayed. Bar is fully filled, not overflowing. |

---

## 8. Logbook

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-046 | Happy Path | Flights grouped by month in reverse chronological order | Flights from multiple months logged | 1. Navigate to Logbook tab. 2. Scroll through the list. | Flights grouped under "Month Year" headers (e.g., "February 2026"). Most recent month at top. Within each section, flights in reverse date order. |
| TC-047 | Happy Path | Search flights by route, category, or remarks | Multiple flights with different routes and remarks | 1. Tap search bar. 2. Type "KSJC". 3. Observe results. 4. Clear and type "Solo". 5. Clear and type a remark keyword. | Search filters in real-time. "KSJC" shows flights with that route. "Solo" shows solo flights. Remark keyword matches correctly. CFI number also searchable. |
| TC-048 | Edge Case | Search with no results shows empty state | Flights exist but none match | 1. Type "ZZZZ" in search bar. | Standard "No Results for ZZZZ" empty state appears. App does not crash. Clearing search restores full list. |
| TC-049 | Happy Path | View flight detail via navigation link | At least one flight logged | 1. Tap on a flight row in the Logbook. | Flight detail view opens with: route header, date, Hobbs/Tach values, Day/Night landing counts, category badges, remarks, signature section (if signed). |
| TC-050 | Happy Path | Edit a flight (unsigned) from detail view | Flight without a locked signature | 1. Open flight detail. 2. Tap "Edit" in toolbar. 3. Change Hobbs from 1.5 to 2.0. 4. Tap Save. | AddFlightView opens pre-populated with existing data. After saving, flight detail reflects updated Hobbs (2.0). Flight updated in-place (not duplicated). |
| TC-051 | Happy Path | Duplicate a flight via swipe action | At least one flight logged | 1. In Logbook list, swipe right on a flight row. 2. Tap "Duplicate" (blue). | New flight created with today's date and all data copied (except signature). Toast "Flight saved" appears. Success haptic fires. New flight appears at top of list. |
| TC-052 | Happy Path | Delete a flight (unsigned) via swipe action | At least one unsigned flight | 1. Swipe left on an unsigned flight row. 2. Tap "Delete" (red). 3. Confirm deletion in alert. | Alert: "Delete Flight? This flight entry will be permanently deleted." Tapping "Delete" removes the flight. Success haptic fires. |
| TC-053 | Happy Path | Logbook summary header shows correct aggregates | Multiple flights logged | 1. Navigate to Logbook tab. 2. Observe summary pills at top. | Three pills: "Total Hrs" (sum of all Hobbs), "Flights" (total count), "This Month" (Hobbs sum for current month). |
| TC-054 | Edge Case | Logbook empty state | No flights logged | 1. Navigate to Logbook tab with zero flights. | ContentUnavailableView: "No Flights Logged" with airplane.departure icon, "Tap + to log your first flight" description, "Add Flight" CTA button. Export button disabled. |

---

## 9. CSV Export

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-055 | Happy Path | Export logbook to CSV and share via ShareLink | At least one flight logged | 1. In Logbook tab, tap the share/export icon. 2. ExportView sheet appears. 3. Verify CSV preview content. 4. Tap "Share CSV". | ExportView shows: doc.text icon, "Export Logbook" title, monospaced CSV preview, Share and Copy buttons. ShareLink opens the iOS share sheet with CSV content. |
| TC-056 | Happy Path | Copy CSV to clipboard | ExportView open | 1. Tap "Copy to Clipboard". 2. Observe button state change. | Button text changes to "Copied!" with green checkmark. Success haptic fires. Button reverts after ~2 seconds. Pasting from clipboard yields CSV content. |
| TC-057 | Edge Case | CSV contains correct header and properly escaped fields | Flights with commas/quotes in remarks | 1. Log a flight with remarks = `He said "good landing", nice`. 2. Export CSV. 3. Inspect CSV content. | Header row: `Date,From,To,Hobbs,Tach,Day Landings,Night FS Landings,Solo,Dual,XC,Instrument,CFI Number,Remarks`. Remarks field is properly quoted and inner quotes doubled. CSV sorted chronologically (oldest first). |
| TC-058 | Edge Case | CSV with flights that have empty routes | Flight logged with both From and To empty | 1. Log a flight with no route. 2. Export CSV. | CSV row shows empty strings for From and To columns. No crash or malformed row. |

---

## 10. Notifications

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-059 | Happy Path | Notification permission request on first launch | Fresh install, onboarding completed | 1. Complete onboarding. 2. Observe system notification permission dialog. | iOS system alert appears requesting notification permission (.alert, .sound, .badge). User can Allow or Deny. App continues to function regardless of choice. |
| TC-060 | Happy Path | Currency cliff notification fires when currency enters caution zone | Day currency at ≤30 days remaining; permission granted | 1. Set up flight data with day currency at ~30 days remaining. 2. Background and re-foreground the app. | NotificationEvaluator detects `.currencyCliff` event. If rate limits pass (not sent in last 7 days, daily cap not reached, 4-hour cooldown elapsed), notification with title "Currency Heads-Up" dispatched. |
| TC-061 | Happy Path | Milestone notification fires when a PPL requirement is newly met | Flights nearly meeting a requirement; permission granted | 1. Log a flight that brings a requirement to completion (e.g., 10th solo hour). 2. Observe notification pipeline. | Evaluator detects `.milestoneCrossed` event. Notification dispatched. FAR reference recorded in `acknowledgedMilestones` to prevent re-firing. |
| TC-062 | Edge Case | Notification rate limiting — daily cap of 2 | Two notifications already sent today | 1. Trigger a third notification-worthy event. 2. Observe. | Third notification suppressed. `passesRateLimits` returns false at Gate 1 (daily cap). No notification dispatched. |
| TC-063 | Edge Case | Notification rate limiting — global 4-hour cooldown | A notification was sent 1 hour ago | 1. Trigger another notification-worthy event. 2. Observe. | Second notification suppressed. `passesRateLimits` returns false at Gate 2 (global cooldown not elapsed). |
| TC-064 | Edge Case | Checkride ready notification fires exactly once | All 6 PPL requirements met for the first time | 1. Log a flight that causes the final PPL requirement to be met. | `.checkrideReady` event fires with score 1.0 (highest priority). Notification: "All PPL Requirements Met". `hasNotifiedCheckrideReady` set to true. Event never fires again. |

---

## 11. iOS Specific — Network & State Restoration

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-065 | iOS Specific | App functions fully in Airplane Mode | App installed, flights logged | 1. Enable Airplane Mode. 2. Launch SoloTrack. 3. Navigate all tabs. 4. Log a flight. 5. Export CSV. | App functions identically to normal operation. No network-related errors, no loading spinners, no "offline" banners. The app is fully offline by design — zero networking code exists. |
| TC-066 | iOS Specific | State restoration after backgrounding and returning | App open on Dashboard | 1. Open Dashboard. 2. Press Home button (or swipe up). 3. Wait 30 seconds. 4. Reopen the app. | App restores to Dashboard tab in same state. No data loss. No blank screen. Currency cards and stats reflect current data. |
| TC-067 | iOS Specific | State restoration with partial form data after lock screen | AddFlightView open with partial data | 1. Open AddFlightView, enter Hobbs = "1.5". 2. Lock the device. 3. Wait 1 minute. 4. Unlock and return to app. | AddFlightView still presented with Hobbs = "1.5" intact. No data loss. Form state preserved. |
| TC-068 | iOS Specific | Multitasking — switch to another app and return | App in foreground | 1. Open SoloTrack. 2. Switch to Safari (via app switcher). 3. Switch back to SoloTrack. | App resumes in same state. On return to `.active`, NotificationCoordinator evaluates events. No UI glitch or data loss. |
| TC-069 | iOS Specific | Memory pressure — low memory warning | App running with many flights | 1. Simulate low memory (Xcode: Debug > Simulate Memory Warning). 2. Observe app behavior. | App does not crash. SwiftData query results may be re-fetched from store. No visible data corruption. |
| TC-070 | iOS Specific | App termination and cold relaunch | App was force-quit | 1. Force-quit SoloTrack from app switcher. 2. Relaunch the app. | App launches to Dashboard (if onboarding completed). All previously logged flights present (SwiftData persisted). Onboarding state preserved. Coach mark tour does not restart if previously completed. |

---

## 12. iOS Specific — Permission Handling

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-071 | iOS Specific | Grant notification permission | Fresh install, notification prompt shown | 1. When notification permission dialog appears, tap "Allow". | `requestAuthorization()` returns true. Future notification events can dispatch. App continues normally. |
| TC-072 | iOS Specific | Deny notification permission | Fresh install, notification prompt shown | 1. When notification permission dialog appears, tap "Don't Allow". | `requestAuthorization()` returns false. Notification dispatch fails silently (no crash). App continues to function fully — all logging, tracking, and export features work. No error messages shown. |
| TC-073 | iOS Specific | Revoke notification permission after initial grant | Permission was previously granted | 1. Go to iOS Settings > SoloTrack > Notifications. 2. Toggle "Allow Notifications" OFF. 3. Return to SoloTrack. 4. Log a flight that would trigger a milestone notification. | No notification delivered. App does not crash or show errors. All other functionality unaffected. |

---

## 13. iOS Specific — UI Adaptability & Accessibility

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-074 | iOS Specific | Dynamic Type at AX5 (maximum accessibility size) | Device or Simulator | 1. Go to Settings > Accessibility > Display & Text Size > Larger Text. 2. Enable "Larger Accessibility Sizes". 3. Drag slider to maximum (AX5). 4. Open SoloTrack. 5. Navigate all tabs, open AddFlightView, view flight detail, open ExportView. | All text scales appropriately. No text truncation that hides critical information. Layouts adapt (some HStacks may reflow). Tab bar labels readable. Currency cards functional. Steppers usable. No overlapping elements blocking interaction. |
| TC-075 | iOS Specific | Dark Mode rendering across all screens | Device set to Dark Mode | 1. Enable Dark Mode (Settings > Display & Brightness > Dark). 2. Navigate all screens: Dashboard, Progress, Logbook, AddFlightView, ExportView, OnboardingView. | All custom colors render correctly against dark backgrounds. `.ultraThinMaterial` backgrounds adapt. Card styles maintain readability. Currency colors remain distinguishable. PencilKit canvas uses `.label` color ink (adapts to white on dark). |
| TC-076 | iOS Specific | Light Mode rendering across all screens | Device set to Light Mode | 1. Enable Light Mode. 2. Navigate all screens. | All elements render correctly against light backgrounds. No invisible text or washed-out elements. Consistent visual theme. |
| TC-077 | iOS Specific | Reduce Motion enabled — all animations suppressed | Accessibility > Motion > Reduce Motion ON | 1. Enable Reduce Motion in iOS Settings. 2. Open SoloTrack. 3. Navigate all tabs. 4. Complete onboarding. 5. Log a flight. 6. Observe coach mark transitions. | ALL animations suppressed. `motionAwareAnimation` returns nil when `reduceMotion` is true. Coach mark transitions instant. Progress ring fills without animation. Onboarding step transitions instant. No `.symbolEffect` animations fire. |
| TC-078 | iOS Specific | VoiceOver full navigation audit | VoiceOver enabled | 1. Enable VoiceOver. 2. Navigate Dashboard. 3. Swipe through currency cards, stat cards, header. 4. Navigate to Progress tab. 5. Navigate to Logbook and swipe through flight rows. 6. Open AddFlightView. | Currency cards announce: "[Day/Night] currency: [state]". Stat cards: "[label]: [value]". Requirement rows: "[title]: [progress]. [remaining]." Flight rows: "[route], [duration] hours, [date]". All interactive elements reachable with appropriate labels. |
| TC-079 | iOS Specific | Bold Text enabled | Accessibility > Bold Text ON | 1. Enable Bold Text in iOS Settings. 2. Restart app. 3. Navigate all screens. | Text renders correctly with increased weight. No layout breakage. All text legible. |

---

## 14. Data Integrity & Persistence

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-080 | Edge Case | UserDefaults persistence across app restarts | Onboarding completed as Checkride Prep | 1. Complete onboarding selecting Checkride Prep. 2. Force-quit app. 3. Relaunch. 4. Verify onboarding state. | `hasCompletedOnboarding` = true, `trainingStage` = checkride_prep persisted. No onboarding sheet appears. |
| TC-081 | Edge Case | SwiftData persistence of FlightLog across app restarts | Multiple flights logged | 1. Log 5 flights with varying data. 2. Force-quit app. 3. Relaunch. 4. Navigate to Logbook. | All 5 flights present with correct data: dates, Hobbs values, routes, landing counts, category toggles, signatures, remarks. No data corruption. |
| TC-082 | Edge Case | Large dataset performance (100+ flights) | 100+ flights logged (use Quick-Entry for rapid backfill) | 1. Log 100+ flights using Quick-Entry mode. 2. Navigate to Dashboard. 3. Navigate to Progress. 4. Navigate to Logbook. 5. Search in Logbook. 6. Export CSV. | App remains responsive. No UI lag when scrolling. Dashboard currency and stats compute correctly. CSV export includes all 100+ rows. Search completes without perceptible delay. |

---

## 15. App Store Review Specifics

| Test ID | Category | Test Description | Prerequisites | Steps to Execute | Expected Result |
|---------|----------|-----------------|---------------|-----------------|-----------------|
| TC-083 | Apple Review | No network calls made at any point | Network monitoring tool (e.g., Charles Proxy or Xcode Network Instrument) | 1. Install network monitoring proxy. 2. Use app extensively: log flights, export CSV, complete onboarding, trigger notifications. 3. Monitor all network traffic. | Zero network requests made. No DNS lookups, no HTTP/HTTPS calls, no analytics pings, no crash reporting, no telemetry. App is entirely offline. |
| TC-084 | Apple Review | No In-App Purchase code or restore mechanism | App running | 1. Search entire codebase for StoreKit references. 2. Run app and look for any purchase-related UI. 3. Check Settings or hidden menus. | No IAP code exists. No "Restore Purchases" button. No StoreKit imports. Free app with no monetization. |
| TC-085 | Apple Review | Privacy — only notification permission requested | App running on device | 1. Go to iOS Settings > SoloTrack. 2. Review permission requests listed. 3. Run app and note any permission prompts. | Only "Notifications" permission appears. No camera, microphone, location, contacts, photos, health, or tracking prompts. |
| TC-086 | Apple Review | App launches within acceptable time (< 3 seconds) | App installed, cold start | 1. Force-quit app. 2. Tap app icon. 3. Time from tap to first interactive screen. | App launches to Dashboard (or onboarding sheet) in under 3 seconds. SwiftData model container initializes synchronously. |
| TC-087 | Apple Review | No crash on first launch with empty data | Fresh install | 1. Install app fresh. 2. Launch immediately. 3. Dismiss or complete onboarding. 4. Navigate all three tabs. | No crash. Empty states display correctly on all tabs. `@Query` returns empty arrays gracefully. CurrencyManager handles empty arrays. ProgressTracker handles zero flights. |
| TC-088 | Apple Review | Content is appropriate and described accurately | App running | 1. Review all user-visible text, labels, and descriptions. 2. Verify no placeholder text, offensive content, or misleading claims. | All text is aviation-specific and accurate. FAR references (61.57, 61.109) correct. No profanity, no placeholder text. Feature descriptions match behavior. |
| TC-089 | Apple Review | App does not use private APIs | Xcode build, static analysis | 1. Build with Xcode and check for private API usage warnings. 2. Run static analyzer. | No private API calls. Only public frameworks: SwiftUI, SwiftData, PencilKit, UserNotifications, UIKit, Foundation, os. |
| TC-090 | Apple Review | iPad compatibility (if Universal) | iPad device or simulator | 1. Run on iPad. 2. Navigate all screens. 3. Test split view / slide over multitasking. 4. Log a flight. 5. Use PencilKit canvas with Apple Pencil. | TabView renders correctly on iPad. Form layouts adapt to wider screens. PencilKit works with finger and Apple Pencil. No layout overflow. Multitasking resizing handled gracefully. |

---

## Appendix: Test Environment Matrix

| Device | iOS Version | Screen Size | Notes |
|--------|-------------|-------------|-------|
| iPhone SE (3rd gen) | iOS 17.x | 4.7" | Smallest supported screen |
| iPhone 15 | iOS 17.x | 6.1" | Standard size |
| iPhone 15 Pro Max | iOS 17.x | 6.7" | Largest iPhone |
| iPad (10th gen) | iOS 17.x | 10.9" | If universal app |
| Any iPhone | iOS 18.x | — | Latest OS compatibility |

## Appendix: Accessibility Test Settings

| Setting | Location | Values to Test |
|---------|----------|---------------|
| Dynamic Type | Settings > Display & Text Size | Default, xxxLarge, AX5 |
| Bold Text | Settings > Display & Text Size | ON / OFF |
| Reduce Motion | Settings > Accessibility > Motion | ON / OFF |
| VoiceOver | Settings > Accessibility > VoiceOver | ON |
| Dark Mode | Settings > Display & Brightness | Light / Dark |
| Increase Contrast | Settings > Accessibility > Display | ON / OFF |
