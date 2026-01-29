import CoreData

extension CDPet {
    func toPet() -> Pet {
        Pet(
            id: id ?? UUID(),
            name: name ?? "",
            petType: PetType(rawValue: petType ?? "dog") ?? .dog,
            ageCategory: AgeCategory(rawValue: ageCategory ?? "adult") ?? .adult,
            photoData: photoData,
            sortOrder: sortOrder,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from pet: Pet) {
        id = pet.id
        name = pet.name
        petType = pet.petType.rawValue
        ageCategory = pet.ageCategory.rawValue
        photoData = pet.photoData
        sortOrder = pet.sortOrder
        createdAt = pet.createdAt
    }
}

extension CDCareTask {
    func toCareTask() -> CareTask {
        CareTask(
            id: id ?? UUID(),
            petID: pet?.id,
            name: name ?? "",
            taskType: TaskType(rawValue: taskType ?? "custom") ?? .custom,
            frequencyType: FrequencyType(rawValue: frequencyType ?? "daily") ?? .daily,
            frequencyValue: frequencyValue,
            scheduledTimes: (scheduledTimes as? [Date]) ?? [],
            notes: notes,
            isEnabled: isEnabled,
            notifyEnabled: notifyEnabled,
            routineID: routine?.id,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from task: CareTask, in context: NSManagedObjectContext) {
        id = task.id
        name = task.name
        taskType = task.taskType.rawValue
        frequencyType = task.frequencyType.rawValue
        frequencyValue = task.frequencyValue
        scheduledTimes = task.scheduledTimes as NSArray
        notes = task.notes
        isEnabled = task.isEnabled
        notifyEnabled = task.notifyEnabled
        createdAt = task.createdAt

        if let petID = task.petID {
            let request = CDPet.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
            pet = try? context.fetch(request).first
        }

        if let routineID = task.routineID {
            let request = CDRoutine.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", routineID as CVarArg)
            routine = try? context.fetch(request).first
        }
    }
}

extension CDTaskCompletion {
    func toTaskCompletion() -> TaskCompletion {
        TaskCompletion(
            id: id ?? UUID(),
            careTaskID: careTask?.id,
            completedAt: completedAt ?? Date(),
            caregiverName: caregiverName ?? "Me",
            notes: notes
        )
    }
}

extension CDRoutine {
    func toRoutine() -> Routine {
        Routine(
            id: id ?? UUID(),
            name: name ?? "",
            isEnabled: isEnabled,
            notes: notes,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from routine: Routine) {
        id = routine.id
        name = routine.name
        isEnabled = routine.isEnabled
        notes = routine.notes
        createdAt = routine.createdAt
    }
}

extension CDJournalEntry {
    func toJournalEntry() -> JournalEntry {
        JournalEntry(
            id: id ?? UUID(),
            petID: pet?.id,
            text: text ?? "",
            photoData: photoData,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from entry: JournalEntry, in context: NSManagedObjectContext) {
        id = entry.id
        text = entry.text
        photoData = entry.photoData
        createdAt = entry.createdAt

        if let petID = entry.petID {
            let request = CDPet.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
            pet = try? context.fetch(request).first
        }
    }
}

extension CDVetInfo {
    func toVetInfo() -> VetInfo {
        VetInfo(
            id: id ?? UUID(),
            petID: pet?.id,
            name: name ?? "",
            phone: phone ?? "",
            address: address ?? "",
            notes: notes ?? ""
        )
    }

    func update(from info: VetInfo, in context: NSManagedObjectContext) {
        id = info.id
        name = info.name
        phone = info.phone
        address = info.address
        notes = info.notes

        if let petID = info.petID {
            let request = CDPet.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", petID as CVarArg)
            pet = try? context.fetch(request).first
        }
    }
}

extension CDCaregiver {
    func toCaregiver() -> Caregiver {
        Caregiver(
            id: id ?? UUID(),
            name: name ?? "",
            role: CaregiverRole(rawValue: role ?? "caregiver") ?? .caregiver,
            isTemporary: isTemporary,
            expiresAt: expiresAt,
            createdAt: createdAt ?? Date()
        )
    }

    func update(from caregiver: Caregiver) {
        id = caregiver.id
        name = caregiver.name
        role = caregiver.role.rawValue
        isTemporary = caregiver.isTemporary
        expiresAt = caregiver.expiresAt
        createdAt = caregiver.createdAt
    }
}

extension CDHousehold {
    func toHousehold() -> Household {
        Household(
            id: id ?? UUID(),
            name: name ?? "My Household",
            createdAt: createdAt ?? Date()
        )
    }
}
