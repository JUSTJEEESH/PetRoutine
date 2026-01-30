import SwiftUI

struct PetTimelineView: View {
    let pet: Pet
    @StateObject private var timelineVM = TimelineViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if timelineVM.events.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No History",
                        message: "Completed tasks, journal entries, and health records will appear here."
                    )
                } else {
                    List {
                        ForEach(timelineVM.events) { event in
                            HStack(spacing: 12) {
                                Image(systemName: event.icon)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.displayTitle)
                                        .font(.subheadline)
                                        .lineLimit(2)

                                    Text(event.date.mediumDateTimeString)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(pet.name)'s Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                timelineVM.fetchTimeline(for: pet.id)
            }
        }
    }
}
