import SwiftUI

struct HealthPassportView: View {
    let pet: Pet

    @StateObject private var healthRecordVM = HealthRecordViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddRecord = false
    @State private var selectedRecord: HealthRecord?
    @State private var addRecordType: HealthRecordType = .vaccination

    var body: some View {
        NavigationStack {
            Group {
                if healthRecordVM.records.isEmpty {
                    EmptyStateView(
                        icon: "cross.case",
                        title: "No Health Records",
                        message: "Track vaccinations, medications, and procedures for \(pet.name).",
                        buttonTitle: "Add Record",
                        action: {
                            addRecordType = .vaccination
                            showingAddRecord = true
                        }
                    )
                } else {
                    recordsList
                }
            }
            .navigationTitle("Health Passport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            addRecordType = .vaccination
                            showingAddRecord = true
                        } label: {
                            Label("Vaccination", systemImage: "syringe.fill")
                        }
                        Button {
                            addRecordType = .medication
                            showingAddRecord = true
                        } label: {
                            Label("Medication", systemImage: "pills.fill")
                        }
                        Button {
                            addRecordType = .procedure
                            showingAddRecord = true
                        } label: {
                            Label("Procedure", systemImage: "cross.case.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                healthRecordVM.fetchRecords(for: pet.id)
            }
            .sheet(isPresented: $showingAddRecord) {
                AddHealthRecordView(
                    petID: pet.id,
                    initialRecordType: addRecordType
                )
                .environmentObject(healthRecordVM)
            }
            .sheet(item: $selectedRecord) { record in
                AddHealthRecordView(petID: pet.id, existingRecord: record)
                    .environmentObject(healthRecordVM)
            }
        }
    }

    // MARK: - Records List

    private var recordsList: some View {
        List {
            // Overdue alert
            if !healthRecordVM.overdueRecords.isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("\(healthRecordVM.overdueRecords.count) overdue record\(healthRecordVM.overdueRecords.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color.red.opacity(0.08))
            }

            // Due soon
            if !healthRecordVM.dueSoonRecords.isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("\(healthRecordVM.dueSoonRecords.count) due within 2 weeks")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color.orange.opacity(0.08))
            }

            // Vaccinations
            recordTypeSection(
                type: .vaccination,
                title: "Vaccinations",
                records: healthRecordVM.records.filter { $0.recordType == .vaccination }
            )

            // Medications
            recordTypeSection(
                type: .medication,
                title: "Medications",
                records: healthRecordVM.records.filter { $0.recordType == .medication }
            )

            // Procedures
            recordTypeSection(
                type: .procedure,
                title: "Procedures",
                records: healthRecordVM.records.filter { $0.recordType == .procedure }
            )
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Record Type Section

    @ViewBuilder
    private func recordTypeSection(type: HealthRecordType, title: String, records: [HealthRecord]) -> some View {
        if !records.isEmpty {
            Section {
                ForEach(records) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        HealthRecordRowView(record: record)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            healthRecordVM.deleteRecord(record)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button {
                    addRecordType = type
                    showingAddRecord = true
                } label: {
                    Label("Add \(type.displayName)", systemImage: "plus.circle")
                }
            } header: {
                Label(title, systemImage: type.icon)
            }
        }
    }
}

// MARK: - Health Record Row

struct HealthRecordRowView: View {
    let record: HealthRecord

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator
                .frame(width: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Label(record.dateAdministered.shortDateString, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let notes = record.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Due date info
            if let dueDate = record.nextDueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next Due")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(dueDate.shortDateString)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(dueDateColor)
                }
            }

            if record.reminderEnabled, record.nextDueDate != nil {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    private var statusColor: Color {
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

    private var dueDateColor: Color {
        if record.isOverdue {
            return .red
        } else if record.isDueSoon {
            return .orange
        } else {
            return .green
        }
    }
}
