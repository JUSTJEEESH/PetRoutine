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

    func scheduleTaskNotification(for task: CareTask, petName: String) {
        guard task.notifyEnabled, task.isEnabled else { return }

        removeNotifications(for: task.id)

        for (index, time) in task.scheduledTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "\(petName) — \(task.name)"
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
