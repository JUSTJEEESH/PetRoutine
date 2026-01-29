import SwiftUI
import PhotosUI

struct AddJournalEntryView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPetID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                if petVM.pets.count > 1 {
                    Section("Pet") {
                        Picker("Pet", selection: $selectedPetID) {
                            ForEach(petVM.pets) { pet in
                                Text(pet.name).tag(Optional(pet.id))
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField("What happened?", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Photo (optional)") {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button("Remove Photo", role: .destructive) {
                            self.photoData = nil
                            selectedItem = nil
                        }
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(
                            photoData == nil ? "Add Photo" : "Change Photo",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                selectedPetID = petVM.selectedPet?.id
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            if let image = UIImage(data: data) {
                                let resized = image.preparingThumbnail(of: CGSize(width: 800, height: 800))
                                photoData = resized?.jpegData(compressionQuality: 0.8) ?? data
                            }
                        }
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            petID: selectedPetID,
            text: text.trimmingCharacters(in: .whitespaces),
            photoData: photoData
        )
        journalVM.addEntry(entry)
        dismiss()
    }
}
