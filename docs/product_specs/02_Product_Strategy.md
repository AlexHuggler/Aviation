# SoloTrack — Product Strategy

## 1. Product Vision

SoloTrack is the simplest, most focused digital flight logbook for student pilots learning to fly. It replaces the paper logbook with a purpose-built iOS experience that not only records flights but actively guides students toward their Private Pilot License by tracking regulatory requirements and flight currency in real time.

---

## 2. Core Value Proposition

**For student pilots**, SoloTrack eliminates the guesswork from flight training progression:

- **Know if you're legal to fly** — Automatic FAR 61.57 currency tracking tells you at a glance whether you meet day and night passenger-carrying requirements, with color-coded status (green/yellow/red) and countdown to expiration.
- **Know how close you are to your checkride** — FAR 61.109 PPL requirement tracking shows exactly how many hours remain across 6 categories, so you can plan training strategically.
- **Log flights in seconds** — Smart defaults remember your last route and pre-fill category toggles based on your training stage, minimizing data entry after every flight.
- **Get your CFI's digital endorsement** — PencilKit signature capture creates a tamper-resistant record of instructor endorsements tied to specific flights.
- **Your data stays yours** — Fully offline, no account required, no data leaves your device.

---

## 3. Target Audience

### 3.1 Primary: Student Pilots (Pre-Solo through Checkride)

The app's entire UX is designed around three training stages, captured during onboarding:

| Stage | Profile | Evidence in Code |
|-------|---------|------------------|
| **Pre-Solo** | Students still training with an instructor. Default: `isDualReceived = true`. | `TrainingStage.preSolo` — form defaults to Dual Received on |
| **Post-Solo** | Students who have soloed and are building cross-country and solo hours. Default: `isSolo = true`. | `TrainingStage.postSolo` — form defaults to Solo on |
| **Checkride Prep** | Students with most requirements met, focused on filling gaps. Default: `isSolo = true`. | `TrainingStage.checkridPrep` — dashboard emphasis on unmet requirements |

Each stage drives:
- Default flight category toggles in the Add Flight form
- Personalized empty state messaging on the Dashboard
- Motivational welcome messages after onboarding
- Feature highlight prioritization

### 3.2 Secondary: Certified Flight Instructors (CFIs)

CFIs interact with SoloTrack when endorsing student flights:
- PencilKit signature capture tied to the CFI's certificate number
- Signature locking prevents tampering after endorsement
- CFI number is searchable in the logbook

### 3.3 Tertiary: Recreational / Private Pilots

Any certificated pilot maintaining currency can use SoloTrack's core logging and currency tracking features, though the PPL progress tracking is specific to the initial certificate.

---

## 4. Key Differentiators

### 4.1 Training-Stage-Aware UX

Unlike general-purpose logbooks that treat all pilots the same, SoloTrack adapts its interface to the student's current training stage. A pre-solo student sees Dual Received as the default; a post-solo student sees Solo. The dashboard emphasizes currency for early students and requirement gaps for checkride-prep students.

### 4.2 Built-In Regulatory Compliance

SoloTrack doesn't just log flights — it interprets them against FAA regulations:
- **FAR 61.57** currency calculations with a 90-day rolling window, 30-day caution threshold, and expiration tracking
- **FAR 61.109** PPL requirement tracking across 6 aeronautical experience categories

Most competing apps require pilots to manually check currency or use separate calculators.

### 4.3 CFI Digital Endorsement

PencilKit-powered signature capture creates a digital endorsement record that locks the flight entry, preventing post-signature modification. This is a step toward paperless flight training records.

### 4.4 Zero-Dependency, Offline-First Architecture

- No third-party libraries — reduces supply chain risk and maintenance burden
- No network calls — works in airplane mode, at remote airports, and in the cockpit
- No user accounts — no password fatigue, no privacy concerns

### 4.5 Guided Onboarding

A 2-step persona profiling flow followed by an optional 6-step interactive coach mark tour ensures new users understand the app's capabilities immediately, reducing time-to-value.

---

