import XCTest
@testable import RecipeApp

final class CookLogReminderSchedulerTests: XCTestCase {
    func test_fireDate_is90MinutesAfterEntryDate() {
        let entryDate = Date(timeIntervalSince1970: 1_700_000_000)

        let fireDate = CookLogReminderScheduler.fireDate(for: entryDate)

        XCTAssertEqual(fireDate.timeIntervalSince(entryDate), 90 * 60)
    }

    func test_fireDate_scalesWithReferenceDate() {
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = earlier.addingTimeInterval(3600)

        let earlierFireDate = CookLogReminderScheduler.fireDate(for: earlier)
        let laterFireDate = CookLogReminderScheduler.fireDate(for: later)

        XCTAssertEqual(laterFireDate.timeIntervalSince(earlierFireDate), 3600)
    }
}
