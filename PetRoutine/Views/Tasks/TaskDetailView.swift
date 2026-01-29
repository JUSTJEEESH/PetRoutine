import SwiftUI

struct TaskDetailView: View {
    let task: CareTask
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    LabeledContent("Type") {
                        Label(task.taskType.displayName, systemImage: task.taskType.icon)
                    }

                    LabeledContent("Frequency") {
                        Text(task.frequencyType.displayName)
                    }

                    if !task.scheduledTimes.isEmpty {
                        LabeledContent("Times") {
                            Text(task.scheduledTimes.map(\.timeString).joined(separator: ", "))
                        }
                    }

                    if let notes = task.notes, !notes.isEmpty {
                        LabeledContent("Notes") {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Enabled", isOn: .constant(task.isEnabled))
                        .disabled(true)

                    Toggle("Notifications", isOn: .constant(task.notifyEnabled))
                        .disabled(true)
                }

                Section("History") {
                    let history = taskVM.completionHistory(for: task)

                    if history.isEmpty {
                        Text("No completions yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(history) { completion in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.completedAt.mediumDateTimeString)
                                        .font(.subheadline)
                                    Text(completion.caregiverName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section {
                    Button("Edit Task") {
                        showingEdit = true
                    }

                    Button("Delete Task", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            }
            .navigationTitle(task.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditTaskView(task: task)
            }
            .alert("Delete Task?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    taskVM.deleteTask(task)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(task.name)\" and all its history.")
            }
        }
    }
}
