import SwiftUI
import PhotosUI

struct AddJournalEntryView: View {
    let petID: UUID
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
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
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
                    }

                    if photoData != nil {
                        Button("Remove Photo", role: .destructive) {
                            photoData = nil
                            selectedItem = nil
                        }
                    }
                }
            }
            .navigationTitle("New Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = JournalEntry(
                            petID: petID,
                            text: text.trimmingCharacters(in: .whitespaces),
                            photoData: photoData
                        )
                        journalVM.addEntry(entry)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let item = newValue else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self) {
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
