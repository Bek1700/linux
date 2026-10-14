// Fajr alarm built on AlarmKit (iOS 26): rings through Silent mode and Focus.
// "Keeps ringing" is done with a chain of alarms every 2 minutes, all cancelled after photo proof.
import Foundation
import AlarmKit
import SwiftUI

struct FajrMetadata: AlarmMetadata {}

@MainActor
final class FajrAlarm: ObservableObject {
    @Published var enabled = UserDefaults.standard.bool(forKey: "fajrAlarm") { didSet { UserDefaults.standard.set(enabled, forKey: "fajrAlarm") } }
    @Published var offsetMinutes = UserDefaults.standard.integer(forKey: "fajrOffset") { didSet { UserDefaults.standard.set(offsetMinutes, forKey: "fajrOffset") } }
    private var ids: [UUID] {
        get { (UserDefaults.standard.stringArray(forKey: "fajrAlarmIDs") ?? []).compactMap(UUID.init) }
        set { UserDefaults.standard.set(newValue.map(\.uuidString), forKey: "fajrAlarmIDs") }
    }

    func schedule(fajr: Date) async {
        await cancelAll()
        guard enabled else { return }
        guard (try? await AlarmManager.shared.requestAuthorization()) == .authorized else { return }
        let first = fajr.addingTimeInterval(Double(offsetMinutes) * 60)
        for i in 0..<6 where first.addingTimeInterval(Double(i) * 120) > Date() {
            let when = first.addingTimeInterval(Double(i) * 120)
            let alert = AlarmPresentation.Alert(
                title: "Fajr",
                stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle"))
            let attrs = AlarmAttributes<FajrMetadata>(presentation: AlarmPresentation(alert: alert), tintColor: .green)
            let cfg = AlarmManager.AlarmConfiguration.alarm(schedule: .fixed(when), attributes: attrs)
            let id = UUID()
            if (try? await AlarmManager.shared.schedule(id: id, configuration: cfg)) != nil { ids.append(id) }
        }
    }

    /// Call after the wake-up photo is accepted.
    func cancelAll() async {
        for id in ids { try? AlarmManager.shared.cancel(id: id) }
        ids.removeAll()
    }
}
