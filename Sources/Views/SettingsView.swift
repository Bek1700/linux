import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var store: PrayerStore
    @EnvironmentObject var blocker: AppBlocker
    @EnvironmentObject var alarm: FajrAlarm
    @State private var picking = false
    @State private var selection = SharedStore.selection
    @State private var eveningMode = UserDefaults.standard.bool(forKey: "evening")

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("City", selection: $store.city) { ForEach(City.all) { Text($0.name).tag($0) } }
                    Button("Use my location") { store.useLocation() }
                    Picker("Method", selection: $store.method) {
                        Text("Uzbekistan").tag(CalculationMethod.uzbekistan)
                        Text("Kazakhstan (DUMK)").tag(CalculationMethod.kazakhstanDUMK)
                        Text("Muslim World League").tag(CalculationMethod.mwl)
                    }
                }
                Section("Apps paused during prayer") {
                    if !blocker.isAuthorized { Button("Allow Screen Time access") { Task { await blocker.requestAuthorization() } } }
                    Button("Choose apps") { picking = true }.disabled(!blocker.isAuthorized)
                    Toggle("Evening mode (Isha → Fajr)", isOn: $eveningMode)
                        .onChange(of: eveningMode) { _, v in UserDefaults.standard.set(v, forKey: "evening") }
                }
                Section("Fajr alarm") {
                    Toggle("Enabled", isOn: $alarm.enabled)
                    Stepper("Offset: \(alarm.offsetMinutes) min", value: $alarm.offsetMinutes, in: -60...60, step: 5)
                }
                Section { Text("Everything runs on this device. No account, no analytics.").font(.footnote) }
            }
            .navigationTitle("More")
            .familyActivityPicker(isPresented: $picking, selection: $selection)
            .onChange(of: selection) { _, s in SharedStore.selection = s }
        }
    }
}
