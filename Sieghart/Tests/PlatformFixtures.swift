import Foundation

// Integration checks never attach UserNotifications or EventKit platform services.
@MainActor private final class IsolatedCalendarReader: CalendarReading {
    var accessState: CalendarAccessState { .notDetermined }
    // Isolated previews must decline, not crash, when the Calendar tab asks for access.
    func requestAccess() async throws -> Bool { throw CocoaError(.userCancelled) }
    func load(from start: Date, to end: Date, selectedIDs: Set<String>?) -> CalendarSnapshot {
        CalendarSnapshot(events: [], calendars: [], fetchedAt: Date())
    }
}
@MainActor private final class IsolatedReminderNotifier: ReminderNotifying {
    func schedule(_ reminder: SieghartReminder, enabled: Bool, quietStart: Int, quietEnd: Int) async {}
    func cancel(_ id: UUID) {}
    func scheduleEvent(_ event: CalendarEventSummary, key: String, at due: Date, quietStart: Int, quietEnd: Int) async {}
    func cancelEvents(_ keys: Set<String>) {}
}
@MainActor enum IsolatedCalendarFixture {
    static func make(defaults: UserDefaults) -> CalendarViewModel {
        CalendarViewModel(reader: IsolatedCalendarReader(), notifier: IsolatedReminderNotifier(), defaults: defaults, observesSystem: false)
    }
}
