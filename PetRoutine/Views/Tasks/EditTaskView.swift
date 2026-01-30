import SwiftUI

struct EditTaskView: View {
    let task: CareTask

    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var taskType: TaskType
    @State private var frequencyType: FrequencyType
    @State private var frequencyValue: String
    @State private var scheduledTimes: [Date]
    @State private var notes: String
    @State private var notifyEnabled: Bool
    @State private var isEnabled: Bool
    @State private var selectedPetIDs: Set<UUID>
    @State private var petNotes: [String: String]
    @State private var showPetNotes: Bool

    // MARK: - Init

    init(task: CareTask) {
        self.task = task
        _name = State(initialValue: task.name)
        _taskType = State(initialValue: task.taskType)
        _frequencyType = State(initialValue: task.frequencyType)
        _frequencyValue = State(initialValue: task.frequencyValue ?? "")
        _scheduledTimes = State(initialValue: task.scheduledTimes)
        _notes = State(initialValue: task.notes ?? "")
        _notifyEnabled = State(initialValue: task.notifyEnabled)
        _isEnabled = State(initialValue: task.isEnabled)
        _selectedPetIDs = State(initialValue: Set(task.petIDs))
        _petNotes = State(initialValue: task.petNotes)
        _showPetNotes = State(initialValue: !task.petNotes.isEmpty)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                taskTypeSection
                petAssignmentSection
                scheduleSection
                perPetNotesSection
                optionsSection
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedPetIDs.isEmpty)
                }
            }
        }
    }

    // MARK: - Task Type Section

    private var taskTypeSection: some View {
        Section("Task") {
            Picker("Type", selection: $taskType) {
                ForEach(TaskType.allCases) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }

            TextField("Task name", text: $name)
                .textInputAutocapitalization(.words)
        }
    }

    // MARK: - Pet Assignment Section

    private var petAssignmentSection: some View {
        Section("Assign to Pets") {
            ForEach(petVM.pets) { pet in
                Button {
                    togglePet(pet.id)
                } label: {
                    HStack {
                        PetAvatarView(pet: pet, size: 36)

                        Text(pet.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: selectedPetIDs.contains(pet.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedPetIDs.contains(pet.id) ? Color.accentColor : .secondary)
                            .font(.title3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        Section("Schedule") {
            Picker("Frequency", selection: $frequencyType) {
                ForEach(FrequencyType.allCases) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }

            if frequencyType == .weekly {
                Picker("Day", selection: $frequencyValue) {
                    Text("Sunday").tag("1")
                    Text("Monday").tag("2")
                    Text("Tuesday").tag("3")
                    Text("Wednesday").tag("4")
                    Text("Thursday").tag("5")
                    Text("Friday").tag("6")
                    Text("Saturday").tag("7")
                }
            }

            if frequencyType == .custom {
                TextField("Custom schedule", text: $frequencyValue)
            }

            timePickerList
        }
    }

    private var timePickerList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(scheduledTimes.indices, id: \.self) { index in
                HStack {
                    DatePicker(
                        "Time",
                        selection: $scheduledTimes[index],
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    Spacer()

                    Button(role: .destructive) {
                        scheduledTimes.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                scheduledTimes.append(Date())
            } label: {
                Label("Add Time", systemImage: "plus.circle.fill")
            }
        }
    }

    // MARK: - Per-Pet Notes Section

    @ViewBuilder
    private var perPetNotesSection: some View {
        if !selectedPetIDs.isEmpty {
            Section {
                DisclosureGroup("Per-Pet Notes", isExpanded: $showPetNotes) {
                    ForEach(sortedSelectedPets) { pet in
                        TextField(
                            "\(pet.name): note",
                            text: petNoteBinding(for: pet.id)
                        )
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        Section("Options") {
            Toggle("Enabled", isOn: $isEnabled)
            Toggle("Notifications", isOn: $notifyEnabled)

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    // MARK: - Helpers

    private var sortedSelectedPets: [Pet] {
        petVM.pets.filter { selectedPetIDs.contains($0.id) }
    }

    private func togglePet(_ id: UUID) {
        if selectedPetIDs.contains(id) {
            selectedPetIDs.remove(id)
            petNotes.removeValue(forKey: id.uuidString)
        } else {
            selectedPetIDs.insert(id)
        }
    }

    private func petNoteBinding(for petID: UUID) -> Binding<String> {
        Binding(
            get: { petNotes[petID.uuidString] ?? "" },
            set: { petNotes[petID.uuidString] = $0 }
        )
    }

    private func saveTask() {
        let cleanedPetNotes = petNotes.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }

        var updated = task
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.taskType = taskType
        updated.frequencyType = frequencyType
        updated.frequencyValue = frequencyValue.isEmpty ? nil : frequencyValue
        updated.scheduledTimes = scheduledTimes
        updated.notes = notes.isEmpty ? nil : notes
        updated.notifyEnabled = notifyEnabled
        updated.isEnabled = isEnabled
        updated.petIDs = Array(selectedPetIDs)
        updated.petNotes = cleanedPetNotes

        taskVM.updateTask(updated)
        dismiss()
    }
}
