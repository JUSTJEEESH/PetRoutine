import SwiftUI

struct VetInfoView: View {
    let petID: UUID
    @StateObject private var vetInfoVM = VetInfoViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Veterinarian") {
                    TextField("Vet name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let phone = vetInfoVM.vetInfo?.phone, !phone.isEmpty {
                    Section {
                        Button {
                            let cleaned = phone.filter { $0.isNumber || $0 == "+" }
                            if let url = URL(string: "tel://\(cleaned)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
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
                        let info = VetInfo(
                            id: vetInfoVM.vetInfo?.id ?? UUID(),
                            petID: petID,
                            name: name.isEmpty ? nil : name,
                            phone: self.phone.isEmpty ? nil : self.phone,
                            address: address.isEmpty ? nil : address,
                            notes: self.notes.isEmpty ? nil : self.notes
                        )
                        vetInfoVM.saveVetInfo(info)
                        dismiss()
                    }
                }
            }
            .onAppear {
                vetInfoVM.fetchVetInfo(for: petID)
                if let info = vetInfoVM.vetInfo {
                    name = info.name ?? ""
                    phone = info.phone ?? ""
                    address = info.address ?? ""
                    notes = info.notes ?? ""
                }
            }
        }
    }
}
