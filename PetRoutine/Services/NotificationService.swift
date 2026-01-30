import UserNotifications
import Foundation

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Task Notifications

    func scheduleTaskNotifications(for task: CareTask) {
        guard task.notifyEnabled, task.isEnabled else { return }

        removeNotifications(for: task.id)

        for (index, time) in task.scheduledTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = task.name
            content.body = task.notes ?? taskBody(for: task.taskType)
            content.sound = .default
            content.categoryIdentifier = "CARE_TASK"
            content.userInfo = ["taskID": task.id.uuidString]

            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.hour, .minute], from: time)

            let trigger: UNNotificationTrigger

            switch task.frequencyType {
            case .daily:
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            case .weekly:
                if let dayString = task.frequencyValue,
                   let weekday = Int(dayString) {
                    dateComponents.weekday = weekday
                }
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            case .custom:
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            }

            let identifier = "\(task.id.uuidString)-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }

    func removeNotifications(for taskID: UUID) {
        let prefix = taskID.uuidString
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    // MARK: - Health Record Reminders

    func scheduleHealthReminder(for record: HealthRecord) {
        guard record.reminderEnabled, let dueDate = record.nextDueDate else { return }

        removeHealthReminder(for: record.id)

        let twoWeeksBefore = Calendar.current.date(byAdding: .day, value: -14, to: dueDate) ?? dueDate
        scheduleHealthNotification(
            id: "\(record.id.uuidString)-2w",
            title: "Upcoming: \(record.name)",
            body: "Due in 2 weeks (\(dueDate.shortDateString))",
            date: twoWeeksBefore
        )

        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        scheduleHealthNotification(
            id: "\(record.id.uuidString)-1d",
            title: "\(record.name) due tomorrow",
            body: "Scheduled for \(dueDate.shortDateString)",
            date: dayBefore
        )

        scheduleHealthNotification(
            id: "\(record.id.uuidString)-due",
            title: "\(record.name) is due today",
            body: "Don't forget to schedule this.",
            date: dueDate
        )
    }

    func removeHealthReminder(for recordID: UUID) {
        let prefix = recordID.uuidString
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    private func scheduleHealthNotification(id: String, title: String, body: String, date: Date) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "HEALTH_RECORD"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Failed to schedule health notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Utilities

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    private func taskBody(for type: TaskType) -> String {
        switch type {
        case .feeding: "Time to feed!"
        case .walk: "Time for a walk!"
        case .medication: "Medication reminder"
        case .grooming: "Grooming time"
        case .custom: "Task reminder"
        }
    }
}
