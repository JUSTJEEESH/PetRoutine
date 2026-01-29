import SwiftUI

struct EditPetView: View {
    let pet: Pet
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var petType: PetType
    @State private var ageCategory: AgeCategory
    @State private var photoData: Data?

    init(pet: Pet) {
        self.pet = pet
        _name = State(initialValue: pet.name)
        _petType = State(initialValue: pet.petType)
        _ageCategory = State(initialValue: pet.ageCategory)
        _photoData = State(initialValue: pet.photoData)
    }

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
            }
            .navigationTitle("Edit Pet")
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
        var updated = pet
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.petType = petType
        updated.ageCategory = ageCategory
        updated.photoData = photoData
        petVM.updatePet(updated)
        dismiss()
    }
}
