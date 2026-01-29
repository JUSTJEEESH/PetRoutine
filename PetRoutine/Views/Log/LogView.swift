import SwiftUI

struct LogView: View {
    @EnvironmentObject var petVM: PetViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showingAddEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if petVM.pets.isEmpty {
                    EmptyStateView(
                        icon: "book.fill",
                        title: "No Pets Yet",
                        message: "Add a pet first to start keeping a journal."
                    )
                } else {
                    logContent
                }
            }
            .navigationTitle("Log")
            .toolbar {
                if !petVM.pets.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddEntry = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddJournalEntryView()
            }
        }
    }

    private var logContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if petVM.pets.count > 1 {
                    PetSelectorView()
                        .padding(.top, 8)
                }

                if journalVM.entries.isEmpty {
                    EmptyStateView(
                        icon: "note.text",
                        title: "No Entries Yet",
                        message: "Add a journal entry to start recording notes about your pet.",
                        buttonTitle: "Add Entry",
                        action: { showingAddEntry = true }
                    )
                    .frame(minHeight: 300)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(journalVM.entries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .onChange(of: petVM.selectedPet?.id) { _, newValue in
            journalVM.fetchEntries(for: newValue)
        }
        .onAppear {
            journalVM.fetchEntries(for: petVM.selectedPet?.id)
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.photoData != nil ? "photo.fill" : "note.text")
                    .foregroundStyle(.secondary)

                Text(entry.createdAt.mediumDateTimeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.text)
                .font(.body)

            if let photoData = entry.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete Entry?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                journalVM.deleteEntry(entry)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
