import SwiftUI

struct PetSelectorView: View {
    @EnvironmentObject var petVM: PetViewModel
    var showAddButton: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(petVM.pets) { pet in
                    Button {
                        petVM.selectedPet = pet
                    } label: {
                        VStack(spacing: 4) {
                            PetAvatarView(pet: pet, size: 52)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            petVM.selectedPet?.id == pet.id ? Color.accentColor : Color.clear,
                                            lineWidth: 3
                                        )
                                )

                            Text(pet.name)
                                .font(.caption)
                                .fontWeight(petVM.selectedPet?.id == pet.id ? .semibold : .regular)
                                .foregroundStyle(petVM.selectedPet?.id == pet.id ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(pet.name)")
                }
            }
            .padding(.horizontal)
        }
    }
}
