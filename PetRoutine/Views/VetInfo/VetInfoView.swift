import SwiftUI

struct VetInfoView: View {
    let petID: UUID

    @StateObject private var vetInfoVM = VetInfoViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Veterinarian") {
                    TextField("Vet name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !phone.isEmpty {
                    Section {
                        Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                            Label("Call Vet", systemImage: "phone.fill")
                        }
                    }
                }
            }
            .navigationTitle("Vet Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVetInfo()
                    }
                }
            }
            .onAppear {
                vetInfoVM.fetchVetInfo(for: petID)
                if let info = vetInfoVM.vetInfo {
                    name = info.name
                    phone = info.phone
                    address = info.address
                    notes = info.notes
                }
            }
        }
    }

    private func saveVetInfo() {
        let info = VetInfo(
            id: vetInfoVM.vetInfo?.id ?? UUID(),
            petID: petID,
            name: name.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        vetInfoVM.saveVetInfo(info)
        dismiss()
    }
}
