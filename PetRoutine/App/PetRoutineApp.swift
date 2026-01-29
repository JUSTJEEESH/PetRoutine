import SwiftUI

@main
struct PetRoutineApp: App {
    let persistence = PersistenceController.shared

    @StateObject private var petVM = PetViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var journalVM = JournalViewModel()
    @StateObject private var routineVM = RoutineViewModel()
    @StateObject private var householdVM = HouseholdViewModel()
    @StateObject private var storeKit = StoreKitService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(petVM)
                .environmentObject(taskVM)
                .environmentObject(journalVM)
                .environmentObject(routineVM)
                .environmentObject(householdVM)
                .environmentObject(storeKit)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .task {
                    _ = await NotificationService.shared.requestAuthorization()
                }
        }
    }
}
