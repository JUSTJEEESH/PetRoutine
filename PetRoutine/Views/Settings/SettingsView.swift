import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @EnvironmentObject var householdVM: HouseholdViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @AppStorage("caregiverName") private var caregiverName = "Me"
    @State private var showingHousehold = false
    @State private var showingProPurchase = false

    var body: some View {
        NavigationStack {
            List {
                if !storeKit.proUnlocked {
                    Section {
                        Button {
                            showingProPurchase = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PetRoutine Pro")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Unlimited pets, sharing, iCloud sync, exports, widgets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Upgrade")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Section {
                        HStack {
                            Label("PetRoutine Pro", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.accent)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Your Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $caregiverName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                    if !storeKit.proUnlocked {
                        Text("iCloud sync requires PetRoutine Pro")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Household") {
                    Button {
                        showingHousehold = true
                    } label: {
                        Label("Manage Household", systemImage: "person.3")
                    }
                    if !storeKit.proUnlocked {
                        Text("Household sharing requires PetRoutine Pro")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notifications") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Notification Settings", systemImage: "bell")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingHousehold) {
                HouseholdView()
            }
            .sheet(isPresented: $showingProPurchase) {
                ProPurchaseView()
            }
        }
    }
}

struct ProPurchaseView: View {
    @EnvironmentObject var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("PetRoutine Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    ProFeatureRow(icon: "infinity", text: "Unlimited pets")
                    ProFeatureRow(icon: "person.3.fill", text: "Household sharing")
                    ProFeatureRow(icon: "clock.badge.checkmark", text: "Temporary caregivers")
                    ProFeatureRow(icon: "icloud.fill", text: "iCloud sync")
                    ProFeatureRow(icon: "doc.fill", text: "PDF exports")
                    ProFeatureRow(icon: "square.grid.2x2.fill", text: "Home screen widgets")
                }
                .padding()

                if let product = storeKit.products.first {
                    Button {
                        Task {
                            let success = await storeKit.purchase()
                            if success { dismiss() }
                        }
                    } label: {
                        HStack {
                            if storeKit.purchaseInProgress {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Buy for \(product.displayPrice)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(storeKit.purchaseInProgress)
                    .padding(.horizontal)

                    Text("One-time purchase. No subscription.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView("Loading...")
                }

                Button("Restore Purchases") {
                    Task { await storeKit.restorePurchases() }
                }
                .font(.subheadline)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.accent)
            Text(text)
                .font(.body)
        }
    }
}
