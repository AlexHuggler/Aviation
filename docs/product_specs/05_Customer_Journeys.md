# SoloTrack — Customer Journeys

End-to-end user flows through every major scenario, documenting each screen, decision point, and edge case.

---

## Journey 1: First-Time User — App Launch to First Flight Logged

### Actors
- **Student Pilot** (primary user)

### Preconditions
- Fresh app install, no prior data
- `hasCompletedOnboarding == false`

### Flow

```
1. App Launch
   └── SoloTrackApp initializes:
         • OnboardingManager created (all defaults: false/nil)
         • SwiftData ModelContainer created (empty)
         • ContentView loads

2. ContentView Appears
   └── Checks onboarding.hasCompletedOnboarding == false
         └── Presents OnboardingView as sheet

3. OnboardingView — Step 0: Training Stage
   ┌─────────────────────────────────────────┐
   │  Welcome to SoloTrack                   │
   │  ✈️ (animated airplane icon)            │
   │                                         │
   │  "Tell us where you are in training"    │
   │                                         │
   │  ┌─────────────┐                        │
   │  │ Pre-Solo    │ ← Haptic on tap        │
   │  │ Post-Solo   │                        │
   │  │ Checkride   │                        │
   │  └─────────────┘                        │
   │                                         │
   │  ● ○  [Continue →]                      │
   └─────────────────────────────────────────┘

   Decision Point: User selects training stage
   └── Continue button enabled → Spring animation to Step 1

4. OnboardingView — Step 1: Getting Started Intent
   ┌─────────────────────────────────────────┐
   │  How would you like to get started?     │
   │                                         │
   │  ┌──────────────────────┐               │
   │  │ Log a Flight         │               │
   │  │ Enter Past Flights   │               │
   │  │ Explore the App      │               │
   │  └──────────────────────┘               │
   │                                         │
   │  ○ ●  [Get Started →]                   │
   └─────────────────────────────────────────┘

   Decision Point: User selects intent → Success haptic
   └── completeOnboarding(stage:intent:) called
         ├── Persists stage + intent to UserDefaults
         ├── hasCompletedOnboarding = true
         └── Sheet dismisses

5. Post-Onboarding Routing
   │
   ├── Path A: "Log a Flight" or "Enter Past Flights"
   │     └── shouldOpenAddFlight = true
   │           └── DashboardView appears
   │                 └── PersonalizedEmptyDashboard shown
   │                       └── After 0.5s delay → AddFlightView opens
   │                             └── → Go to Step 6
   │
   └── Path B: "Explore the App"
         └── currentCoachStep = .dashboardWelcome
               └── → Go to Journey 2 (Coach Mark Tour)

6. AddFlightView — First Flight Entry
   │
   ├── Smart Defaults Applied:
   │     ├── No prior flights → persona defaults only
   │     ├── Pre-Solo → isDualReceived = true
   │     ├── Post-Solo → isSolo = true
   │     └── Checkride Prep → isSolo = true
   │
   ├── User fills required fields:
   │     ├── Date (defaults to today)
   │     ├── Route From / To (ICAO codes)
   │     ├── Hobbs duration (> 0 required)
   │     ├── Day landings (defaults to 1)
   │     └── Optional: categories, remarks, signature
   │
   └── User taps Save
         │
         ├── Validation passes → Flight inserted → Success haptic
         │     └── Sheet dismisses → Dashboard now shows data:
         │           ├── Currency cards (computed)
         │           ├── Quick stats (1 flight, X.X hours)
         │           └── Progress nudge (next unmet requirement)
         │
         └── Validation fails → Error shown
               ├── Hobbs = 0 → "Duration required"
               └── No landings → "At least 1 landing required"
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| User dismisses onboarding sheet before completing | Sheet re-presents on next app launch (hasCompletedOnboarding still false) |
| User swipes to dismiss AddFlightView without saving | Form dirty check → no changes: dismiss. Changes made: "Discard?" alert |
| User enters Hobbs > 12 hours | Warning alert: "This flight is over 12 hours. Are you sure?" — can override |
| User enters future date | DatePicker max prevents selection |

---

## Journey 2: Coach Mark Tour — Guided App Exploration

### Actors
- **First-time user** who selected "Explore the App" during onboarding

### Preconditions
- Onboarding complete with intent = `.explore`
- `currentCoachStep = .dashboardWelcome`

### Flow

```
1. Step 0: Dashboard Welcome (Tab 0)
   ┌─────────────────────────────────────────┐
   │  ████ Dimmed Backdrop (0.4 opacity) ████│
   │                                         │
   │  ┌───────────────────────────────┐      │
   │  │ ● ○ ○ ○ ○ ○                  │      │
   │  │ 🏠 "Your Home Base"          │      │
   │  │                               │      │
   │  │ "This is your Dashboard..."   │      │
   │  │                               │      │
   │  │ [Skip Tour]     [Next →]      │      │
   │  └───────────────────────────────┘      │
   └─────────────────────────────────────────┘

