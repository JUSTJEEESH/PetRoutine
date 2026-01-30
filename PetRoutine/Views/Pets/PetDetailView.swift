import SwiftUI

struct PetDetailView: View {
    let pet: Pet

    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @StateObject private var healthRecordVM = HealthRecordViewModel()

    @State private var showingEditPet = false
    @State private var showingAddTask = false
    @State private var showingAddRecord = false
    @State private var showingHealthPassport = false
    @State private var showingJournalEntry = false
    @State private var showingVetInfo = false
    @State private var showingExport = false
    @State private var showingTimeline = false
    @State private var showingDeleteConfirm = false
    @State private var selectedRecord: HealthRecord?

    @Environment(\.dismiss) private var dismiss

    private var birthdayString: String? {
        guard let birthday = pet.birthday else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthday)
    }

    var body: some View {
        List {
            headerSection
            todayTasksSection
            healthPassportSection
            actionsSection
            managementSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            taskVM.fetchAllTasks()
            healthRecordVM.fetchRecords(for: pet.id)
        }
        .sheet(isPresented: $showingEditPet) {
            EditPetView(pet: pet)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(initialPetIDs: [pet.id])
        }
        .sheet(isPresented: $showingAddRecord) {
            AddHealthRecordView(petID: pet.id)
                .environmentObject(healthRecordVM)
        }
        .sheet(isPresented: $showingHealthPassport, onDismiss: {
            healthRecordVM.fetchRecords(for: pet.id)
        }) {
            HealthPassportView(pet: pet)
        }
        .sheet(isPresented: $showingJournalEntry) {
            AddJournalEntryView(petID: pet.id)
        }
        .sheet(isPresented: $showingVetInfo) {
            VetInfoView(petID: pet.id)
        }
        .sheet(isPresented: $showingExport) {
            ExportView(pet: pet)
        }
        .sheet(isPresented: $showingTimeline) {
            PetTimelineView(pet: pet)
        }
        .sheet(item: $selectedRecord) { record in
            AddHealthRecordView(petID: pet.id, existingRecord: record)
                .environmentObject(healthRecordVM)
        }
        .alert("Delete \(pet.name)?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                petVM.deletePet(pet)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(pet.name) and all associated tasks, health records, and history.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
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

                    if let birthdayString {
                        Label(birthdayString, systemImage: "birthday.cake")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Today's Tasks Section

    private var todayTasksSection: some View {
        Section {
            let petTasks = taskVM.todayTasks.filter { $0.petIDs.contains(pet.id) }

            if petTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No tasks scheduled for today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(petTasks) { task in
                    todayTaskRow(task: task)
                }
            }

            Button {
                showingAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Today's Tasks")
                Spacer()
                let completed = taskVM.completedTodayTaskPetPairs(filterPetID: pet.id)
                let total = taskVM.totalTodayTaskPetPairs(filterPetID: pet.id)
                if total > 0 {
                    Text("\(completed)/\(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func todayTaskRow(task: CareTask) -> some View {
        let isCompleted = taskVM.isCompleted(taskID: task.id, petID: pet.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isCompleted {
                    taskVM.undoCompletion(taskID: task.id, petID: pet.id)
                } else {
                    taskVM.completeTask(task.id, forPet: pet.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                Image(systemName: task.taskType.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(task.name)
                    .font(.body)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)

                Spacer()

                if !task.isEnabled {
                    Text("Off")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Health Passport Section

    private var healthPassportSection: some View {
        Section {
            // Overdue alert banner
            if !healthRecordVM.overdueRecords.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("\(healthRecordVM.overdueRecords.count) overdue")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.red.opacity(0.08))
            }

            // Grouped health records (show first few per type)
            let vaccinations = healthRecordVM.records.filter { $0.recordType == .vaccination }
            let medications = healthRecordVM.records.filter { $0.recordType == .medication }
            let procedures = healthRecordVM.records.filter { $0.recordType == .procedure }

            if healthRecordVM.records.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "cross.case")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No health records yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                healthRecordGroup(title: "Vaccinations", icon: "syringe.fill", records: vaccinations)
                healthRecordGroup(title: "Medications", icon: "pills.fill", records: medications)
                healthRecordGroup(title: "Procedures", icon: "cross.case.fill", records: procedures)
            }

            // Add Record
            Button {
                showingAddRecord = true
            } label: {
                Label("Add Record", systemImage: "plus.circle")
            }

            // View Full Passport
            if !healthRecordVM.records.isEmpty {
                Button {
                    showingHealthPassport = true
                } label: {
                    Label("View Full Health Passport", systemImage: "list.clipboard")
                }
            }
        } header: {
            Text("Health Passport")
        }
    }

    @ViewBuilder
    private func healthRecordGroup(title: String, icon: String, records: [HealthRecord]) -> some View {
        if !records.isEmpty {
            let preview = Array(records.prefix(3))
            ForEach(preview) { record in
                Button {
                    selectedRecord = record
                } label: {
                    healthRecordRow(record: record)
                }
                .buttonStyle(.plain)
            }

            if records.count > 3 {
                Text("+\(records.count - 3) more \(title.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func healthRecordRow(record: HealthRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.recordType.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(record.dateAdministered.shortDateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let dueDate = record.nextDueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Due")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(dueDate.shortDateString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(dueDateColor(for: record))
                }
            }

            Circle()
                .fill(statusColor(for: record))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                actionButton(title: "Journal", icon: "book.fill") {
                    showingJournalEntry = true
                }
                actionButton(title: "Vet Info", icon: "cross.case") {
                    showingVetInfo = true
                }
                actionButton(title: "Export", icon: "square.and.arrow.up") {
                    showingExport = true
                }
                actionButton(title: "Timeline", icon: "clock.arrow.circlepath") {
                    showingTimeline = true
                }
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.accent)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Management Section

    private var managementSection: some View {
        Section {
            Button("Edit Pet") {
                showingEditPet = true
            }

            Button("Delete Pet", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
    }

    // MARK: - Helpers

    private func dueDateColor(for record: HealthRecord) -> Color {
        if record.isOverdue {
            return .red
        } else if record.isDueSoon {
            return .orange
        } else {
            return .green
        }
    }

    private func statusColor(for record: HealthRecord) -> Color {
        guard record.nextDueDate != nil else {
            return .gray
        }
        if record.isOverdue {
            return .red
        } else if record.isDueSoon {
            return .orange
        } else {
            return .green
        }
    }
}
