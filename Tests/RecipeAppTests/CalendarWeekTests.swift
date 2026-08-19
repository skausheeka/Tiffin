import XCTest
@testable import RecipeApp

final class CalendarWeekTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func test_days_returnsSevenDays() {
        let reference = Date(timeIntervalSince1970: 1_755_500_000) // arbitrary date
        let days = CalendarWeek.days(containing: reference, calendar: calendar)

        XCTAssertEqual(days.count, 7)
    }

    func test_days_includesReferenceDate() {
        let reference = Date(timeIntervalSince1970: 1_755_500_000)
        let days = CalendarWeek.days(containing: reference, calendar: calendar)

        XCTAssertTrue(days.contains { calendar.isDate($0, inSameDayAs: reference) })
    }

    func test_days_firstDayMatchesWeekIntervalStart() throws {
        let reference = Date(timeIntervalSince1970: 1_755_500_000)
        let interval = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: reference))
        let days = CalendarWeek.days(containing: reference, calendar: calendar)

        XCTAssertEqual(days.first, interval.start)
    }

    func test_days_areConsecutiveCalendarDays() {
        let reference = Date(timeIntervalSince1970: 1_755_500_000)
        let days = CalendarWeek.days(containing: reference, calendar: calendar)

        for (previous, next) in zip(days, days.dropFirst()) {
            let expectedNext = calendar.date(byAdding: .day, value: 1, to: previous)
            XCTAssertEqual(next, expectedNext)
        }
    }

    func test_days_anyDayInSameWeekProducesSameWindow() {
        let monday = Date(timeIntervalSince1970: 1_755_500_000)
        guard let friday = calendar.date(byAdding: .day, value: 3, to: monday) else {
            return XCTFail("Could not construct a later date")
        }

        let daysFromMonday = CalendarWeek.days(containing: monday, calendar: calendar)
        let daysFromFriday = CalendarWeek.days(containing: friday, calendar: calendar)

        // Calendar-aligned: any reference date within the same week snaps to the same
        // Sunday–Saturday (or locale-equivalent) window.
        XCTAssertEqual(daysFromMonday, daysFromFriday)
    }

    func test_days_differentWeeksProduceDifferentWindows() {
        let reference = Date(timeIntervalSince1970: 1_755_500_000)
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: reference) else {
            return XCTFail("Could not construct a later date")
        }

        let daysThisWeek = CalendarWeek.days(containing: reference, calendar: calendar)
        let daysNextWeek = CalendarWeek.days(containing: nextWeek, calendar: calendar)

        XCTAssertNotEqual(daysThisWeek, daysNextWeek)
    }
}
