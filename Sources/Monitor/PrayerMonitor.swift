// DeviceActivity extension: iOS wakes it at each prayer start, even when the app is closed,
// and it shields the chosen apps. The main app lifts the shield after the user confirms.
import DeviceActivity
import ManagedSettings

final class PrayerMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        let s = SharedStore.selection
        store.shield.applications = s.applicationTokens
        store.shield.applicationCategories = .specific(s.categoryTokens)
        store.shield.webDomains = s.webDomainTokens
    }
    // Prayer intervals keep the shield until the user confirms in the app;
    // only the evening interval lifts it by itself at Fajr.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity.rawValue.hasPrefix("evening-") { store.clearAllSettings() }
    }
}
