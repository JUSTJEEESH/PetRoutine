import SwiftUI

struct TaskDetailView: View {
    let task: CareTask

    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                detailsSection
                assignedPetsSection
                todayStatusSection
                historySection
                actionsSection
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

    // MARK: - Details Section

    private var detailsSection: some View {
        Section("Details") {
            LabeledContent("Type") {
                Label(task.taskType.displayName, systemImage: task.taskType.icon)
            }

            LabeledContent("Frequency") {
                Text(frequencyDescription)
            }

            if !task.scheduledTimes.isEmpty {
                LabeledContent("Times") {
                    Text(task.scheduledTimes.map(\.timeString).joined(separator: ", "))
                }
            }

            if let notes = task.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.body)
                }
            }

            LabeledContent("Notifications") {
                Text(task.notifyEnabled ? "On" : "Off")
            }

            LabeledContent("Enabled") {
                Text(task.isEnabled ? "Yes" : "No")
            }
        }
    }

    private var frequencyDescription: String {
        switch task.frequencyType {
        case .daily:
            return "Daily"
        case .weekly:
            if let dayValue = task.frequencyValue, let dayNum = Int(dayValue) {
                let dayName = dayNameForWeekday(dayNum)
                return "Weekly on \(dayName)"
            }
            return "Weekly"
        case .custom:
            return task.frequencyValue ?? "Custom"
        }
    }

    private func dayNameForWeekday(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        guard weekday >= 1 && weekday <= 7 else { return "Unknown" }
        return formatter.weekdaySymbols[weekday - 1]
    }

    // MARK: - Assigned Pets Section

    private var assignedPetsSection: some View {
        Section("Assigned Pets") {
            if task.petIDs.isEmpty {
                Text("No pets assigned")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(task.petIDs, id: \.self) { petID in
                    if let pet = petVM.petFor(id: petID) {
                        HStack {
                            PetAvatarView(pet: pet, size: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pet.name)
                                    .font(.body)

                                if let note = task.petNotes[petID.uuidString], !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Status Section

    private var todayStatusSection: some View {
        Section("Today") {
            let completedCount = taskVM.completedPetCount(task: task)
            let totalCount = task.petIDs.count

            HStack {
                Text("Completed")
                Spacer()
                Text("\(completedCount) of \(totalCount)")
                    .foregroundStyle(.secondary)
            }

            ForEach(task.petIDs, id: \.self) { petID in
                if let pet = petVM.petFor(id: petID) {
                    let isDone = taskVM.isCompleted(taskID: task.id, petID: petID)
                    HStack {
                        Text(pet.name)
                            .font(.subheadline)

                        Spacer()

                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isDone ? .green : .secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section("Recent History (7 days)") {
            let history = taskVM.completionHistory(for: task, days: 7)

            if history.isEmpty {
                Text("No completions yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history) { completion in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.completedAt.mediumDateTimeString)
                                .font(.subheadline)

                            HStack(spacing: 4) {
                                if let pet = petVM.petFor(id: completion.petID) {
                                    Text(pet.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("by \(completion.caregiverName)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            Button("Edit Task") {
                showingEdit = true
            }

            Button("Delete Task", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
    }
}
