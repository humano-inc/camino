import Foundation
import UserNotifications

@MainActor
enum ReminderScheduler {
    static func requestAndSchedule(journey: Journey?, calendar: Calendar) async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        if let journey {
            await reschedule(journey: journey, calendar: calendar)
        }
    }

    static func areDenied() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .denied: return true
        default: return false
        }
    }

    static func reschedule(journey: Journey, calendar: Calendar) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !journey.isArrived, let current = journey.currentProtocol else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let today = calendar.startOfDay(for: Date())
        let confirmedToday = Set(
            journey.events
                .filter { $0.isConfirmed && calendar.isDate($0.dayStart, inSameDayAs: today) }
                .map(\.slotId)
        )

        var scheduled = Set<String>()
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for slot in current.slots where slot.includes(on: day, calendar: calendar) {
                if offset == 0 && confirmedToday.contains(slot.id) { continue }
                let id = await add(
                    to: center,
                    day: day,
                    hour: slot.hour,
                    minute: slot.minute,
                    amountMg: slot.amountMg,
                    slotId: slot.id,
                    calendar: calendar
                )
                if let id { scheduled.insert(id) }
            }
        }

        // A delayed dose can land on a night outside the rhythm; its open
        // step still deserves the reminder.
        guard let horizon = calendar.date(byAdding: .day, value: 14, to: today) else { return }
        for event in journey.events where event.isOpen {
            let day = calendar.startOfDay(for: event.dayStart)
            guard day >= today, day < horizon else { continue }
            let id = "slot.\(event.slotId.uuidString).\(day.timeIntervalSince1970)"
            guard !scheduled.contains(id) else { continue }
            _ = await add(
                to: center,
                day: day,
                hour: event.hour,
                minute: event.minute,
                amountMg: event.plannedAmountMg,
                slotId: event.slotId,
                calendar: calendar
            )
        }
    }

    private static func add(
        to center: UNUserNotificationCenter,
        day: Date,
        hour: Int,
        minute: Int,
        amountMg: Double,
        slotId: UUID,
        calendar: Calendar
    ) async -> String? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        guard let fire = calendar.date(from: components), fire > Date() else { return nil }

        let content = UNMutableNotificationContent()
        content.body = CaminoFormat.pathAmount(
            hour: hour,
            minute: minute,
            amount: amountMg,
            calendar: calendar
        )
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = "slot.\(slotId.uuidString).\(calendar.startOfDay(for: day).timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
        return id
    }

    static func cancel(event: ScheduledEvent, calendar: Calendar) {
        let id = "slot.\(event.slotId.uuidString).\(calendar.startOfDay(for: event.dayStart).timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