2. Step 1: Currency Cards (Tab 0)
   └── Title: "Currency at a Glance"
       Body: Explains day/night currency cards

3. Step 2: Progress Tab (auto-switches to Tab 1)
   └── Title: "Track Your Progress"
       Body: Explains PPL requirement tracking

4. Step 3: Logbook Tab (auto-switches to Tab 2)
   └── Title: "Your Digital Logbook"
       Body: Explains flight log management

5. Step 4: Add Flight Button (auto-switches to Tab 0)
   └── Title: "Log Your First Flight"
       Body: Explains the + button and flight entry

6. Step 5: Tour Complete (Tab 0)
   └── Title: "You're All Set!"
       Button: [Start Logging →]
       └── completeTour() called
             ├── hasCompletedTour = true
             ├── currentCoachStep = nil
             └── Overlay disappears
```

### Decision Points

| Point | Options | Result |
|-------|---------|--------|
| Any step | Tap "Next" or backdrop | Advance to next step |
| Any step | Tap "Skip Tour" | skipTour() → hasCompletedTour = true, overlay dismisses |
| Final step | Tap "Start Logging" | completeTour() → overlay dismisses, user at Dashboard |

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| User backgrounds app during tour | Tour state preserved in memory; resumes on foreground |
| User force-quits during tour | hasCompletedTour still false; tour does NOT resume (currentCoachStep is transient in-memory state) |

---

## Journey 3: Returning User — Check Currency and Log Flight

### Actors
- **Student Pilot** with existing flight history

### Preconditions
- Onboarding complete, flights already logged
- App launches to Dashboard

### Flow

```
1. App Launch → Dashboard
   │
   ├── "LEGAL TO FLY?" Header
   │     ├── ✈️ Green + "You are current" → Cleared for passenger flight
   │     └── ✈️ Red + "NOT CURRENT" → Cannot carry passengers
   │
   ├── Currency Cards
   │     ├── Day: .valid(45 days) → Green card, "Current — 45 days"
   │     ├── Day: .caution(12 days) → Yellow card, "Expiring in 12 days"
   │     ├── Day: .expired(5 days) → Red card, "Expired 5 days ago"
   │     └── Night: (same three states independently)
   │
   ├── Quick Stats → Total Hours | Total Flights | Reqs Met
   │
   └── Progress Nudge → "Solo Cross-Country: 2.5 hrs to go (50%)"

2. User Decides to Log a Flight
   │
   ├── Taps + button (toolbar) → AddFlightView opens
   │
   └── Smart Defaults Applied:
         ├── Route From/To from most recent flight
         ├── Category toggles from most recent flight
         └── CFI number from most recent flight (if any)

