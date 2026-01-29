import SwiftUI

struct PetAvatarView: View {
    let pet: Pet
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let photoData = pet.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: pet.petType.icon)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.accentColor.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
