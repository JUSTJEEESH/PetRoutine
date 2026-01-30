import SwiftUI

struct AddHealthRecordView: View {
    let petID: UUID
    let existingRecord: HealthRecord?
    let initialRecordType: HealthRecordType

    @EnvironmentObject var healthRecordVM: HealthRecordViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var recordType: HealthRecordType
    @State private var dateAdministered: Date
    @State private var hasNextDueDate: Bool
    @State private var nextDueDate: Date
    @State private var notes: String
    @State private var reminderEnabled: Bool

    private var isEditing: Bool { existingRecord != nil }

    init(petID: UUID, existingRecord: HealthRecord? = nil, initialRecordType: HealthRecordType = .vaccination) {
        self.petID = petID
        self.existingRecord = existingRecord
        self.initialRecordType = initialRecordType

        if let record = existingRecord {
            _name = State(initialValue: record.name)
            _recordType = State(initialValue: record.recordType)
            _dateAdministered = State(initialValue: record.dateAdministered)
            _hasNextDueDate = State(initialValue: record.nextDueDate != nil)
            _nextDueDate = State(initialValue: record.nextDueDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
            _notes = State(initialValue: record.notes ?? "")
            _reminderEnabled = State(initialValue: record.reminderEnabled)
        } else {
            _name = State(initialValue: "")
            _recordType = State(initialValue: initialRecordType)
            _dateAdministered = State(initialValue: Date())
            _hasNextDueDate = State(initialValue: false)
            _nextDueDate = State(initialValue: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
            _notes = State(initialValue: "")
            _reminderEnabled = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Record Type") {
                    Picker("Type", selection: $recordType) {
                        ForEach(HealthRecordType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField(namePlaceholder, text: $name)
                        .textInputAutocapitalization(.words)

                    DatePicker(
                        "Date Administered",
                        selection: $dateAdministered,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                Section("Next Due Date") {
                    Toggle("Set Next Due Date", isOn: $hasNextDueDate.animation())

                    if hasNextDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $nextDueDate,
                            displayedComponents: .date
                        )

                        Toggle("Enable Reminder", isOn: $reminderEnabled)
                    }
                }

                Section("Notes") {
                    TextField("Additional notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        Button("Delete Record", role: .destructive) {
                            if let record = existingRecord {
                                healthRecordVM.deleteRecord(record)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Record" : "New Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var namePlaceholder: String {
        switch recordType {
        case .vaccination: "e.g., Rabies, DHPP"
        case .medication: "e.g., Heartworm, Flea Prevention"
        case .procedure: "e.g., Dental Cleaning, Spay/Neuter"
        }
    }

    private func saveRecord() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        if let existing = existingRecord {
            var updated = existing
            updated.name = trimmedName
            updated.recordType = recordType
            updated.dateAdministered = dateAdministered
            updated.nextDueDate = hasNextDueDate ? nextDueDate : nil
            updated.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            updated.reminderEnabled = hasNextDueDate ? reminderEnabled : false
            healthRecordVM.updateRecord(updated)
        } else {
            let record = HealthRecord(
                petID: petID,
                name: trimmedName,
                recordType: recordType,
                dateAdministered: dateAdministered,
                nextDueDate: hasNextDueDate ? nextDueDate : nil,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                reminderEnabled: hasNextDueDate ? reminderEnabled : false
            )
            healthRecordVM.addRecord(record)
        }

        dismiss()
    }
}
