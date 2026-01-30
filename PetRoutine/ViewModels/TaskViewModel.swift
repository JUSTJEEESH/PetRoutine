import CoreData
import SwiftUI

struct TimeBlock: Identifiable {
    let id: String
    let time: Date?
    let label: String
    var tasks: [CareTask]
}

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var allTasks: [CareTask] = []
    @Published var completedPairs: [UUID: Set<UUID>] = [:]

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var todayTasks: [CareTask] {
        allTasks.filter { $0.shouldShowToday() }
    }

    func timeBlocks(filterPetID: UUID? = nil) -> [TimeBlock] {
        var tasks = todayTasks
        if let petID = filterPetID {
            tasks = tasks.filter { $0.petIDs.contains(petID) }
        }

        var groups: [String: (time: Date?, tasks: [CareTask])] = [:]

        for task in tasks {
            let key: String
            let time: Date?
            if let earliest = task.earliestTime {
                let cal = Calendar.current
                let h = cal.component(.hour, from: earliest)
                let m = cal.component(.minute, from: earliest)
                key = String(format: "%02d:%02d", h, m)
                time = earliest
            } else {
                key = "99:99"
                time = nil
            }

            if groups[key] != nil {
                groups[key]!.tasks.append(task)
            } else {
                groups[key] = (time: time, tasks: [task])
            }
        }

        return groups
            .sorted(by: { $0.key < $1.key })
            .map { entry in
                let label: String
                if let t = entry.value.time {
                    label = t.timeString
                } else {
                    label = "Anytime"
                }
                return TimeBlock(
                    id: entry.key,
                    time: entry.value.time,
                    label: label,
                    tasks: entry.value.tasks.sorted(by: { $0.name < $1.name })
                )
            }
    }

    func isCompleted(taskID: UUID, petID: UUID) -> Bool {
        completedPairs[taskID]?.contains(petID) == true
    }

    func allPetsCompleted(task: CareTask) -> Bool {
        task.petIDs.allSatisfy { isCompleted(taskID: task.id, petID: $0) }
    }

    func completedPetCount(task: CareTask) -> Int {
        task.petIDs.filter { isCompleted(taskID: task.id, petID: $0) }.count
    }

    // MARK: - Fetch

    func fetchAllTasks() {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCareTask.createdAt, ascending: true)]

        guard let results = try? context.fetch(request) else { return }
        allTasks = results.map { $0.toCareTask() }
        fetchTodayCompletions()
    }

    func fetchTodayCompletions() {
        let context = persistence.container.viewContext
        let request = CDTaskCompletion.fetchRequest()
        let start = Date().startOfDay
        let end = Date().endOfDay
        request.predicate = NSPredicate(format: "completedAt >= %@ AND completedAt <= %@", start as NSDate, end as NSDate)

        guard let results = try? context.fetch(request) else { return }
        var pairs: [UUID: Set<UUID>] = [:]
        for completion in results {
            guard let taskID = completion.careTask?.id, let petID = completion.pet?.id else { continue }
            pairs[taskID, default: []].insert(petID)
        }
        completedPairs = pairs
    }

    // MARK: - Complete / Undo

    func completeTask(_ taskID: UUID, forPet petID: UUID) {
        let context = persistence.container.viewContext

        let taskReq = CDCareTask.fetchRequest()
        taskReq.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
        guard let cdTask = try? context.fetch(taskReq).first else { return }

        let petReq = CDPet.fetchRequest()
        petReq.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
        guard let cdPet = try? context.fetch(petReq).first else { return }

        let completion = CDTaskCompletion(context: context)
        completion.id = UUID()
        completion.completedAt = Date()
        completion.caregiverName = UserDefaults.standard.string(forKey: "caregiverName") ?? "Me"
        completion.careTask = cdTask
        completion.pet = cdPet

        persistence.save()
        completedPairs[taskID, default: []].insert(petID)
    }

    func completeTaskForAllPets(_ task: CareTask) {
        for petID in task.petIDs where !isCompleted(taskID: task.id, petID: petID) {
            completeTask(task.id, forPet: petID)
        }
    }

    func undoCompletion(taskID: UUID, petID: UUID) {
        let context = persistence.container.viewContext
        let request = CDTaskCompletion.fetchRequest()
        let start = Date().startOfDay
        let end = Date().endOfDay
        request.predicate = NSPredicate(
            format: "careTask.id == %@ AND pet.id == %@ AND completedAt >= %@ AND completedAt <= %@",
            taskID as CVarArg, petID as CVarArg, start as NSDate, end as NSDate
        )

        if let results = try? context.fetch(request) {
            for item in results { context.delete(item) }
        }
        persistence.save()
        completedPairs[taskID]?.remove(petID)
    }

    // MARK: - CRUD

    func addTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let cdTask = CDCareTask(context: context)
        cdTask.id = task.id
        cdTask.name = task.name
        cdTask.taskType = task.taskType.rawValue
        cdTask.frequencyType = task.frequencyType.rawValue
        cdTask.frequencyValue = task.frequencyValue
        cdTask.scheduledTimes = task.scheduledTimes as NSArray
        cdTask.isEnabled = task.isEnabled
        cdTask.notifyEnabled = task.notifyEnabled
        cdTask.notes = task.notes
        cdTask.petNotes = task.petNotes as NSDictionary
        cdTask.createdAt = task.createdAt

        // Link to pets (many-to-many)
        for petID in task.petIDs {
            let petReq = CDPet.fetchRequest()
            petReq.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
            if let cdPet = try? context.fetch(petReq).first {
                cdTask.addToPets(cdPet)
            }
        }

        persistence.save()

        if task.notifyEnabled {
            NotificationService.shared.scheduleTaskNotifications(for: task)
        }

        fetchAllTasks()
    }

    func updateTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        guard let cdTask = try? context.fetch(request).first else { return }
        cdTask.name = task.name
        cdTask.taskType = task.taskType.rawValue
        cdTask.frequencyType = task.frequencyType.rawValue
        cdTask.frequencyValue = task.frequencyValue
        cdTask.scheduledTimes = task.scheduledTimes as NSArray
        cdTask.isEnabled = task.isEnabled
        cdTask.notifyEnabled = task.notifyEnabled
        cdTask.notes = task.notes
        cdTask.petNotes = task.petNotes as NSDictionary

        // Update pet associations
        if let existingPets = cdTask.pets as? Set<CDPet> {
            for p in existingPets { cdTask.removeFromPets(p) }
        }
        for petID in task.petIDs {
            let petReq = CDPet.fetchRequest()
            petReq.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
            if let cdPet = try? context.fetch(petReq).first {
                cdTask.addToPets(cdPet)
            }
        }

        persistence.save()

        NotificationService.shared.removeNotifications(for: task.id)
        if task.notifyEnabled && task.isEnabled {
            NotificationService.shared.scheduleTaskNotifications(for: task)
        }

        fetchAllTasks()
    }

    func deleteTask(_ task: CareTask) {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        guard let cdTask = try? context.fetch(request).first else { return }
        NotificationService.shared.removeNotifications(for: task.id)
        context.delete(cdTask)
        persistence.save()
        fetchAllTasks()
    }

    // MARK: - Stats

    func totalTodayTaskPetPairs(filterPetID: UUID? = nil) -> Int {
        var tasks = todayTasks
        if let petID = filterPetID {
            tasks = tasks.filter { $0.petIDs.contains(petID) }
        }
        if let petID = filterPetID {
            return tasks.count
        }
        return tasks.reduce(0) { $0 + $1.petIDs.count }
    }

    func completedTodayTaskPetPairs(filterPetID: UUID? = nil) -> Int {
        var tasks = todayTasks
        if let petID = filterPetID {
            tasks = tasks.filter { $0.petIDs.contains(petID) }
            return tasks.filter { isCompleted(taskID: $0.id, petID: petID) }.count
        }
        return tasks.reduce(0) { sum, task in
            sum + task.petIDs.filter { isCompleted(taskID: task.id, petID: $0) }.count
        }
    }

    // MARK: - History

    func completionHistory(for task: CareTask, days: Int = 7) -> [TaskCompletion] {
        let context = persistence.container.viewContext
        let request = CDTaskCompletion.fetchRequest()
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        request.predicate = NSPredicate(
            format: "careTask.id == %@ AND completedAt >= %@",
            task.id as CVarArg, since as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDTaskCompletion.completedAt, ascending: false)
        ]

        guard let results = try? context.fetch(request) else { return [] }
        return results.map { $0.toTaskCompletion() }
    }
}
