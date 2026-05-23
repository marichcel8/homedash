# App Store Review Notes – HomeDash

> Diesen Text **wortwörtlich** in App Store Connect → App-Information →
> *Review Information → Notes* einfügen. Für HomeKit-/Apple-Home-Apps sind
> Review Notes praktisch Pflicht, sonst hohe Reject-Quote.

---

## App Review Information

**App Name:** HomeDash
**Bundle ID:** de.marcel.homedash
**Version:** 1.0.0
**Build:** 1
**Platform:** tvOS 17.0+
**Category:** Lifestyle (primary), Utilities (secondary)

## What does the app do?

HomeDash is a tvOS dashboard for Apple Home. It shows all your rooms and
accessories on a large-screen layout, lets you toggle devices, dim lights,
change colors, adjust thermostats, lock doors, and run scenes — entirely from
the Apple TV using the Siri Remote.

All data stays on-device. No analytics, no network calls outside HomeKit.

## How to test the app

**Important:** HomeDash requires a configured Apple Home with at least one
accessory. Without accessories, the app shows an empty-state screen
("No accessories yet").

### Recommended setup for review

1. **Sign in** the Apple TV with an iCloud account that has Apple Home set up
   (Settings → Users and Accounts).
2. **Grant Apple Home access** on first launch:
   Settings → Apps → HomeDash → Apple Home = On.
   Note: tvOS does not show a modal permission prompt; the user must enable it
   in Settings. The app guides users to this screen.
3. **Launch HomeDash**. The dashboard renders rooms and accessories.

### If the reviewer cannot configure a real Apple Home

- The **empty-state UI** demonstrates the loading and onboarding flow.
- The **permission screen** demonstrates how the app instructs the user.
- A **30-second demo video** with a populated home is attached as
  App Preview (or available on request via the contact email below).

### Interaction patterns

- **Click (Select button)**: toggles a device on/off, or runs a scene.
- **Long-press Select**: opens the device detail sheet with sliders for
  brightness, color picker, thermostat target, etc.
- **Play/Pause**: shortcut to open the detail sheet.
- **Menu**: refreshes the dashboard.

## Privacy

- Privacy Manifest (`PrivacyInfo.xcprivacy`) is included.
- App does not collect user data.
- App does not track users.
- App does not use IDFA.
- Required Reason API: `UserDefaults` (Reason CA92.1) for storing locally
  pinned favorites.
- Only HomeKit framework calls; no outbound network requests.

## Marketing references

The app uses "Apple Home" as the user-facing brand and "HomeKit" only as a
technical framework reference where appropriate. The app **does not** use the
"Works with Apple Home" badge or claim certification.

## Contact

If anything is unclear or the build needs additional context:

- **Email:** marsoen@outlook.de
- **Support page:** https://marichcel8.github.io/homedash/support.html

Thank you for the review.
