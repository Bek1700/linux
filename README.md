# Namaz Pause (iOS 26)

An original prayer-discipline app for iPhone: social apps pause during each prayer until you confirm,
a Fajr alarm you switch off with a camera proof, evening mode, offline prayer times, all on device.
It is inspired by the idea of apps like Niyyah AI; it copies none of their name, art or text.

## Status
Written without access to Xcode, so **it has not been compiled or run**. Expect to fix a few compiler
errors on first build. Only the prayer-time maths was checked (against a Python port).

## Build on a Mac
1. `brew install xcodegen`, then in this folder: `xcodegen`
2. Open `NamazPause.xcodeproj`, set your Team in both targets, change `com.example` bundle ids and the
   App Group (`group.com.example.namazpause`, also in `Sources/Core/SharedStore.swift`).
3. Run on the iPhone (Developer Mode on). A free Apple ID signs for 7 days.

## Things you must know
- **Screen Time (FamilyControls)**: development works with your own team; for the App Store, Apple must
  approve the Family Controls distribution entitlement. Without it, app blocking cannot ship.
- **Photo proof**: Apple's generic Vision labels will not reliably recognise a prayer mat. Train a small
  Core ML classifier and pass it as `ProofClassifying`. The "Checkmark" button is the fallback.
- **Prayer times**: angles in `CalculationMethod` are a starting point. Compare with the official
  Uzbekistan / DUMK calendar and tune `offsets` per prayer.
- **Fajr alarm**: AlarmKit cannot block "Stop"; the app schedules 6 alarms 2 minutes apart and cancels
  them after proof. Check the AlarmKit API names against your Xcode 26 SDK.
- Not done yet: Uzbek/Russian localisation, custom shield screen (ShieldConfiguration extension),
  subscription, widgets.
