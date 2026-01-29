import SwiftUI

struct TodayView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingAddPet = false
    @State private var showingAddTask = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if petVM.pets.isEmpty {
                    EmptyStateView(
                        icon: "pawprint.fill",
                        title: "Welcome to PetRoutine",
                        message: "Add your first pet to start tracking care tasks.",
                        buttonTitle: "Add Pet",
                        action: { showingAddPet = true }
                    )
                } else {
                    todayContent
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !petVM.pets.isEmpty {
                        Button {
                            showingAddTask = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPet) {
                AddPetView()
            }
            .sheet(isPresented: $showingAddTask) {
                if let pet = petVM.selectedPet {
                    AddTaskView(petID: pet.id)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pet selector
                if petVM.pets.count > 1 {
                    PetSelectorView()
                        .padding(.top, 8)
                }

                // Summary
                if let pet = petVM.selectedPet {
                    todaySummary(for: pet)
                }

                // Task list
                if let pet = petVM.selectedPet {
                    todayTasks(for: pet)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            if let pet = petVM.selectedPet {
                taskVM.fetchTasks(for: pet.id)
            }
        }
        .onChange(of: petVM.selectedPet?.id) { _, newValue in
            if let petID = newValue {
                taskVM.fetchTasks(for: petID)
            }
        }
        .onAppear {
            if let pet = petVM.selectedPet {
                taskVM.fetchTasks(for: pet.id)
            }
        }
    }

    private func todaySummary(for pet: Pet) -> some View {
        let summary = taskVM.todayTasksSummary(for: pet.id)
        return HStack {
            PetAvatarView(pet: pet, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.headline)
                if summary.total > 0 {
                    Text("\(summary.completed)/\(summary.total) tasks done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No tasks scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if summary.total > 0 {
                CircularProgressView(
                    progress: summary.total > 0 ? Double(summary.completed) / Double(summary.total) : 0
                )
                .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal)
    }

    private func todayTasks(for pet: Pet) -> some View {
        let todayTasks = taskVM.tasks.filter { taskVM.shouldShowToday($0) }

        return VStack(spacing: 0) {
            if todayTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Tasks Today",
                    message: "Add a task to start tracking \(pet.name)'s care.",
                    buttonTitle: "Add Task",
                    action: { showingAddTask = true }
                )
                .frame(minHeight: 200)
            } else {
                let pending = todayTasks.filter { !taskVM.isCompletedToday($0) }
                let completed = todayTasks.filter { taskVM.isCompletedToday($0) }

                if !pending.isEmpty {
                    taskSection(title: "To Do", tasks: pending)
                }

                if !completed.isEmpty {
                    taskSection(title: "Done", tasks: completed)
                }
            }
        }
    }

    private func taskSection(title: String, tasks: [CareTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ForEach(tasks) { task in
                TaskRowView(task: task)
            }
        }
        .padding(.top, 8)
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.accent)
            }
        }
    }
}
