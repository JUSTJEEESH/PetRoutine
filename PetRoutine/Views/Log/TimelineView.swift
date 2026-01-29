import SwiftUI

struct TimelineView: View {
    let petID: UUID
    let petName: String

    @StateObject private var timelineVM = TimelineViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if timelineVM.events.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No History Yet",
                        message: "Complete tasks or add journal entries to see the timeline."
                    )
                } else {
                    timelineList
                }
            }
            .navigationTitle("\(petName) Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                timelineVM.fetchTimeline(for: petID)
            }
        }
    }

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let grouped = groupedByDate(timelineVM.events)

                ForEach(grouped, id: \.date) { group in
                    Section {
                        ForEach(group.events) { event in
                            TimelineEventRow(event: event)
                        }
                    } header: {
                        HStack {
                            Text(group.date.isToday ? "Today" : group.date.shortDateString)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    private struct DateGroup {
        let date: Date
        let events: [TimelineEvent]
    }

    private func groupedByDate(_ events: [TimelineEvent]) -> [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.date)
        }
        return grouped
            .map { DateGroup(date: $0.key, events: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: event.icon)
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayTitle)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(event.date.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
