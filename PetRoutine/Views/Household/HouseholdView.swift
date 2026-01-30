import SwiftUI

struct HouseholdView: View {
    @EnvironmentObject var householdVM: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCaregiver = false

    var body: some View {
        NavigationStack {
            List {
                if householdVM.caregivers.isEmpty {
                    Section {
                        Text("No caregivers added yet. Add family members or pet sitters to share care responsibilities.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                } else {
                    Section("Caregivers") {
                        ForEach(householdVM.caregivers) { caregiver in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(caregiver.name)
                                            .font(.body)
                                            .fontWeight(.medium)

                                        if caregiver.isExpired {
                                            Text("Expired")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.red)
                                                .clipShape(Capsule())
                                        } else if caregiver.isTemporary {
                                            Text("Temporary")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.orange)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(caregiver.role.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if let expires = caregiver.expiresAt {
                                        Text("Expires: \(expires.shortDateString)")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteCaregivers)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCaregiver = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCaregiver) {
                AddCaregiverView()
            }
            .onAppear {
                householdVM.fetchHousehold()
            }
        }
    }

    private func deleteCaregivers(at offsets: IndexSet) {
        for index in offsets {
            householdVM.removeCaregiver(householdVM.caregivers[index])
        }
    }
}

struct AddCaregiverView: View {
    @EnvironmentObject var householdVM: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var role: CaregiverRole = .caregiver
    @State private var isTemporary = false
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Caregiver") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Role", selection: $role) {
                        ForEach(CaregiverRole.allCases) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                }

                Section("Temporary Access") {
                    Toggle("Temporary Caregiver", isOn: $isTemporary)

                    if isTemporary {
                        DatePicker("Expires", selection: $expiresAt, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let caregiver = Caregiver(
                            name: name.trimmingCharacters(in: .whitespaces),
                            role: role,
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
