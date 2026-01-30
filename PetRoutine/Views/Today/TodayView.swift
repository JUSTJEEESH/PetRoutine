import SwiftUI

struct TodayView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var healthRecordVM: HealthRecordViewModel

    @State private var showingAddPet = false
    @State private var showingAddTask = false
    @State private var showingSettings = false

    // MARK: - Helpers

    private var filterPetID: UUID? {
        petVM.showAllPets ? nil : petVM.selectedPet?.id
    }

    private var addTaskPetIDs: [UUID] {
        if petVM.showAllPets { return [] }
        if let pet = petVM.selectedPet { return [pet.id] }
        return []
    }

    private var dateString: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    // MARK: - Body

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAddPet) {
                AddPetView()
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(initialPetIDs: addTaskPetIDs)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Today Content

    private var todayContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    dateHeader
                        .padding(.top, 4)

                    petSelectorRow

                    progressSummary

                    healthAlertBanner

                    timeBlocksList
                }
                .padding(.bottom, 88)
            }
            .refreshable {
                await MainActor.run {
                    taskVM.fetchAllTasks()
                    healthRecordVM.fetchAllRecords()
                }
            }
            .onAppear {
                taskVM.fetchAllTasks()
                healthRecordVM.fetchAllRecords()
            }

            floatingAddButton
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Pet Selector

    private var petSelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allPetsBubble

                ForEach(petVM.pets) { pet in
                    petBubble(pet)
                }
            }
            .padding(.horizontal)
        }
    }

    private var allPetsBubble: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                petVM.showAllPets = true
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(petVM.showAllPets ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 52, height: 52)

                    Text("All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(petVM.showAllPets ? .white : .secondary)
                }
                .overlay(
                    Circle()
                        .stroke(petVM.showAllPets ? Color.accentColor : Color.clear, lineWidth: 3)
                        .frame(width: 58, height: 58)
                )

                Text("All")
                    .font(.caption)
                    .fontWeight(petVM.showAllPets ? .semibold : .regular)
                    .foregroundStyle(petVM.showAllPets ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show all pets")
    }

    private func petBubble(_ pet: Pet) -> some View {
        let isSelected = !petVM.showAllPets && petVM.selectedPet?.id == pet.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                petVM.showAllPets = false
                petVM.selectedPet = pet
            }
        } label: {
            VStack(spacing: 4) {
                PetAvatarView(pet: pet, size: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 3
                            )
                            .frame(width: 58, height: 58)
                    )

                Text(pet.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(pet.name)")
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        let total = taskVM.totalTodayTaskPetPairs(filterPetID: filterPetID)
        let completed = taskVM.completedTodayTaskPetPairs(filterPetID: filterPetID)
        let progress: Double = total > 0 ? Double(completed) / Double(total) : 0

        return VStack(spacing: 8) {
            HStack {
                Text("\(completed) of \(total) done")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if total > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .accentColor)
        }
        .padding(.horizontal)
    }

    // MARK: - Health Alert Banner

    @ViewBuilder
    private var healthAlertBanner: some View {
        let overdueCount = healthRecordVM.overdueRecords.count
        let dueSoonCount = healthRecordVM.dueSoonRecords.count
        let totalAlerts = overdueCount + dueSoonCount

        if totalAlerts > 0 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("\(totalAlerts) health record\(totalAlerts == 1 ? "" : "s") due")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }

    // MARK: - Time Blocks

    private var timeBlocksList: some View {
        let blocks = taskVM.timeBlocks(filterPetID: filterPetID)

        return Group {
            if blocks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Tasks Today",
                    message: "Tap + to add a care task for your pets.",
                    buttonTitle: "Add Task",
                    action: { showingAddTask = true }
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(blocks) { block in
                        timeBlockSection(block)
                    }
                }
            }
        }
    }

    private func timeBlockSection(_ block: TimeBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: iconForTimeBlock(block))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(block.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ForEach(block.tasks) { task in
                TaskRowView(task: task)
            }
        }
    }

    private func iconForTimeBlock(_ block: TimeBlock) -> String {
        guard let time = block.time else {
            return "clock.fill"
        }
        let hour = Calendar.current.component(.hour, from: time)
        if hour < 12 {
            return "sunrise.fill"
        } else if hour < 17 {
            return "sun.max.fill"
        } else {
            return "sunset.fill"
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button {
            showingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add new task")
    }
}

// MARK: - Circular Progress (used elsewhere)

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
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
