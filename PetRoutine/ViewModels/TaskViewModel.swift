import CoreData
import SwiftUI

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [CareTask] = []
    @Published var todayCompletions: [UUID: [TaskCompletion]] = [:]

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func fetchTasks(for petID: UUID) {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "pet.id == %@", petID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCareTask.createdAt, ascending: true)]

        do {
            let results = try context.fetch(request)
            tasks = results.map { $0.toCareTask() }
            fetchTodayCompletions()
        } catch {
            print("Fetch tasks error: \(error.localizedDescription)")
        }
    }

    func fetchTodayCompletions() {
        let context = persistence.container.viewContext
        let startOfDay = Date().startOfDay
        let endOfDay = Date().endOfDay

        var completionsMap: [UUID: [TaskCompletion]] = [:]

        for task in tasks {
            let request = CDTaskCompletion.fetchRequest()
            request.predicate = NSPredicate(
                format: "careTask.id == %@ AND completedAt >= %@ AND completedAt <= %@",
                task.id as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTaskCompletion.completedAt, ascending: false)]

            do {
                let results = try context.fetch(request)
                completionsMap[task.id] = results.map { $0.toTaskCompletion() }
            } catch {
                print("Fetch completions error: \(error.localizedDescription)")
            }
        }

        todayCompletions = completionsMap
    }

    func addTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let cdTask = CDCareTask(context: context)
        cdTask.update(from: task, in: context)
        persistence.save()

        if let petID = task.petID {
            fetchTasks(for: petID)

            if task.notifyEnabled {
                let petName = petNameFor(petID: petID)
                NotificationService.shared.scheduleTaskNotification(for: task, petName: petName)
            }
        }
    }

    func updateTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let cdTask = try context.fetch(request).first {
                cdTask.update(from: task, in: context)
                persistence.save()

                if let petID = task.petID {
                    fetchTasks(for: petID)

                    let petName = petNameFor(petID: petID)
                    if task.notifyEnabled && task.isEnabled {
                        NotificationService.shared.scheduleTaskNotification(for: task, petName: petName)
                    } else {
                        NotificationService.shared.removeNotifications(for: task.id)
                    }
                }
            }
        } catch {
            print("Update task error: \(error.localizedDescription)")
        }
    }

    func deleteTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let cdTask = try context.fetch(request).first {
                context.delete(cdTask)
                persistence.save()
                NotificationService.shared.removeNotifications(for: task.id)
                if let petID = task.petID {
                    fetchTasks(for: petID)
                }
            }
        } catch {
            print("Delete task error: \(error.localizedDescription)")
        }
    }

    func completeTask(_ task: CareTask, caregiverName: String = "Me") {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            if let cdTask = try context.fetch(request).first {
                let completion = CDTaskCompletion(context: context)
                completion.id = UUID()
                completion.completedAt = Date()
                completion.caregiverName = caregiverName
                completion.careTask = cdTask
                persistence.save()
                fetchTodayCompletions()
            }
        } catch {
            print("Complete task error: \(error.localizedDescription)")
        }
    }

    func undoCompletion(for task: CareTask) {
        let context = persistence.container.viewContext
        let startOfDay = Date().startOfDay
        let endOfDay = Date().endOfDay

        let request = CDTaskCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "careTask.id == %@ AND completedAt >= %@ AND completedAt <= %@",
            task.id as CVarArg,
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTaskCompletion.completedAt, ascending: false)]
        request.fetchLimit = 1

        do {
            if let latest = try context.fetch(request).first {
                context.delete(latest)
                persistence.save()
                fetchTodayCompletions()
            }
        } catch {
            print("Undo completion error: \(error.localizedDescription)")
        }
    }

    func isCompletedToday(_ task: CareTask) -> Bool {
        guard let completions = todayCompletions[task.id] else { return false }
        return !completions.isEmpty
    }

    func todayTasksSummary(for petID: UUID) -> (completed: Int, total: Int) {
        let enabledTasks = tasks.filter { $0.isEnabled && shouldShowToday($0) }
        let completedCount = enabledTasks.filter { isCompletedToday($0) }.count
        return (completedCount, enabledTasks.count)
    }

    func shouldShowToday(_ task: CareTask) -> Bool {
        guard task.isEnabled else { return false }

        switch task.frequencyType {
        case .daily:
            return true
        case .weekly:
            if let dayString = task.frequencyValue,
               let weekday = Int(dayString) {
                return Date().dayOfWeek == weekday
            }
            return true
        case .custom:
            return true
        }
    }

    func completionHistory(for task: CareTask, limit: Int = 30) -> [TaskCompletion] {
        let context = persistence.container.viewContext
        let request = CDTaskCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "careTask.id == %@", task.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTaskCompletion.completedAt, ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request).map { $0.toTaskCompletion() }
        } catch {
            print("Fetch history error: \(error.localizedDescription)")
            return []
        }
    }

    private func petNameFor(petID: UUID) -> String {
        let context = persistence.container.viewContext
        let request = CDPet.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
        return (try? context.fetch(request).first?.name) ?? "Pet"
    }
}
