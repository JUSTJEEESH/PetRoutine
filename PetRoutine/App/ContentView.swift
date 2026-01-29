import SwiftUI

struct ContentView: View {
    @EnvironmentObject var petVM: PetViewModel
    @State private var selectedTab: AppTab = .today

    enum AppTab: String, CaseIterable {
        case today
        case pets
        case log
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "checkmark.circle.fill", value: .today) {
                TodayView()
            }

            Tab("Pets", systemImage: "pawprint.fill", value: .pets) {
                PetsListView()
            }

            Tab("Log", systemImage: "book.fill", value: .log) {
                LogView()
            }
        }
        .tint(.accentColor)
        .onAppear {
            petVM.fetchPets()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PetViewModel(persistence: .preview))
        .environmentObject(TaskViewModel(persistence: .preview))
        .environmentObject(JournalViewModel(persistence: .preview))
        .environmentObject(RoutineViewModel(persistence: .preview))
        .environmentObject(HouseholdViewModel(persistence: .preview))
        .environmentObject(StoreKitService.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
