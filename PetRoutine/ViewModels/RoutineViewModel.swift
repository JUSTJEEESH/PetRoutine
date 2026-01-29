import CoreData
import SwiftUI

@MainActor
final class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        fetchRoutines()
    }

    func fetchRoutines() {
        let context = persistence.container.viewContext
        let request = CDRoutine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDRoutine.createdAt, ascending: true)]

        do {
            routines = try context.fetch(request).map { $0.toRoutine() }
        } catch {
            print("Fetch routines error: \(error.localizedDescription)")
        }
    }

    func addRoutine(_ routine: Routine) {
        let context = persistence.container.viewContext
        let cdRoutine = CDRoutine(context: context)
        cdRoutine.update(from: routine)
        persistence.save()
        fetchRoutines()
    }

    func updateRoutine(_ routine: Routine) {
        let context = persistence.container.viewContext
        let request = CDRoutine.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", routine.id as CVarArg)

        do {
            if let cdRoutine = try context.fetch(request).first {
                cdRoutine.update(from: routine)
                persistence.save()
                fetchRoutines()
            }
        } catch {
            print("Update routine error: \(error.localizedDescription)")
        }
    }

    func deleteRoutine(_ routine: Routine) {
        let context = persistence.container.viewContext
        let request = CDRoutine.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", routine.id as CVarArg)

        do {
            if let cdRoutine = try context.fetch(request).first {
                context.delete(cdRoutine)
                persistence.save()
                fetchRoutines()
            }
        } catch {
            print("Delete routine error: \(error.localizedDescription)")
        }
    }

    func toggleRoutine(_ routine: Routine) {
        var updated = routine
        updated.isEnabled.toggle()
        updateRoutine(updated)
    }

    func tasksForRoutine(_ routine: Routine) -> [CareTask] {
        let context = persistence.container.viewContext
        let request = CDCareTask.fetchRequest()
        request.predicate = NSPredicate(format: "routine.id == %@", routine.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCareTask.createdAt, ascending: true)]

        do {
            return try context.fetch(request).map { $0.toCareTask() }
        } catch {
            print("Fetch routine tasks error: \(error.localizedDescription)")
            return []
        }
    }

    func cloneRoutine(_ routine: Routine, forPetID petID: UUID) {
        let newRoutine = Routine(name: "\(routine.name) (Copy)", notes: routine.notes)
        addRoutine(newRoutine)

        let existingTasks = tasksForRoutine(routine)
        let context = persistence.container.viewContext

        for task in existingTasks {
            let newTask = CareTask(
                petID: petID,
                name: task.name,
                taskType: task.taskType,
                frequencyType: task.frequencyType,
                frequencyValue: task.frequencyValue,
                scheduledTimes: task.scheduledTimes,
                notes: task.notes,
                isEnabled: task.isEnabled,
                notifyEnabled: task.notifyEnabled,
                routineID: newRoutine.id
            )
            let cdTask = CDCareTask(context: context)
            cdTask.update(from: newTask, in: context)
        }

        persistence.save()
    }
}
