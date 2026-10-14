import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: PrayerStore
    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Streak", value: "\(store.streak) days")
                LabeledContent("Last 7 days", value: "\(Int(store.completion(days: 7) * 100))%")
                LabeledContent("Last 30 days", value: "\(Int(store.completion(days: 30) * 100))%")
            }.navigationTitle("Stats")
        }
    }
}
