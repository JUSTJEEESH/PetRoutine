import SwiftUI

struct PetSelectorView: View {
    @EnvironmentObject var petVM: PetViewModel
    var showAllOption: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if showAllOption {
                    Button {
                        petVM.showAllPets = true
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(petVM.showAllPets ? Color.accentColor : Color(.systemGray5))
                                    .frame(width: 52, height: 52)

                                Image(systemName: "pawprint.fill")
                                    .font(.title3)
                                    .foregroundStyle(petVM.showAllPets ? .white : .secondary)
                            }

                            Text("All")
                                .font(.caption)
                                .fontWeight(petVM.showAllPets ? .semibold : .regular)
                                .foregroundStyle(petVM.showAllPets ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show all pets")
                }

                ForEach(petVM.pets) { pet in
                    let isSelected = !petVM.showAllPets && petVM.selectedPet?.id == pet.id

                    Button {
                        petVM.showAllPets = false
                        petVM.selectedPet = pet
                    } label: {
                        VStack(spacing: 4) {
                            PetAvatarView(pet: pet, size: 52)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isSelected ? Color.accentColor : Color.clear,
                                            lineWidth: 3
                                        )
                                )

                            Text(pet.name)
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .primary : .secondary)
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
