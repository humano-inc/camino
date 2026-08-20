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

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for slot in current.slots where slot.includes(on: day, calendar: calendar) {
                if offset == 0 && confirmedToday.contains(slot.id) { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = slot.hour
                components.minute = slot.minute
                guard let fire = calendar.date(from: components), fire > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.body = CaminoFormat.pathAmount(
                    hour: slot.hour,
                    minute: slot.minute,
                    amount: slot.amountMg,
                    calendar: calendar
                )
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let id = "slot.\(slot.id.uuidString).\(calendar.startOfDay(for: day).timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    static func cancel(event: ScheduledEvent, calendar: Calendar) {
        let id = "slot.\(event.slotId.uuidString).\(calendar.startOfDay(for: event.dayStart).timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
