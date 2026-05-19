# SoloTrack — App Store Connect web URL checklist

Use this page when filling out App Store Connect for SoloTrack. Every URL below resolves on the live site at <https://www.solo-track.com/>.

_Last updated: 2026-05-18_

## URLs to paste into App Store Connect

| Field | URL |
| --- | --- |
| Marketing URL | `https://www.solo-track.com/` |
| Privacy Policy URL | `https://www.solo-track.com/privacy/` |
| Terms of Use URL | `https://www.solo-track.com/terms/` |
| Support URL | `https://www.solo-track.com/support/` |
| Alternate Support URL (Contact page) | `https://www.solo-track.com/contact/` |
| EULA | Use Apple's Standard EULA, or replace `https://www.solo-track.com/terms/` if a custom EULA is preferred (legal review recommended) |
| Support email | `Contact@solo-track.com` |
| App Store URL | TODO — fill in after the App is published |

## Developer / publisher

- Legal entity: **Huggler Holdings LLC**
- Trade name shown to users: **SoloTrack**
- Support email: `Contact@solo-track.com`
- Mailing address: no public postal address is published on the website; provide the business mailing address privately in App Store Connect or to regulators if Apple requests it

## App Privacy Nutrition Label — proposed disclosures

Based on the published product documentation, the current build should disclose:

- **Purchases → Purchase History** — used for App Functionality and Analytics. RevenueCat and Apple process purchase, trial, renewal, cancellation, and restore status for SoloTrack Pro subscriptions. If SoloTrack continues using anonymous RevenueCat app user IDs and does not map them to an app account, email, or custom user ID, mark Purchase History **not linked to user identity**.
- **Identifiers → User ID / Device ID** — add only if the final build or RevenueCat configuration uses custom app user IDs, IDFA, or another identifier Apple/RevenueCat requires disclosed.
- **Usage Data → Product Interaction** — add only if the final RevenueCat configuration or app instrumentation records purchase-related product interactions that Apple/RevenueCat requires disclosed.
- **iCloud / CloudKit** — If the user enables iCloud sync, flights and templates are stored in the user's own iCloud account via Apple's CloudKit. This is not data collected by the developer; Apple operates the storage.
- **No Tracking** — SoloTrack does not use data to track users across apps or websites owned by other companies.

> Confirm before each submission that App Store Connect App Privacy answers match the shipped SDK set and RevenueCat configuration.

## Subscription / IAP status

- Current status: **Free to download with SoloTrack Pro subscriptions / in-app purchases for full access or premium features.** Purchases are processed by Apple under the user's Apple ID and managed through RevenueCat.
- App Store metadata, paywall copy, Privacy Policy, and Terms should all disclose subscription auto-renewal, cancellation through Apple ID Subscriptions, Apple refund handling, and RevenueCat purchase processing.

## Third-party SDK list (per current docs)

Apple frameworks and RevenueCat:

- SwiftData
- CloudKit (only when the user opts in to iCloud sync)
- WidgetKit
- ActivityKit
- App Intents
- PencilKit
- MapKit
- UserNotifications
- StoreKit / App Store purchase APIs
- RevenueCat

RevenueCat is the only disclosed non-Apple SDK in the app. No advertising, tracking, A/B testing, Firebase/Supabase, Superwall, or third-party crash-reporting SDKs are disclosed.

## Data practices summary

- Local-first SwiftData store inside an App Group container on-device.
- Optional CloudKit sync covering only flights and templates.
- Onboarding state, custom airports, notification memory, and timer state stay device-local.
- No SoloTrack-operated server.
- No selling of personal information.
- No cross-app or cross-site tracking.
- RevenueCat purchase history for subscription functionality and analytics, without cross-app/cross-site tracking.
- Endorsed flights are locked to preserve integrity; can be voided.

## Outstanding TODOs

- [ ] Legal owner/counsel should review final `/terms/` wording before submission.
- [ ] Confirm Apple Standard EULA vs custom EULA decision with legal counsel.
- [ ] Replace TODO App Store URL once the App is published.
- [ ] Re-verify before each App Store submission that third-party SDK disclosures match the shipped build.
- [ ] Confirm App Store Connect App Privacy includes RevenueCat Purchase History and only includes Identifiers/Product Interaction if the final build or RevenueCat configuration requires them.

## Validation checklist

- [ ] `https://www.solo-track.com/privacy/` returns 200 and renders.
- [ ] `https://www.solo-track.com/terms/` returns 200 and renders.
- [ ] `https://www.solo-track.com/contact/` returns 200 and renders, with a working `mailto:` link.
- [ ] `https://www.solo-track.com/support/` returns 200 and renders.
- [ ] `https://www.solo-track.com/sitemap.xml` and `https://www.solo-track.com/robots.txt` return 200.
- [ ] Each page has a unique `<title>`, meta description, and canonical pointing at the `www.solo-track.com` domain.
- [ ] Apple Standard EULA reference present in `/terms/`.
- [ ] No `[PLACEHOLDER]` text remains on any public-facing page (TODOs are scoped to this internal doc and to clearly marked legal placeholders).
