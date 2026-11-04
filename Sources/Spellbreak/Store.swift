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
    private var trialExpiryTask: Task<Void, Never>?
    private var isLoadingProducts = false

    /// Seven days. SPELLBREAK_TRIAL_SECONDS can shorten it to test the ending —
    /// only shorten: a debug lever must never become a way to stretch the trial.
    private let trialLength: TimeInterval = {
        let week: TimeInterval = 7 * 24 * 60 * 60
        guard let override = ProcessInfo.processInfo.environment["SPELLBREAK_TRIAL_SECONDS"]
            .flatMap({ TimeInterval($0) }), override.isFinite else { return week }
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

    deinit {
        transactionUpdates?.cancel()
        trialExpiryTask?.cancel()
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
        guard !isWorking else { return }
        guard let trialProduct, unlockProduct != nil else {
            await loadProducts()
            return
        }
        await purchase(trialProduct)
    }

    @MainActor
    func unlock() async {
        guard !isWorking else { return }
        guard let unlockProduct else {
            await loadProducts()
            return
        }
        await purchase(unlockProduct)
    }

    @MainActor
    func restore() async {
        guard !isWorking else { return }
        let wasAllowed = allowsScheduledBreaks
        isWorking = true
        defer { isWorking = false }
        problem = nil

        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            // Sign-in sheet closed; nothing to report
        } catch {
            problem = "App Store connection unavailable. Restore can resume later."
        }
        await refresh()
        if trialProduct == nil || unlockProduct == nil {
            await loadProducts()
        }
        announceUnlockIfNew(wasAllowed: wasAllowed)
    }

    @MainActor
    private func purchase(_ product: Product) async {
        guard !isWorking else { return }
        let wasAllowed = allowsScheduledBreaks
        isWorking = true
        defer { isWorking = false }
        problem = nil

        do {
            switch try await product.purchase() {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refresh()
                    announceUnlockIfNew(wasAllowed: wasAllowed)
                case .unverified:
                    problem = "Purchase verification could not complete."
                }
            case .pending:
                problem = "Purchase awaiting approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            problem = "Purchase unavailable right now."
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
        await MainActor.run {
            self.access = resolved
            self.scheduleTrialExpiryIfNeeded(for: resolved)
        }
    }

    @MainActor
    private func scheduleTrialExpiryIfNeeded(for current: Access) {
        trialExpiryTask?.cancel()
        trialExpiryTask = nil
        guard case .trial(let endsAt) = current else { return }

        let delay = max(0.1, endsAt.timeIntervalSinceNow)
        trialExpiryTask = Task { [weak self] in
            let nanos = UInt64(min(delay, 8 * 24 * 60 * 60) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    func loadProducts() async {
        let shouldStart = await MainActor.run { () -> Bool in
            guard !self.isLoadingProducts else { return false }
            self.isLoadingProducts = true
            return true
        }
        guard shouldStart else { return }
        defer {
            Task { @MainActor [weak self] in
                self?.isLoadingProducts = false
            }
        }

        do {
            let products = try await Product.products(for: [Store.trialProductID, Store.unlockProductID])
            await MainActor.run {
                self.trialProduct = products.first { $0.id == Store.trialProductID }
                self.unlockProduct = products.first { $0.id == Store.unlockProductID }
                self.problem = products.isEmpty ? "App Store did not respond. Purchases are unavailable right now." : nil
            }
        } catch {
            await MainActor.run {
                self.problem = "App Store connection unavailable. Purchases can resume later."
            }
        }
    }
}
