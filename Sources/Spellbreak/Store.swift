//
//  Store.swift
//  Spellbreak
//
//  The App Store unlock: a free week, then one purchase. Scheduled breaks are
//  what the unlock pays for — Test Break and Break Now always work.
//
//  App Store builds only (-DAPP_STORE, set by build-mas.sh). The website build
//  is always unlocked and never asks StoreKit anything.
//

import Foundation
import StoreKit

final class Store: ObservableObject {
    enum Access: Equatable {
        case checking              // StoreKit hasn't answered yet — never lock on a guess
        case notStarted
        case trial(endsAt: Date)
        case trialEnded
        case unlocked
    }

    /// Apple's sanctioned trial for a one-time unlock (App Review 3.1.1): a free
    /// non-consumable named "7-Day Trial". Its purchase date starts the clock, and
    /// as an App Store transaction it survives reinstalls and new Macs.
    static let trialProductID = "com.pabloalvarado.spellbreak.trial"
    static let unlockProductID = "com.pabloalvarado.spellbreak.unlock"

    static let didUnlockScheduledBreaks = Notification.Name("SpellbreakDidUnlockScheduledBreaks")

    @Published private(set) var access: Access
    @Published private(set) var trialProduct: Product?
    @Published private(set) var unlockProduct: Product?
    @Published private(set) var isWorking = false
    @Published private(set) var problem: String?

    private var transactionUpdates: Task<Void, Never>?

    /// Seven days. SPELLBREAK_TRIAL_SECONDS can shorten it to test the ending —
    /// only shorten: a debug lever must never become a way to stretch the trial.
    private let trialLength: TimeInterval = {
        let week: TimeInterval = 7 * 24 * 60 * 60
        guard let override = ProcessInfo.processInfo.environment["SPELLBREAK_TRIAL_SECONDS"]
            .flatMap({ TimeInterval($0) }) else { return week }
        return min(max(override, 1), week)
    }()

    init() {
        #if APP_STORE
        access = .checking
        // Purchases made elsewhere (another Mac, Family Sharing, a refund) land here
        transactionUpdates = Task.detached { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.refresh()
            await self?.loadProducts()
        }
        #else
        access = .unlocked
        #endif
    }

    /// `access`, reading an expired trial as ended without waiting for a refresh
    var currentAccess: Access {
        if case .trial(let endsAt) = access, Date() >= endsAt {
            return .trialEnded
        }
        return access
    }

    /// Scheduled breaks are what the unlock pays for. While StoreKit is still
    /// answering they're allowed: a slow App Store never locks anyone out.
    var allowsScheduledBreaks: Bool {
        switch currentAccess {
        case .checking, .trial, .unlocked: return true
        case .notStarted, .trialEnded: return false
        }
    }

    var trialDaysLeft: Int? {
        guard case .trial(let endsAt) = currentAccess else { return nil }
        return max(1, Int(ceil(endsAt.timeIntervalSinceNow / 86_400)))
    }

    // MARK: - Actions

    @MainActor
    func startTrial() async {
        guard let trialProduct else { return await loadProducts() }
        await purchase(trialProduct)
    }

    @MainActor
    func unlock() async {
        guard let unlockProduct else { return await loadProducts() }
        await purchase(unlockProduct)
    }

    @MainActor
    func restore() async {
        let wasAllowed = allowsScheduledBreaks
        isWorking = true
        defer { isWorking = false }
        problem = nil

        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            // They closed the sign-in sheet; nothing to say
        } catch {
            problem = "Couldn't reach the App Store to restore. Try again in a moment."
        }
        await refresh()
        announceUnlockIfNew(wasAllowed: wasAllowed)
    }

    @MainActor
    private func purchase(_ product: Product) async {
        let wasAllowed = allowsScheduledBreaks
        isWorking = true
        defer { isWorking = false }
        problem = nil

        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                }
                await refresh()
                announceUnlockIfNew(wasAllowed: wasAllowed)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            problem = "The purchase didn't go through. Try again in a moment."
        }
    }

    /// Starting the trial or unlocking should start breaks too — AppState listens
    @MainActor
    private func announceUnlockIfNew(wasAllowed: Bool) {
        guard !wasAllowed, allowsScheduledBreaks else { return }
        NotificationCenter.default.post(name: Store.didUnlockScheduledBreaks, object: nil)
    }

    // MARK: - StoreKit

    func refresh() async {
        var unlocked = false
        var trialStarted: Date?

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.revocationDate == nil else { continue }
            switch transaction.productID {
            case Store.unlockProductID:
                unlocked = true
            case Store.trialProductID:
                trialStarted = transaction.originalPurchaseDate
            default:
                break
            }
        }

        let resolved: Access
        if unlocked {
            resolved = .unlocked
        } else if let trialStarted {
            let endsAt = trialStarted.addingTimeInterval(trialLength)
            resolved = Date() < endsAt ? .trial(endsAt: endsAt) : .trialEnded
        } else {
            resolved = .notStarted
        }
        await MainActor.run { self.access = resolved }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Store.trialProductID, Store.unlockProductID])
            await MainActor.run {
                self.trialProduct = products.first { $0.id == Store.trialProductID }
                self.unlockProduct = products.first { $0.id == Store.unlockProductID }
                self.problem = products.isEmpty ? "The App Store didn't answer. Try again in a moment." : nil
            }
        } catch {
            await MainActor.run {
                self.problem = "Couldn't reach the App Store. Check your connection and try again."
            }
        }
    }
}