## 5. Competitive Positioning

| Capability | SoloTrack | ForeFlight | MyFlightBook | LogTen Pro |
|-----------|-----------|------------|--------------|------------|
| **Target user** | Student pilots | All pilots (EFB focus) | All pilots | All pilots |
| **Currency tracking** | Automatic (FAR 61.57) | Manual/limited | Manual | Automatic |
| **PPL progress tracking** | Built-in (FAR 61.109) | No | No | No |
| **Persona-driven UX** | Yes (3 training stages) | No | No | No |
| **CFI signature capture** | Yes (PencilKit) | No | No | No |
| **Offline-first** | 100% offline | Requires sync | Web-based | Sync-optional |
| **Price** | Free (no monetization) | Subscription ($) | Free | Subscription ($) |
| **Third-party deps** | Zero | Heavy | Web stack | Moderate |

**Positioning statement**: SoloTrack is the only flight logbook built specifically for the student pilot journey, combining flight logging with regulatory compliance tracking and training-stage-aware UX in a single, offline-first iOS app.

---

## 6. Growth Opportunities

### 6.1 Near-Term (Architecture Ready)

These features can be built on the existing architecture with minimal refactoring:

- **Home Screen Widgets** — Display currency status and PPL progress using WidgetKit. SwiftData's `@Query` already provides the data layer.
- **PDF Logbook Export** — Generate a printable logbook page layout for DPE checkride presentation. The `CSVExporter` pattern can be extended.
- **Additional Currency Types** — Instrument currency (FAR 61.57(c)), flight review (FAR 61.56) — extend `CurrencyManager` with new methods.
- **Logbook Import** — CSV import to complement the existing CSV export, enabling migration from paper or other digital logbooks.

### 6.2 Medium-Term (Moderate Investment)

- **CloudKit Sync** — Multi-device access and automatic backup. SwiftData has built-in CloudKit integration via `ModelConfiguration`.
- **Apple Watch Complications** — Currency status at a glance on the wrist. Leverages the existing `CurrencyState` model.
- **Additional Certificate Tracks** — Instrument Rating (FAR 61.65), Commercial (FAR 61.129) progress tracking. The `ProgressTracker` pattern generalizes cleanly.
- **Siri Shortcuts** — "Hey Siri, am I current?" — query currency status hands-free.

### 6.3 Long-Term (Strategic)

- **CFI Dashboard** — Instructor-facing view to manage multiple students' progress. Would require multi-user data architecture.
- **ForeFlight / Garmin Pilot Integration** — Import flight track data to auto-populate route and duration fields.
- **FAA IACRA Integration** — Streamline checkride application by pre-filling aeronautical experience from SoloTrack data.
- **Social/Community Features** — Training milestone sharing, flight school leaderboards.
- **Monetization** — Premium tier for advanced features (sync, additional certificates, PDF export) while keeping core logging free.

---

## 7. Technical Scalability

The current architecture supports growth in several dimensions:

| Dimension | Current State | Scalability Path |
|-----------|--------------|------------------|
| **Data model** | SwiftData with auto-migration | Add new `@Model` entities or properties with lightweight migration |
| **Business logic** | Stateless service structs | Add new services following the same pattern (e.g., `InstrumentCurrencyManager`) |
| **UI** | Token-based design system | Extend `AppTokens` for new screens; view modifiers ensure consistency |
| **Testing** | Swift Testing framework in place | Service layer is pure-function, highly testable without mocking |
| **Persistence** | Local SwiftData | CloudKit integration via `ModelConfiguration` swap |
| **Navigation** | TabView + NavigationStack | Add tabs or push destinations without restructuring |

### Architectural Constraints

- **Single-device data**: No sync mechanism means the app cannot scale to multi-device use without CloudKit or a custom backend.
- **No networking layer**: Any future integration (import, sync, API) requires building a network stack from scratch.
- **No monetization infrastructure**: No StoreKit integration, no paywall, no subscription management.
- **iOS only**: No macOS, iPadOS-optimized, or visionOS targets currently.
