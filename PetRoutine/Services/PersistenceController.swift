import CoreData
import SwiftUI

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let pet = CDPet(context: context)
        pet.id = UUID()
        pet.name = "Buddy"
        pet.petType = "dog"
        pet.ageCategory = "adult"
        pet.createdAt = Date()
        pet.sortOrder = 0

        let task1 = CDCareTask(context: context)
        task1.id = UUID()
        task1.name = "Morning Feed"
        task1.taskType = "feeding"
        task1.frequencyType = "daily"
        task1.isEnabled = true
        task1.notifyEnabled = true
        task1.createdAt = Date()
        task1.pet = pet

        let task2 = CDCareTask(context: context)
        task2.id = UUID()
        task2.name = "Walk"
        task2.taskType = "walk"
        task2.frequencyType = "daily"
        task2.isEnabled = true
        task2.notifyEnabled = true
        task2.createdAt = Date()
        task2.pet = pet

        let pet2 = CDPet(context: context)
        pet2.id = UUID()
        pet2.name = "Whiskers"
        pet2.petType = "cat"
        pet2.ageCategory = "senior"
        pet2.createdAt = Date()
        pet2.sortOrder = 1

        do {
            try context.save()
        } catch {
            fatalError("Preview Core Data save error: \(error)")
        }

        return controller
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "PetRoutine")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        if !iCloudEnabled {
            description?.cloudKitContainerOptions = nil
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data load error: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error.localizedDescription)")
        }
    }
}
