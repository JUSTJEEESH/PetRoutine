import SwiftUI

struct PetsListView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var storeKit: StoreKitService
    @State private var showingAddPet = false
    @State private var showingProPrompt = false

    var body: some View {
        NavigationStack {
            Group {
                if petVM.pets.isEmpty {
                    EmptyStateView(
                        icon: "pawprint.fill",
                        title: "No Pets Yet",
                        message: "Add your first pet to get started.",
                        buttonTitle: "Add Pet",
                        action: { showingAddPet = true }
                    )
                } else {
                    List {
                        ForEach(petVM.pets) { pet in
                            NavigationLink(value: pet) {
                                PetListRow(pet: pet)
                            }
                        }
                        .onDelete(perform: deletePets)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pets")
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(pet: pet)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if petVM.canAddPet {
                            showingAddPet = true
                        } else {
                            showingProPrompt = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPet) {
                AddPetView()
            }
            .alert("Upgrade to Pro", isPresented: $showingProPrompt) {
                Button("OK") {}
            } message: {
                Text("The free version supports 1 pet. Upgrade to PetRoutine Pro for unlimited pets.")
            }
        }
    }

    private func deletePets(at offsets: IndexSet) {
        for index in offsets {
            petVM.deletePet(petVM.pets[index])
        }
    }
}

// MARK: - Pet List Row

struct PetListRow: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: 14) {
            PetAvatarView(pet: pet, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Label(pet.petType.displayName, systemImage: pet.petType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(pet.ageCategory.displayName(for: pet.petType))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
