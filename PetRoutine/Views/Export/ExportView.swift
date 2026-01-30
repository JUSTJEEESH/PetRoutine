import SwiftUI

struct ExportView: View {
    let pet: Pet
    @EnvironmentObject var taskVM: TaskViewModel
    @StateObject private var healthRecordVM = HealthRecordViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var pdfData: Data?
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Generate a PDF report for \(pet.name) including care tasks, health records, and vet information.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        generateReport()
                    } label: {
                        Label("Generate Report", systemImage: "doc.fill")
                    }
                }

                if pdfData != nil {
                    Section {
                        Button {
                            showingShare = true
                        } label: {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let data = pdfData {
                    ShareSheet(items: [data])
                }
            }
            .onAppear {
                healthRecordVM.fetchRecords(for: pet.id)
            }
        }
    }

    private func generateReport() {
        var sections: [(title: String, rows: [(label: String, value: String)])] = []

        // Pet info
        var petRows: [(String, String)] = [
            ("Type", pet.petType.displayName),
            ("Age", pet.ageCategory.displayName(for: pet.petType)),
        ]
        if let birthday = pet.birthday {
            petRows.append(("Birthday", birthday.shortDateString))
        }
        sections.append((title: "Pet Information", rows: petRows))

        // Tasks
        let petTasks = taskVM.allTasks.filter { $0.petIDs.contains(pet.id) }
        if !petTasks.isEmpty {
            let taskRows = petTasks.map { task -> (String, String) in
                let note = task.petNotes[pet.id.uuidString] ?? task.notes ?? ""
                return (task.name, "\(task.taskType.displayName) · \(task.frequencyType.displayName)\(note.isEmpty ? "" : " · \(note)")")
            }
            sections.append((title: "Care Tasks", rows: taskRows))
        }

        // Health records
        if !healthRecordVM.records.isEmpty {
            let healthRows = healthRecordVM.records.map { record -> (String, String) in
                var value = "\(record.recordType.displayName) · \(record.dateAdministered.shortDateString)"
                if let due = record.nextDueDate {
                    value += " · Next: \(due.shortDateString)"
                }
                return (record.name, value)
            }
            sections.append((title: "Health Records", rows: healthRows))
        }

        pdfData = ExportService.generatePDF(petName: pet.name, sections: sections)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
