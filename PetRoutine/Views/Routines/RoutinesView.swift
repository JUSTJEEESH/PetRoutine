import SwiftUI

struct RoutinesView: View {
    let petID: UUID

    @EnvironmentObject var routineVM: RoutineViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddRoutine = false

    var body: some View {
        NavigationStack {
            Group {
                if routineVM.routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No Routines",
                        message: "Create routines to group tasks together, like a morning or evening routine.",
                        buttonTitle: "Add Routine",
                        action: { showingAddRoutine = true }
                    )
                } else {
                    List {
                        ForEach(routineVM.routines) { routine in
                            NavigationLink(value: routine) {
                                RoutineRow(routine: routine)
                            }
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Routine.self) { routine in
                RoutineDetailView(routine: routine, petID: petID)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRoutine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView()
            }
            .onAppear {
                routineVM.fetchRoutines()
            }
        }
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            routineVM.deleteRoutine(routineVM.routines[index])
        }
    }
}

struct RoutineRow: View {
    let routine: Routine
    @EnvironmentObject var routineVM: RoutineViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.body)
                    .fontWeight(.medium)

                let taskCount = routineVM.tasksForRoutine(routine).count
                Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { routine.isEnabled },
                set: { _ in routineVM.toggleRoutine(routine) }
            ))
            .labelsHidden()
        }
    }
}

struct AddRoutineView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Name (e.g., Morning Routine)", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Notes (optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let routine = Routine(
                            name: name.trimmingCharacters(in: .whitespaces),
                            notes: notes.isEmpty ? nil : notes
                        )
                        routineVM.addRoutine(routine)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct RoutineDetailView: View {
    let routine: Routine
    let petID: UUID

    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingAddTask = false
    @State private var showingDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Tasks") {
                let tasks = routineVM.tasksForRoutine(routine)

                if tasks.isEmpty {
                    Text("No tasks in this routine")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tasks) { task in
                        HStack {
                            Image(systemName: task.taskType.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            Text(task.name)
                                .font(.body)
                        }
                    }
                }

                Button {
                    showingAddTask = true
                } label: {
                    Label("Add Task to Routine", systemImage: "plus.circle")
                }
            }

            if let notes = routine.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Clone Routine") {
                    routineVM.cloneRoutine(routine, forPetID: petID)
                }

                Button("Delete Routine", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(routine.name)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(petID: petID, routineID: routine.id)
        }
        .alert("Delete Routine?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                routineVM.deleteRoutine(routine)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the routine. Tasks will remain but won't be grouped.")
        }
    }
}
