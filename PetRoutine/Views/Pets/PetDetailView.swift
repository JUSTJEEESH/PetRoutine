import SwiftUI

struct PetDetailView: View {
    let pet: Pet
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingEditPet = false
    @State private var showingAddTask = false
    @State private var showingVetInfo = false
    @State private var showingTimeline = false
    @State private var showingExport = false
    @State private var showingRoutines = false
    @State private var showingDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Pet header
            Section {
                HStack(spacing: 16) {
                    PetAvatarView(pet: pet, size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pet.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 6) {
                            Label(pet.petType.displayName, systemImage: pet.petType.icon)
                            Text("·")
                            Text(pet.ageCategory.displayName(for: pet.petType))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Tasks
            Section("Tasks") {
                let petTasks = taskVM.tasks.filter { $0.petID == pet.id }
                if petTasks.isEmpty {
                    Text("No tasks yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(petTasks) { task in
                        HStack {
                            Image(systemName: task.taskType.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading) {
                                Text(task.name)
                                    .font(.body)
                                Text(task.frequencyType.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if !task.isEnabled {
                                Text("Off")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Button {
                    showingAddTask = true
                } label: {
                    Label("Add Task", systemImage: "plus.circle")
                }
            }

            // Actions
            Section("Actions") {
                Button {
                    showingTimeline = true
                } label: {
                    Label("Timeline", systemImage: "clock.arrow.circlepath")
                }

                Button {
                    showingRoutines = true
                } label: {
                    Label("Routines", systemImage: "list.bullet.rectangle")
                }

                Button {
                    showingVetInfo = true
                } label: {
                    Label("Vet Info", systemImage: "cross.case")
                }

                Button {
                    showingExport = true
                } label: {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
            }

            // Danger zone
            Section {
                Button("Edit Pet") {
                    showingEditPet = true
                }

                Button("Delete Pet", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            taskVM.fetchTasks(for: pet.id)
        }
        .sheet(isPresented: $showingEditPet) {
            EditPetView(pet: pet)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(petID: pet.id)
        }
        .sheet(isPresented: $showingVetInfo) {
            VetInfoView(petID: pet.id)
        }
        .sheet(isPresented: $showingTimeline) {
            TimelineView(petID: pet.id, petName: pet.name)
        }
        .sheet(isPresented: $showingExport) {
            ExportView(pet: pet)
        }
        .sheet(isPresented: $showingRoutines) {
            RoutinesView(petID: pet.id)
        }
        .alert("Delete \(pet.name)?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                petVM.deletePet(pet)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(pet.name) and all associated tasks, logs, and history.")
        }
    }
}
