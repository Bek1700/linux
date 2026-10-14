// Offline prayer-time calculator (solar position + twilight angles).
// Pure Foundation, no network. Angles are configurable because each
// religious board publishes its own calendar; verify against the official one.
import Foundation

enum Prayer: String, CaseIterable, Codable, Identifiable {
    case fajr, dhuhr, asr, maghrib, isha
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct CalculationMethod: Hashable {
    var name: String
    var fajrAngle: Double
    var ishaAngle: Double
    /// 1 = Shafi/Maliki/Hanbali, 2 = Hanafi
    var asrFactor: Double
    /// Minutes added to each prayer to match an official calendar.
    var offsets: [Prayer: Double] = [:]

    // Angles below are a starting point, not an authoritative copy of the boards' tables.
    static let kazakhstanDUMK = CalculationMethod(name: "Kazakhstan (DUMK)", fajrAngle: 18, ishaAngle: 17, asrFactor: 2)
    static let uzbekistan = CalculationMethod(name: "Uzbekistan (Muslim Board)", fajrAngle: 18, ishaAngle: 17, asrFactor: 2)
    static let mwl = CalculationMethod(name: "Muslim World League", fajrAngle: 18, ishaAngle: 17, asrFactor: 1)
}

struct DayPrayerTimes {
    let fajr, sunrise, dhuhr, asr, maghrib, isha: Date

    func time(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

enum PrayerCalculator {
    /// `day` is interpreted as a calendar date in `timeZone`.
    static func times(day: Date, latitude: Double, longitude: Double,
                      timeZone: TimeZone, method: CalculationMethod) -> DayPrayerTimes? {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        let c = local.dateComponents([.year, .month, .day], from: day)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let midnightUTC = utc.date(from: c) else { return nil }

        let jdNoon = midnightUTC.timeIntervalSince1970 / 86400 + 2440587.5 + 0.5
        let d = jdNoon - 2451545.0
        let g = rad(fix(357.529 + 0.98560028 * d, 360))
        let q = fix(280.459 + 0.98564736 * d, 360)
        let l = rad(fix(q + 1.915 * sin(g) + 0.020 * sin(2 * g), 360))
        let e = rad(23.439 - 0.00000036 * d)
        let ra = fix(deg(atan2(cos(e) * sin(l), cos(l))) / 15, 24)
        let decl = asin(sin(e) * sin(l))
        let eqt = q / 15 - ra
        let noon = 12 - longitude / 15 - eqt // hours, UTC

        let lat = rad(latitude)
        func hourAngle(_ altitudeDeg: Double) -> Double? {
            let v = (sin(rad(altitudeDeg)) - sin(lat) * sin(decl)) / (cos(lat) * cos(decl))
            guard abs(v) <= 1 else { return nil }
            return deg(acos(v)) / 15
        }
        let asrAlt = deg(atan(1 / (method.asrFactor + tan(abs(lat - decl)))))
        guard let tFajr = hourAngle(-method.fajrAngle),
              let tRise = hourAngle(-0.833),
              let tAsr = hourAngle(asrAlt),
              let tIsha = hourAngle(-method.ishaAngle) else { return nil }

        func date(_ hours: Double, _ p: Prayer?) -> Date {
            let off = p.flatMap { method.offsets[$0] } ?? 0
            return midnightUTC.addingTimeInterval(hours * 3600 + off * 60)
        }
        return DayPrayerTimes(
            fajr: date(noon - tFajr, .fajr), sunrise: date(noon - tRise, nil),
            dhuhr: date(noon, .dhuhr), asr: date(noon + tAsr, .asr),
            maghrib: date(noon + tRise, .maghrib), isha: date(noon + tIsha, .isha))
    }

    private static func rad(_ x: Double) -> Double { x * .pi / 180 }
    private static func deg(_ x: Double) -> Double { x * 180 / .pi }
    private static func fix(_ x: Double, _ m: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: m); return r < 0 ? r + m : r
    }
}
