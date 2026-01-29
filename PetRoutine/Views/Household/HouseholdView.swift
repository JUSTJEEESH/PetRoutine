import SwiftUI

struct HouseholdView: View {
    @EnvironmentObject var householdVM: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCaregiver = false
    @State private var showingAddTemporary = false
    @State private var householdName: String = ""

    var body: some View {
        NavigationStack {
            List {
                if householdVM.household == nil {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)

                            Text("Set up your household to share pet care with others.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            TextField("Household Name", text: $householdName)
                                .textFieldStyle(.roundedBorder)

                            Button("Create Household") {
                                householdVM.createHousehold(name: householdName.isEmpty ? "My Household" : householdName)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical)
                    }
                } else {
                    Section("Caregivers") {
                        ForEach(householdVM.caregivers) { caregiver in
                            CaregiverRow(caregiver: caregiver)
                        }
                        .onDelete(perform: deleteCaregivers)

                        Button {
                            showingAddCaregiver = true
                        } label: {
                            Label("Add Caregiver", systemImage: "person.badge.plus")
                        }
                    }

                    Section("Temporary Access") {
                        let temporaryCaregivers = householdVM.caregivers.filter(\.isTemporary)

                        if temporaryCaregivers.isEmpty {
                            Text("No temporary caregivers")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(temporaryCaregivers) { caregiver in
                                CaregiverRow(caregiver: caregiver)
                            }
                        }

                        Button {
                            showingAddTemporary = true
                        } label: {
                            Label("Add Temporary Caregiver", systemImage: "clock.badge.checkmark")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddCaregiver) {
                AddCaregiverView(isTemporary: false)
            }
            .sheet(isPresented: $showingAddTemporary) {
                AddCaregiverView(isTemporary: true)
            }
            .onAppear {
                householdVM.fetchHousehold()
            }
        }
    }

    private func deleteCaregivers(at offsets: IndexSet) {
        for index in offsets {
            let caregiver = householdVM.caregivers[index]
            if caregiver.role != .owner {
                householdVM.removeCaregiver(caregiver)
            }
        }
    }
}

struct CaregiverRow: View {
    let caregiver: Caregiver

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(caregiver.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if caregiver.isTemporary {
                        Text("TEMP")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text(caregiver.role.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let expiresAt = caregiver.expiresAt {
                    Text("Expires: \(expiresAt.shortDateString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: roleIcon(caregiver.role))
                .foregroundStyle(.secondary)
        }
    }

    private func roleIcon(_ role: CaregiverRole) -> String {
        switch role {
        case .owner: "crown.fill"
        case .caregiver: "person.fill"
        case .viewer: "eye.fill"
        }
    }
}

struct AddCaregiverView: View {
    let isTemporary: Bool

    @EnvironmentObject var householdVM: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var role: CaregiverRole = .caregiver
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Caregiver") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    if !isTemporary {
                        Picker("Role", selection: $role) {
                            Text(CaregiverRole.caregiver.displayName).tag(CaregiverRole.caregiver)
                            Text(CaregiverRole.viewer.displayName).tag(CaregiverRole.viewer)
                        }
                    }
                }

                if isTemporary {
                    Section("Access Period") {
                        DatePicker("Expires", selection: $expiresAt, in: Date()..., displayedComponents: [.date])
                    }
                }

                if !isTemporary {
                    Section {
                        ForEach(CaregiverRole.allCases.filter { $0 != .owner }) { r in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(r.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Role Descriptions")
                    }
                }
            }
            .navigationTitle(isTemporary ? "Temporary Caregiver" : "Add Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let caregiver = Caregiver(
                            name: name.trimmingCharacters(in: .whitespaces),
                            role: isTemporary ? .caregiver : role,
                            isTemporary: isTemporary,
                            expiresAt: isTemporary ? expiresAt : nil
                        )
                        householdVM.addCaregiver(caregiver)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
