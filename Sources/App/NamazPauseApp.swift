import SwiftUI

@main
struct NamazPauseApp: App {
    @StateObject private var store = PrayerStore()
    @StateObject private var blocker = AppBlocker()
    @StateObject private var alarm = FajrAlarm()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store).environmentObject(blocker).environmentObject(alarm)
                .task { await resync() }
                .onChange(of: phase) { _, p in if p == .active { Task { await resync() } } }
        }
    }

    /// Re-register monitors and alarms; lock again if a prayer window is open and unconfirmed.
    private func resync() async {
        store.refresh()
        guard blocker.isAuthorized else { return }
        blocker.schedule([store.times(), store.times(daysFromToday: 1)].compactMap { $0 }, evening: store.eveningMode)
        if store.shouldLock() { blocker.lockNow() } else { blocker.unlock() }
        if let next = store.times(daysFromToday: Date() < (store.today?.fajr ?? .distantPast) ? 0 : 1)?.fajr {
            await alarm.schedule(fajr: next)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "moon.stars") }
            StatsView().tabItem { Label("Stats", systemImage: "chart.bar") }
            SettingsView().tabItem { Label("More", systemImage: "gearshape") }
        }
    }
}
