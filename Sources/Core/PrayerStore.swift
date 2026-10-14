// App state: location, today's times, confirmations and streak. Everything stays on device.
import Foundation
import CoreLocation

struct City: Identifiable, Hashable {
    let name: String, lat: Double, lng: Double, tz: String
    var id: String { name }
    static let all = [
        City(name: "Tashkent", lat: 41.3111, lng: 69.2797, tz: "Asia/Tashkent"),
        City(name: "Samarkand", lat: 39.6542, lng: 66.9597, tz: "Asia/Samarkand"),
        City(name: "Almaty", lat: 43.2389, lng: 76.8897, tz: "Asia/Almaty"),
        City(name: "Astana", lat: 51.1605, lng: 71.4704, tz: "Asia/Almaty"),
    ]
}

@MainActor
final class PrayerStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var city: City = City.all[0] { didSet { save(); refresh() } }
    @Published var method: CalculationMethod = .uzbekistan { didSet { refresh() } }
    @Published private(set) var today: DayPrayerTimes?
    @Published private(set) var confirmations: [String: [String: Date]] = [:]
    private let manager = CLLocationManager()
    private let key = "confirmations"

    override init() {
        super.init()
        if let d = UserDefaults.standard.data(forKey: key),
           let v = try? JSONDecoder().decode([String: [String: Date]].self, from: d) { confirmations = v }
        if let n = UserDefaults.standard.string(forKey: "city"), let c = City.all.first(where: { $0.name == n }) { city = c }
        manager.delegate = self
        refresh()
    }

    func useLocation() { manager.requestWhenInUseAuthorization(); manager.requestLocation() }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations l: [CLLocation]) {
        guard let loc = l.last else { return }
        Task { @MainActor in
            self.city = City(name: "Current", lat: loc.coordinate.latitude, lng: loc.coordinate.longitude, tz: TimeZone.current.identifier)
        }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {}

    var timeZone: TimeZone { TimeZone(identifier: city.tz) ?? .current }

    func times(daysFromToday n: Int = 0) -> DayPrayerTimes? {
        let day = Calendar.current.date(byAdding: .day, value: n, to: Date())!
        return PrayerCalculator.times(day: day, latitude: city.lat, longitude: city.lng, timeZone: timeZone, method: method)
    }

    func refresh() { today = times() }

    // MARK: status

    private func dayKey(_ d: Date = Date()) -> String {
        var c = Calendar(identifier: .gregorian); c.timeZone = timeZone
        let x = c.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", x.year!, x.month!, x.day!)
    }

    func isDone(_ p: Prayer) -> Bool { confirmations[dayKey()]?[p.rawValue] != nil }
    var doneCount: Int { Prayer.allCases.filter(isDone).count }

    /// The prayer whose window is open now: started, not yet confirmed, and before the next one starts.
    func current(at now: Date = Date()) -> Prayer? {
        guard let t = today else { return nil }
        let all = Prayer.allCases
        for (i, p) in all.enumerated().reversed() where t.time(for: p) <= now {
            let end = i + 1 < all.count ? t.time(for: all[i + 1]) : t.fajr.addingTimeInterval(86400)
            return now < end ? p : nil
        }
        return nil
    }

    /// The prayer that should be blocking apps right now, if any.
    func pendingPrayer(at now: Date = Date()) -> Prayer? {
        guard let p = current(at: now), !isDone(p) else { return nil }
        return p
    }

    var eveningMode: Bool { UserDefaults.standard.bool(forKey: "evening") }

    /// True when apps must be shielded: an unconfirmed prayer window, or evening mode (Isha until Fajr).
    func shouldLock(at now: Date = Date()) -> Bool {
        if pendingPrayer(at: now) != nil { return true }
        guard eveningMode, let t = today else { return false }
        return now >= t.isha || now < t.fajr
    }

    func nextPrayer(at now: Date = Date()) -> (Prayer, Date)? {
        guard let t = today, let tomorrow = times(daysFromToday: 1) else { return nil }
        if let p = Prayer.allCases.first(where: { t.time(for: $0) > now }) { return (p, t.time(for: p)) }
        return (.fajr, tomorrow.fajr)
    }

    func confirm(_ p: Prayer) {
        confirmations[dayKey(), default: [:]][p.rawValue] = Date()
        save()
    }

    var streak: Int {
        var n = 0
        var date = Date()
        if doneCount < 5 { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! }
        while let day = confirmations[dayKey(date)], day.count == 5 {
            n += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return n
    }

    /// Fraction of confirmed prayers over the last `days` days (today included).
    func completion(days: Int) -> Double {
        let total = days * 5
        var done = 0
        for i in 0..<days {
            let d = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            done += confirmations[dayKey(d)]?.count ?? 0
        }
        return Double(done) / Double(total)
    }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(confirmations), forKey: key)
        UserDefaults.standard.set(city.name, forKey: "city")
    }
}