3. Flight Entry
   │
   ├── Recent Route Quick-Picks shown (up to 5 routes)
   │     └── Tap to auto-fill From/To
   │
   ├── User modifies fields as needed
   │     ├── Change date (if logging yesterday's flight)
   │     ├── Update route
   │     ├── Enter Hobbs time
   │     ├── Adjust landings
   │     └── Toggle categories
   │
   └── Save → Validation → Insert → Haptic → Dismiss

4. Dashboard Updates Reactively
   └── @Query auto-refreshes:
         ├── Currency recalculated with new landings
         ├── Stats updated (hours, flights, reqs)
         └── Progress nudge may change
```

---

## Journey 4: CFI Endorsement Flow

### Actors
- **Student Pilot** (flight entry owner)
- **Certified Flight Instructor** (signs the entry)

### Preconditions
- Flight being logged or edited (not signature-locked)
- CFI is physically present with their certificate

### Flow

```
1. Student Opens AddFlightView
   └── Fills flight details as usual

2. Student Expands "More Details" Section
   └── SignatureCaptureView appears:
         ┌────────────────────────────────────┐
         │ 👤 CFI Certificate Number           │
         │ ┌──────────────────────────────┐   │
         │ │ [__________________________] │   │
         │ └──────────────────────────────┘   │
         │                                    │
         │ Signature                          │
         │ ┌──────────────────────────────┐   │
         │ │                              │   │
         │ │     "Sign here"              │   │
         │ │                        [🧹]  │   │
         │ └──────────────────────────────┘   │
         │                                    │
         │ [ Capture Signature ] (disabled)   │
         └────────────────────────────────────┘

3. Student Enters CFI Number
   └── Capture button becomes enabled

4. CFI Draws Signature on Canvas
   │
   ├── PencilKit accepts finger or Apple Pencil input
   ├── Ink pen tool, label color, 3pt width
   │
   ├── Optional: Tap eraser icon to clear and retry
   │
   └── Tap "Capture Signature"
         └── PKDrawing → UIImage → PNG Data
               └── Confirmation: ✅ "Signature captured" (bounce effect)

5. Student Saves Flight
   └── lockSignature() called:
         ├── instructorSignature = PNG data
         ├── cfiNumber = "1234567"
         ├── signatureDate = now
         └── isSignatureLocked = true

6. Post-Lock State
   ├── Flight row in logbook shows 🔒 lock icon
   ├── Flight detail shows signature image + CFI info
   ├── Edit button disabled
   ├── Swipe-to-delete blocked (haptic error + alert)
   └── Only action available: "Void Signature"

7. Void Signature (if needed)
   └── Student opens FlightDetailView
         └── Taps "Void Signature"
               └── Confirmation alert: "Are you sure?"
                     ├── Void → voidSignature() → Flight unlocked
                     └── Cancel → No change
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| CFI number empty, try to capture | Capture button remains disabled |
| Canvas is blank, tap capture | Captures empty image (no validation on drawing content) |
| Edit a locked flight | Not possible — edit button disabled in FlightDetailView |
| Delete a locked flight | Blocked with haptic error feedback and explanatory alert |

---

## Journey 5: Flight Export Flow

### Actors
- **Student Pilot** exporting logbook data (e.g., for DPE, insurance, or personal backup)

### Preconditions
- At least one flight logged

### Flow

```
1. User Navigates to Logbook Tab (Tab 2)
   └── LogbookListView with populated flight list

2. User Taps Export Button (toolbar, left side)
   │
   └── CSVExporter.generateCSV(from:) called
         ├── Flights sorted by date ascending
         ├── 13-column CSV string generated
         └── ExportView sheet presented

3. ExportView
   ┌────────────────────────────────────────┐
   │  📄 Export Logbook                     │
   │                                        │
   │  "Your logbook will be exported as..." │
   │                                        │
   │  ┌──────────────────────────────┐      │
   │  │ Date,From,To,Hobbs,...       │      │
   │  │ 2025-01-15,KSJC,KRHV,1.5,...│      │
   │  │ (scrollable preview)         │      │
   │  └──────────────────────────────┘      │
   │                                        │
   │  [ Share ]                             │
   │  [ Copy to Clipboard ]                 │
   └────────────────────────────────────────┘

4. User Chooses Action
   │
   ├── Path A: Tap Share
   │     └── System ShareLink opens share sheet
   │           ├── AirDrop
   │           ├── Mail
   │           ├── Messages
   │           ├── Save to Files
   │           └── Other system share targets
   │
   └── Path B: Tap Copy to Clipboard
         └── CSV string → UIPasteboard.general
               ├── Success haptic
               ├── Button text: "Copy" → "Copied! ✓" (green)
               └── Auto-reverts after 2 seconds
```

---

## Journey 6: Training Stage Progression

### Actors
- **Student Pilot** progressing through flight training

### Context
Unlike a traditional state machine, the training stage in SoloTrack is set once during onboarding and persists until manually reset. The stage affects defaults and messaging but does not automatically advance based on logged data.

### Stage Impact Matrix

| Aspect | Pre-Solo | Post-Solo | Checkride Prep |
|--------|----------|-----------|----------------|
| **Default Solo toggle** | Off | On | On |
| **Default Dual toggle** | On | Off | Off |
| **Dashboard focus** | Currency | Progress | Progress gaps |
| **Empty dashboard greeting** | "Ready to Begin" | "Building Toward Checkride" | "Final Stretch" |
| **Feature highlight #1** | Currency Tracking | PPL Requirement Progress | Close the Gaps |
| **Feature highlight #2** | CFI Endorsements | Stay Current | Currency Check |
| **Feature highlight #3** | PPL Progress | Export Logbook | Endorsement Ready |
| **Welcome message** | Stage-specific motivational text | Stage-specific motivational text | Stage-specific motivational text |

### Typical Training Timeline

```
App Install (Month 1-3)
  └── Onboarding: Selects "Pre-Solo"
        ├── Dual Received flights dominate
        ├── Dashboard emphasizes currency
        └── CFI endorsement used frequently

First Solo (Month 4-6)
  └── User would need to reset onboarding to change stage
        NOTE: No in-app stage change UI exists.
        Only OnboardingManager.resetOnboarding() (dev utility) resets.

Building Hours (Month 6-12)
  └── Solo and XC flights increase
        ├── Progress tracking becomes more relevant
        └── PPL requirements start filling in

Checkride Prep (Month 12+)
  └── Focus shifts to closing requirement gaps
        ├── Progress nudge highlights remaining hours
        └── Instrument and night hours often the last to meet
```

### Known Gap

There is no user-facing UI to change the training stage after onboarding. A student who selected "Pre-Solo" at install must continue with those defaults even after soloing. The `resetOnboarding()` method exists but is only accessible programmatically (developer/test use). A future settings screen with stage re-selection would resolve this.

---

## Journey 7: Flight Edit and Duplicate Flows

### 7.1 Edit an Existing Flight

```
1. Logbook Tab → Tap flight row → FlightDetailView

2. Check: isSignatureLocked?
   ├── Yes → Edit button disabled (grayed out)
   └── No → Edit button active in toolbar

3. Tap Edit → AddFlightView opens in edit mode
   ├── All fields pre-populated from existing FlightLog
   ├── isFormDirty tracks changes against original values
   └── Save updates the existing entry (no new insert)

4. Save → Success haptic → Toast → Detail view updates
```

### 7.2 Duplicate a Flight

```
1. Logbook Tab → Flight row interactions:
   │
   ├── Path A: Swipe left → Tap "Duplicate" button (skyBlue)
   └── Path B: Long press → Context menu → "Duplicate"

2. Duplicate Logic:
   ├── Creates new FlightLog with same field values
   ├── Sets date to today (Date.now)
   ├── Does NOT copy signature (new flight is unsigned)
   └── Inserts into ModelContext

3. Result:
   └── New flight appears at top of logbook (today's date)
         └── User can edit if needed
```

### Use Case
Duplicating is designed for pilots who fly the same route repeatedly (e.g., pattern work at a home airport). It's also useful for backfilling multiple similar flights from a paper logbook — a scenario explicitly supported by the "Enter Past Flights" onboarding intent.

---

## Journey 8: Search and Filter Flow

### Actors
- **Student Pilot** looking for specific flights

### Flow

```
1. Logbook Tab → Search bar appears at top

2. User types search query
   │
   └── Real-time filtering against:
         ├── routeFrom (case-insensitive contains)
         ├── routeTo (case-insensitive contains)
         ├── categoryTags (e.g., "Solo", "Dual", "XC", "Inst")
         ├── remarks (free-text match)
         └── cfiNumber (CFI certificate number)

3. Results update instantly
   ├── Matching flights displayed in grouped list
   ├── Non-matching flights hidden
   └── Empty result: standard empty state

4. User clears search
   └── Full logbook restored
```

### Examples

| Query | Matches |
|-------|---------|
| `KSJC` | Flights departing or arriving at KSJC |
| `Solo` | All solo flights (via categoryTags) |
| `night` | Flights with "night" in remarks |
| `1234567` | Flights endorsed by CFI #1234567 |

---

## Journey Summary Matrix

| Journey | Trigger | Steps | Decision Points | Key Outcome |
|---------|---------|-------|-----------------|-------------|
| 1. First-Time User | App install | 6 | Training stage, intent | First flight logged |
| 2. Coach Mark Tour | "Explore" intent | 6 tour steps | Skip or complete | User understands app |
| 3. Returning User | App launch | 4 | Which flight to log | Currency updated |
| 4. CFI Endorsement | Instructor present | 7 | Void or keep | Flight locked |
| 5. Export | Need external copy | 4 | Share or copy | CSV delivered |
| 6. Stage Progression | Training advances | — | No in-app change | Defaults persist |
| 7. Edit/Duplicate | Modify existing | 3–4 | Edit vs duplicate | Data corrected/replicated |
| 8. Search | Find specific flight | 4 | Query terms | Results filtered |
