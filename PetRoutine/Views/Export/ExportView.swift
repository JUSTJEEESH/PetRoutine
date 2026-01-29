import SwiftUI

struct ExportView: View {
    let pet: Pet

    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var includeFeedingHistory = true
    @State private var includeMedications = true
    @State private var includeLogs = true
    @State private var pdfData: Data?
    @State private var showingShareSheet = false
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Report Contents") {
                    Toggle("Feeding History", isOn: $includeFeedingHistory)
                    Toggle("Medications", isOn: $includeMedications)
                    Toggle("Journal Logs", isOn: $includeLogs)
                }

                Section {
                    Button {
                        generatePDF()
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                            } else {
                                Label("Generate PDF", systemImage: "doc.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isGenerating)
                }

                if pdfData != nil {
                    Section {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
            .onAppear {
                taskVM.fetchTasks(for: pet.id)
                journalVM.fetchEntries(for: pet.id)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true

        var sections: [(title: String, rows: [(label: String, value: String)])] = []

        if includeFeedingHistory {
            let feedingTasks = taskVM.tasks.filter { $0.taskType == .feeding }
            var rows: [(String, String)] = []
            for task in feedingTasks {
                let history = taskVM.completionHistory(for: task, limit: 50)
                for completion in history {
                    rows.append((
                        completion.completedAt.mediumDateTimeString,
                        "\(task.name) — \(completion.caregiverName)"
                    ))
                }
            }
            if !rows.isEmpty {
                sections.append((title: "Feeding History", rows: rows))
            }
        }

        if includeMedications {
            let medTasks = taskVM.tasks.filter { $0.taskType == .medication }
            var rows: [(String, String)] = []
            for task in medTasks {
                let history = taskVM.completionHistory(for: task, limit: 50)
                for completion in history {
                    rows.append((
                        completion.completedAt.mediumDateTimeString,
                        "\(task.name) — \(completion.caregiverName)"
                    ))
                }
            }
            if !rows.isEmpty {
                sections.append((title: "Medication History", rows: rows))
            }
        }

        if includeLogs {
            var rows: [(String, String)] = []
            for entry in journalVM.entries {
                rows.append((
                    entry.createdAt.mediumDateTimeString,
                    entry.text
                ))
            }
            if !rows.isEmpty {
                sections.append((title: "Journal Entries", rows: rows))
            }
        }

        pdfData = ExportService.generatePDF(petName: pet.name, sections: sections)
        isGenerating = false

        if pdfData != nil {
            showingShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
