# SoloTrack — App Store Connect web URL checklist

Use this page when filling out App Store Connect for SoloTrack. Every URL below resolves on the live site at <https://solo-track.com/>.

_Last updated: 2026-05-02_

## URLs to paste into App Store Connect

| Field | URL |
| --- | --- |
| Marketing URL | `https://solo-track.com/` |
| Privacy Policy URL | `https://solo-track.com/privacy/` |
| Terms of Use URL | `https://solo-track.com/terms/` |
| Support URL | `https://solo-track.com/support/` |
| Alternate Support URL (Contact page) | `https://solo-track.com/contact/` |
| EULA | Use Apple's Standard EULA, or replace `https://solo-track.com/terms/` if a custom EULA is preferred (legal review recommended) |
| Support email | `Contact@solo-track.com` |
| App Store URL | TODO — fill in after the App is published |

## Developer / publisher

- Legal entity: **Huggler Holdings LLC**
- Trade name shown to users: **SoloTrack**
- Support email: `Contact@solo-track.com`
- Mailing address: TODO — confirm postal address before submitting if Apple requires it

## App Privacy Nutrition Label — proposed disclosures

Based on the published product documentation, the current build:

- **Data Not Collected** — SoloTrack does not collect data linked to the user from the app itself, because it does not run a server and does not include third-party analytics, advertising, or tracking SDKs.
- **iCloud / CloudKit** — If the user enables iCloud sync, flights and templates are stored in the user's own iCloud account via Apple's CloudKit. This is not data collected by the developer; Apple operates the storage.
- **No third-party SDKs** — No Firebase, Supabase, RevenueCat, Superwall, ad networks, A/B testing, or attribution SDKs in the current build.

> ⚠️ **Confirm before each submission.** If any third-party SDK is added in a future build, update the Privacy Policy and the App Privacy Nutrition Label accordingly.

## Subscription / IAP status

- Current status: **Free for student pilots during the beta.** No in-app purchases or subscriptions are offered as of `2026-05-02`.
- Future: The Terms of Use note that paid features may be introduced in the future. Update this checklist and the Terms when that ships.

## Third-party SDK list (per current docs)

Apple frameworks only:

- SwiftData
- CloudKit (only when the user opts in to iCloud sync)
- WidgetKit
- ActivityKit
- App Intents
- PencilKit
- MapKit
- UserNotifications

No third-party SDKs are present.

## Data practices summary

- Local-first SwiftData store inside an App Group container on-device.
- Optional CloudKit sync covering only flights and templates.
- Onboarding state, custom airports, notification memory, and timer state stay device-local.
- No SoloTrack-operated server.
- No selling of personal information.
- No cross-app or cross-site tracking.
- Endorsed flights are locked to preserve integrity; can be voided.

## Outstanding TODOs

- [ ] Confirm mailing address for the publisher (if Apple or App Privacy disclosures require it).
- [ ] Confirm governing-law jurisdiction in `/terms/` (currently `[STATE]` placeholder).
- [ ] Confirm Apple Standard EULA vs custom EULA decision with legal counsel.
- [ ] Replace TODO App Store URL once the App is published.
- [ ] Re-verify before each App Store submission that no new third-party SDKs were added.
- [ ] If paid features ship, update `/terms/`, `/privacy/`, and the App Privacy Nutrition Label.

## Validation checklist

- [ ] `https://solo-track.com/privacy/` returns 200 and renders.
- [ ] `https://solo-track.com/terms/` returns 200 and renders.
- [ ] `https://solo-track.com/contact/` returns 200 and renders, with a working `mailto:` link.
- [ ] `https://solo-track.com/support/` returns 200 and renders.
- [ ] `https://solo-track.com/sitemap.xml` and `https://solo-track.com/robots.txt` return 200.
- [ ] Each page has a unique `<title>`, meta description, and canonical pointing at the apex domain.
- [ ] Apple Standard EULA reference present in `/terms/`.
- [ ] No `[PLACEHOLDER]` text remains on any public-facing page (TODOs are scoped to this internal doc and to clearly marked legal placeholders).
