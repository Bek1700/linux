import XCTest
@testable import NamazPause

final class PrayerCalculatorTests: XCTestCase {
    private let tashkent = TimeZone(identifier: "Asia/Tashkent")!
    private func day(_ y: Int, _ m: Int, _ d: Int, _ tz: TimeZone) -> Date {
        var c = Calendar(identifier: .gregorian); c.timeZone = tz
        return c.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    private func minutes(_ d: Date, _ tz: TimeZone) -> Int {
        var c = Calendar(identifier: .gregorian); c.timeZone = tz
        let x = c.dateComponents([.hour, .minute], from: d); return x.hour! * 60 + x.minute!
    }

    func testOrderingInTashkentSummer() throws {
        let t = try XCTUnwrap(PrayerCalculator.times(day: day(2026, 7, 29, tashkent), latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: .uzbekistan))
        XCTAssertLessThan(t.fajr, t.sunrise); XCTAssertLessThan(t.sunrise, t.dhuhr)
        XCTAssertLessThan(t.dhuhr, t.asr); XCTAssertLessThan(t.asr, t.maghrib); XCTAssertLessThan(t.maghrib, t.isha)
    }
    func testDhuhrTashkentJuly() throws {
        let t = try XCTUnwrap(PrayerCalculator.times(day: day(2026, 7, 29, tashkent), latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: .uzbekistan))
        XCTAssertEqual(minutes(t.dhuhr, tashkent), 12 * 60 + 29, accuracy: 3)
    }
    func testEquinoxAtGreenwichNoonIsAbout1207() throws {
        let utc = TimeZone(identifier: "UTC")!
        let t = try XCTUnwrap(PrayerCalculator.times(day: day(2026, 3, 20, utc), latitude: 0, longitude: 0, timeZone: utc, method: .mwl))
        XCTAssertEqual(minutes(t.dhuhr, utc), 12 * 60 + 7, accuracy: 3)
    }
    func testHanafiAsrIsLaterThanShafi() throws {
        let d = day(2026, 7, 29, tashkent)
        let h = try XCTUnwrap(PrayerCalculator.times(day: d, latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: .uzbekistan))
        var shafi = CalculationMethod.uzbekistan; shafi.asrFactor = 1
        let s = try XCTUnwrap(PrayerCalculator.times(day: d, latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: shafi))
        XCTAssertGreaterThan(h.asr, s.asr)
    }
    func testOffsetShiftsOnlyThatPrayer() throws {
        let d = day(2026, 7, 29, tashkent)
        var m = CalculationMethod.uzbekistan; m.offsets[.fajr] = 5
        let a = try XCTUnwrap(PrayerCalculator.times(day: d, latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: .uzbekistan))
        let b = try XCTUnwrap(PrayerCalculator.times(day: d, latitude: 41.31, longitude: 69.28, timeZone: tashkent, method: m))
        XCTAssertEqual(b.fajr.timeIntervalSince(a.fajr), 300, accuracy: 1)
        XCTAssertEqual(b.dhuhr, a.dhuhr)
    }
    func testPolarLatitudeReturnsNilInsteadOfCrashing() {
        let utc = TimeZone(identifier: "UTC")!
        XCTAssertNil(PrayerCalculator.times(day: day(2026, 6, 21, utc), latitude: 80, longitude: 0, timeZone: utc, method: .mwl))
    }
}
