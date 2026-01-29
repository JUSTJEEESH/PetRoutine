import StoreKit
import SwiftUI

@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    static let proProductID = "com.petroutine.pro"

    @Published private(set) var proUnlocked: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress: Bool = false

    private var transactionListener: Task<Void, Never>?

    init() {
        proUnlocked = UserDefaults.standard.bool(forKey: "proUnlocked")
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.proProductID])
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
        }
    }

    func purchase() async -> Bool {
        guard let product = products.first else { return false }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlockPro()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result),
                   transaction.productID == Self.proProductID {
                    unlockPro()
                    return
                }
            }
        } catch {
            print("Restore failed: \(error.localizedDescription)")
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result),
                   transaction.productID == StoreKitService.proProductID {
                    await self?.unlockPro()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.notAvailableInStorefront
        case .verified(let value):
            return value
        }
    }

    private func unlockPro() {
        proUnlocked = true
        UserDefaults.standard.set(true, forKey: "proUnlocked")
    }
}
