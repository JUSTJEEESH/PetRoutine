import SwiftUI

struct LogView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showingAddEntry = false
    @State private var showingTimeline = false

    var body: some View {
        NavigationStack {
            Group {
                if petVM.pets.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "No Pets Yet",
                        message: "Add a pet first to start logging care notes."
                    )
                } else if let pet = petVM.selectedPet {
                    VStack(spacing: 0) {
                        PetSelectorView()
                            .padding(.vertical, 8)

                        if journalVM.entries.isEmpty {
                            EmptyStateView(
                                icon: "note.text",
                                title: "No Log Entries",
                                message: "Add notes, photos, and observations for \(pet.name).",
                                buttonTitle: "Add Entry",
                                action: { showingAddEntry = true }
                            )
                        } else {
                            List {
                                ForEach(journalVM.entries) { entry in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(entry.text)
                                            .font(.body)
                                            .lineLimit(3)

                                        HStack {
                                            Text(entry.createdAt.mediumDateTimeString)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            if entry.photoData != nil {
                                                Image(systemName: "photo.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                .onDelete(perform: deleteEntries)
                            }
                            .listStyle(.plain)
                        }
                    }
                    .onChange(of: petVM.selectedPet?.id) { _, newID in
                        if let id = newID {
                            journalVM.fetchEntries(for: id)
                        }
                    }
                    .onAppear {
                        journalVM.fetchEntries(for: pet.id)
                    }
                }
            }
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingTimeline = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .disabled(petVM.selectedPet == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(petVM.selectedPet == nil)
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                if let pet = petVM.selectedPet {
                    AddJournalEntryView(petID: pet.id)
                }
            }
            .sheet(isPresented: $showingTimeline) {
                if let pet = petVM.selectedPet {
                    PetTimelineView(pet: pet)
                }
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            journalVM.deleteEntry(journalVM.entries[index])
        }
    }
}
