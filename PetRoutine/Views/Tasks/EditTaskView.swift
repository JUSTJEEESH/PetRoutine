import SwiftUI

struct EditTaskView: View {
    let task: CareTask
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var taskType: TaskType
    @State private var frequencyType: FrequencyType
    @State private var frequencyValue: String
    @State private var scheduledTimes: [Date]
    @State private var notes: String
    @State private var notifyEnabled: Bool
    @State private var isEnabled: Bool

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
    }

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
                        TextField("Custom schedule", text: $frequencyValue)
                    }

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

                Section("Options") {
                    Toggle("Enabled", isOn: $isEnabled)
                    Toggle("Notifications", isOn: $notifyEnabled)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        var updated = task
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.taskType = taskType
        updated.frequencyType = frequencyType
        updated.frequencyValue = frequencyValue.isEmpty ? nil : frequencyValue
        updated.scheduledTimes = scheduledTimes
        updated.notes = notes.isEmpty ? nil : notes
        updated.notifyEnabled = notifyEnabled
        updated.isEnabled = isEnabled
        taskVM.updateTask(updated)
        dismiss()
    }
}
