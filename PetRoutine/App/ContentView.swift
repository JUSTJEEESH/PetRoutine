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
            TodayView()
                .tag(AppTab.today)
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }

            PetsListView()
                .tag(AppTab.pets)
                .tabItem {
                    Label("Pets", systemImage: "pawprint.fill")
                }

            LogView()
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", systemImage: "book.fill")
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
