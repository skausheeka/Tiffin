import Foundation

enum CalendarWeek {
    /// The 7 days (Sunday–Saturday, or whatever the calendar's first weekday is) of the
    /// week containing `date` — a calendar-aligned range, not a rolling window. Which
    /// week is shown first is controlled by the reference date passed in, not by this
    /// function, so "today's week" is simply the result of passing today.
    static func days(containing date: Date, calendar: Calendar = .current) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [date] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }
}
