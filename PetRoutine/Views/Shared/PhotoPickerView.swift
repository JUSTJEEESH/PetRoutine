import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, height: 100)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }

            let hasImage = imageData != nil
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text(hasImage ? "Change Photo" : "Add Photo")
                    .font(.subheadline)
            }

            if imageData != nil {
                Button("Remove Photo", role: .destructive) {
                    imageData = nil
                    selectedItem = nil
                }
                .font(.caption)
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            guard let item = newValue else { return }
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        let resized = image.preparingThumbnail(of: CGSize(width: 400, height: 400))
                        imageData = resized?.jpegData(compressionQuality: 0.8) ?? data
                    }
                }
            }
        }
    }
}
