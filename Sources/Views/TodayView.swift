import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: PrayerStore
    @EnvironmentObject var blocker: AppBlocker
    @State private var proofFor: Prayer?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                ScrollView {
                    VStack(spacing: 16) {
                        header(ctx.date)
                        ForEach(Prayer.allCases) { row($0, now: ctx.date) }
                    }.padding()
                }
            }
            .navigationTitle("Assalamu alaikum")
            .fullScreenCover(item: $proofFor) { p in
                ProofCameraView(title: "Confirm \(p.title) with a photo") { confirm(p) }
            }
        }
    }

    private func header(_ now: Date) -> some View {
        let next = store.nextPrayer(at: now)
        let locked = store.pendingPrayer(at: now)
        return VStack(spacing: 6) {
            Text(locked.map { "Now · \($0.title)" } ?? "Next · \(next?.0.title ?? "-")").font(.caption.bold())
            Text(countdown(to: next?.1 ?? now, now: now)).font(.system(size: 54, weight: .heavy, design: .rounded)).monospacedDigit()
            if locked != nil { Label("Social apps locked", systemImage: "lock.fill").font(.caption) }
            Text("Streak · \(store.streak) days").font(.caption)
        }
        .frame(maxWidth: .infinity).padding(24)
        .background(.orange.gradient.opacity(0.3), in: RoundedRectangle(cornerRadius: 24))
    }

    private func row(_ p: Prayer, now: Date) -> some View {
        let t = store.today?.time(for: p)
        let done = store.isDone(p)
        let open = store.pendingPrayer(at: now) == p
        return HStack {
            Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundStyle(done ? .green : .secondary)
            VStack(alignment: .leading) {
                Text(p.title).bold()
                Text(t.map { $0.formatted(.dateTime.hour().minute().timeZone(.omitted)) } ?? "--:--")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if open { Button("I prayed") { proofFor = p }.buttonStyle(.borderedProminent) }
            else { Text(done ? "Done" : "Pending").font(.caption).foregroundStyle(.secondary) }
        }
        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func confirm(_ p: Prayer) {
        store.confirm(p)
        if !store.shouldLock() { blocker.unlock() }
    }

    private func countdown(to d: Date, now: Date) -> String {
        let s = max(0, Int(d.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
    }
}
