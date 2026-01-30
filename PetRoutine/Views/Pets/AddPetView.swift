import SwiftUI

struct AddPetView: View {
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var petType: PetType = .dog
    @State private var ageCategory: AgeCategory = .adult
    @State private var photoData: Data?
    @State private var hasBirthday = false
    @State private var birthday = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotoPickerView(imageData: $photoData)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Pet name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Details") {
                    Picker("Type", selection: $petType) {
                        ForEach(PetType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Age", selection: $ageCategory) {
                        ForEach(AgeCategory.allCases) { category in
                            Text(category.displayName(for: petType))
                                .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Birthday") {
                    Toggle("Set Birthday", isOn: $hasBirthday.animation())

                    if hasBirthday {
                        DatePicker(
                            "Birthday",
                            selection: $birthday,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }
            }
            .navigationTitle("New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePet()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func savePet() {
        let pet = Pet(
            name: name.trimmingCharacters(in: .whitespaces),
            petType: petType,
            ageCategory: ageCategory,
            photoData: photoData,
            birthday: hasBirthday ? birthday : nil,
            sortOrder: Int16(petVM.pets.count)
        )
        petVM.addPet(pet)
        dismiss()
    }
}
