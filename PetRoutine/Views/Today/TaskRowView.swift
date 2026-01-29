import SwiftUI

struct TaskRowView: View {
    let task: CareTask
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var householdVM: HouseholdViewModel
    @State private var showingDetail = false

    private var isCompleted: Bool {
        taskVM.isCompletedToday(task)
    }

    var body: some View {
        HStack(spacing: 14) {
            // One-tap completion button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isCompleted {
                        taskVM.undoCompletion(for: task)
                    } else {
                        taskVM.completeTask(task)
                    }
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .accent : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Mark \(task.name) incomplete" : "Complete \(task.name)")

            // Task info
            Button {
                showingDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: task.taskType.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(task.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                    }

                    HStack(spacing: 8) {
                        if !task.scheduledTimes.isEmpty {
                            let timeStr = task.scheduledTimes.map(\.timeString).joined(separator: ", ")
                            Text(timeStr)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let notes = task.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    if isCompleted,
                       let completions = taskVM.todayCompletions[task.id],
                       let latest = completions.first {
                        Text("\(latest.caregiverName) · \(latest.completedAt.timeString)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
    }
}
