import SwiftUI

struct TaskRowView: View {
    let task: CareTask

    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var petVM: PetViewModel

    @State private var showingDetail = false

    // MARK: - Computed

    private var allDone: Bool {
        taskVM.allPetsCompleted(task: task)
    }

    private var petNotesSummary: String {
        task.petIDs.compactMap { petID in
            guard let note = task.petNotes[petID.uuidString], !note.isEmpty,
                  let pet = petVM.petFor(id: petID) else { return nil }
            return "\(pet.name): \(note)"
        }.joined(separator: " | ")
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            taskIcon

            taskInfo

            Spacer(minLength: 4)

            petPills
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .opacity(allDone ? 0.65 : 1.0)
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }

    // MARK: - Task Icon

    private var taskIcon: some View {
        Image(systemName: task.taskType.icon)
            .font(.body)
            .foregroundStyle(allDone ? .secondary : .accentColor)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(allDone ? Color(.systemGray5) : Color.accentColor.opacity(0.12))
            )
    }

    // MARK: - Task Info (tappable for detail)

    private var taskInfo: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(allDone ? .secondary : .primary)
                    .strikethrough(allDone)
                    .lineLimit(1)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if !petNotesSummary.isEmpty {
                    Text(petNotesSummary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pet Completion Pills

    private var petPills: some View {
        HStack(spacing: 6) {
            ForEach(task.petIDs, id: \.self) { petID in
                petPill(for: petID)
            }

            if task.petIDs.count > 1 {
                markAllButton
            }
        }
    }

    private func petPill(for petID: UUID) -> some View {
        let completed = taskVM.isCompleted(taskID: task.id, petID: petID)
        let pet = petVM.petFor(id: petID)
        let initial = String((pet?.name ?? "?").prefix(1))

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if completed {
                    taskVM.undoCompletion(taskID: task.id, petID: petID)
                } else {
                    taskVM.completeTask(task.id, forPet: petID)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(completed ? Color.accentColor : Color.clear)
                    .frame(width: 28, height: 28)

                Circle()
                    .stroke(completed ? Color.accentColor : Color(.systemGray3), lineWidth: 2)
                    .frame(width: 28, height: 28)

                if completed {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text(initial)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pet?.name ?? "Pet") \(completed ? "completed" : "pending")")
    }

    // MARK: - Mark All Button

    private var markAllButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if allDone {
                    for petID in task.petIDs {
                        taskVM.undoCompletion(taskID: task.id, petID: petID)
                    }
                } else {
                    taskVM.completeTaskForAllPets(task)
                }
            }
        } label: {
            Text("All")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(allDone ? .secondary : .accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(allDone ? Color(.systemGray5) : Color.accentColor.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(allDone ? "Undo all completions" : "Complete for all pets")
    }
}
