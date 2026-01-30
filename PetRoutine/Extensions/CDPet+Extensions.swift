import CoreData

extension CDPet {
    func toPet() -> Pet {
        Pet(
            id: id ?? UUID(),
            name: name ?? "",
            petType: PetType(rawValue: petType ?? "dog") ?? .dog,
            ageCategory: AgeCategory(rawValue: ageCategory ?? "adult") ?? .adult,
            photoData: photoData,
            birthday: birthday,
            sortOrder: sortOrder,
            createdAt: createdAt ?? Date()
        )
    }
}

extension CDCareTask {
    func toCareTask() -> CareTask {
        let petIDArray: [UUID] = (pets as? Set<CDPet>)?.compactMap { $0.id }.sorted(by: { $0.uuidString < $1.uuidString }) ?? []
        let notesDict = (petNotes as? [String: String]) ?? [:]
        return CareTask(
            id: id ?? UUID(),
            name: name ?? "",
            taskType: TaskType(rawValue: taskType ?? "custom") ?? .custom,
            frequencyType: FrequencyType(rawValue: frequencyType ?? "daily") ?? .daily,
            frequencyValue: frequencyValue,
            scheduledTimes: (scheduledTimes as? [Date]) ?? [],
            isEnabled: isEnabled,
            notifyEnabled: notifyEnabled,
            notes: notes,
            petIDs: petIDArray,
            petNotes: notesDict,
            createdAt: createdAt ?? Date()
        )
    }
}

extension CDTaskCompletion {
    func toTaskCompletion() -> TaskCompletion {
        TaskCompletion(
            id: id ?? UUID(),
            taskID: careTask?.id ?? UUID(),
            petID: pet?.id ?? UUID(),
            completedAt: completedAt ?? Date(),
            caregiverName: caregiverName ?? "Me",
            notes: notes
        )
    }
}

extension CDHealthRecord {
    func toHealthRecord() -> HealthRecord {
        HealthRecord(
            id: id ?? UUID(),
            petID: pet?.id ?? UUID(),
            name: name ?? "",
            recordType: HealthRecordType(rawValue: recordType ?? "vaccination") ?? .vaccination,
            dateAdministered: dateAdministered ?? Date(),
            nextDueDate: nextDueDate,
            notes: notes,
            reminderEnabled: reminderEnabled,
            createdAt: createdAt ?? Date()
        )
    }
}

extension CDJournalEntry {
    func toJournalEntry() -> JournalEntry {
        JournalEntry(
            id: id ?? UUID(),
            petID: pet?.id ?? UUID(),
            text: text ?? "",
            photoData: photoData,
            createdAt: createdAt ?? Date()
        )
    }
}

extension CDVetInfo {
    func toVetInfo() -> VetInfo {
        VetInfo(
            id: id ?? UUID(),
            petID: pet?.id ?? UUID(),
            name: name,
            phone: phone,
            address: address,
            notes: notes
        )
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
}

extension CDHousehold {
    func toHousehold() -> Household {
        let caregiversArray = (caregivers as? Set<CDCaregiver>)?.map { $0.toCaregiver() }.sorted(by: { $0.createdAt < $1.createdAt }) ?? []
        return Household(
            id: id ?? UUID(),
            name: name ?? "My Household",
            caregivers: caregiversArray,
            createdAt: createdAt ?? Date()
        )
    }
}
