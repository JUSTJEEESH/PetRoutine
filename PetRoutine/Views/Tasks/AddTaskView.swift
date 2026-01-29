import SwiftUI

struct AddTaskView: View {
    let petID: UUID
    var routineID: UUID? = nil

    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var taskType: TaskType = .custom
    @State private var frequencyType: FrequencyType = .daily
    @State private var frequencyValue = ""
    @State private var scheduledTime = Date()
    @State private var scheduledTimes: [Date] = []
    @State private var notes = ""
    @State private var notifyEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Type", selection: $taskType) {
                        ForEach(TaskType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

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
                        TextField("Custom schedule (e.g., every 3 days)", text: $frequencyValue)
                    }

                    // Times
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
                            scheduledTimes.append(scheduledTime)
                        } label: {
                            Label("Add Time", systemImage: "plus.circle.fill")
                        }
                    }
                }

                Section("Options") {
                    Toggle("Notifications", isOn: $notifyEnabled)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            applyDefaultsForType()
        }
        .onChange(of: taskType) { _, _ in
            applyDefaultsForType()
        }
    }

    private func applyDefaultsForType() {
        if name.isEmpty {
            switch taskType {
            case .feeding: name = "Feeding"
            case .walk: name = "Walk"
            case .medication: name = "Medication"
            case .grooming: name = "Grooming"
            case .custom: break
            }
        }
    }

    private func saveTask() {
        let task = CareTask(
            petID: petID,
            name: name.trimmingCharacters(in: .whitespaces),
            taskType: taskType,
            frequencyType: frequencyType,
            frequencyValue: frequencyValue.isEmpty ? nil : frequencyValue,
            scheduledTimes: scheduledTimes,
            notes: notes.isEmpty ? nil : notes,
            isEnabled: true,
            notifyEnabled: notifyEnabled,
            routineID: routineID
        )
        taskVM.addTask(task)
        dismiss()
    }
}
