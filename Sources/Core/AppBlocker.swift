// Screen Time wrapper: authorization, shield on/off, and per-prayer DeviceActivity schedules.
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
final class AppBlocker: ObservableObject {
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    @Published var isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch { isAuthorized = false }
    }

    func unlock() { store.clearAllSettings() }

    func lockNow() {
        let s = SharedStore.selection
        store.shield.applications = s.applicationTokens
        store.shield.applicationCategories = .specific(s.categoryTokens)
        store.shield.webDomains = s.webDomainTokens
    }

    /// One monitored interval per prayer start. Intervals last until the next prayer (or 2 h for Isha).
    /// iOS allows about 20 schedules per app, so only the next days are registered.
    func schedule(_ days: [DayPrayerTimes], evening: Bool = false, calendar: Calendar = .current) {
        center.stopMonitoring()
        let now = Date()
        for (i, day) in days.enumerated() {
            if evening, i + 1 < days.count, day.isha > now {
                // Shield from Isha until the next Fajr; the extension lifts it in intervalDidEnd.
                let c: (Date) -> DateComponents = { calendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0) }
                let sch = DeviceActivitySchedule(intervalStart: c(day.isha), intervalEnd: c(days[i + 1].fajr), repeats: false)
                try? center.startMonitoring(DeviceActivityName("evening-\(Int(day.isha.timeIntervalSince1970))"), during: sch)
            }
            for p in Prayer.allCases {
                let start = day.time(for: p)
                guard start > now else { continue }
                let end = start.addingTimeInterval(2 * 3600)
                let comps: (Date) -> DateComponents = {
                    calendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
                }
                let schedule = DeviceActivitySchedule(intervalStart: comps(start), intervalEnd: comps(end), repeats: false)
                let name = DeviceActivityName("\(p.rawValue)-\(Int(start.timeIntervalSince1970))")
                try? center.startMonitoring(name, during: schedule)
            }
        }
    }
}
