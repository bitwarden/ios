// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - StateServiceBillingStateServiceTests

@MainActor
struct StateServiceBillingStateServiceTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let errorReporter: MockErrorReporter
    let timeProvider: MockTimeProvider
    let subject: DefaultStateService

    // MARK: Setup

    init() {
        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.currentTime)

        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: DataStore(errorReporter: MockErrorReporter(), storeType: .memory),
            errorReporter: errorReporter,
            keychainRepository: MockKeychainRepository(),
            timeProvider: timeProvider,
            userSessionKeychainRepository: MockUserSessionKeychainRepository(),
        )
    }

    // MARK: Premium Upgrade Banner

    /// `getPremiumUpgradeBannerDismissed(userId:)` returns whether the Premium upgrade banner has been dismissed.
    @Test
    func getPremiumUpgradeBannerDismissed() async throws {
        await subject.addAccount(.fixture())
        var hasDismissedBanner = try await subject.getPremiumUpgradeBannerDismissed(userId: nil)
        #expect(!hasDismissedBanner)

        appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] = true
        hasDismissedBanner = try await subject.getPremiumUpgradeBannerDismissed(userId: nil)
        #expect(hasDismissedBanner)
    }

    /// `getPremiumUpgradeBannerDismissed(userId:)` throws errors if no user exists.
    @Test
    func getPremiumUpgradeBannerDismissed_error() async {
        await #expect(throws: StateServiceError.noActiveAccount) {
            _ = try await subject.getPremiumUpgradeBannerDismissed(userId: nil)
        }
    }

    /// `isPremiumUpgradeBannerDismissed()` returns `true` when the banner has been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_true() async {
        await subject.addAccount(.fixture())
        appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] = true

        let isDismissed = await subject.isPremiumUpgradeBannerDismissed()
        #expect(isDismissed)
    }

    /// `isPremiumUpgradeBannerDismissed()` returns `false` when the banner has not been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_false() async {
        await subject.addAccount(.fixture())
        appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] = false

        let isDismissed = await subject.isPremiumUpgradeBannerDismissed()
        #expect(!isDismissed)
    }

    /// `isPremiumUpgradeEligible()` returns `true` when user is free and account is 7+ days old.
    @Test
    func isPremiumUpgradeEligible_true() async {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)
        timeProvider.timeConfig = .mockTime(fixedDate)
        let creationDate = fixedDate.addingTimeInterval(-Constants.premiumUpgradeBannerAccountAge - 1)
        await subject.addAccount(.fixture(profile: .fixture(
            creationDate: creationDate,
            hasPremiumPersonally: false,
        )))

        let isEligible = await subject.isPremiumUpgradeEligible()
        #expect(isEligible)
    }

    /// `isPremiumUpgradeEligible()` returns `false` when user has Premium.
    @Test
    func isPremiumUpgradeEligible_hasPremium() async {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)
        timeProvider.timeConfig = .mockTime(fixedDate)
        let creationDate = fixedDate.addingTimeInterval(-Constants.premiumUpgradeBannerAccountAge - 1)
        await subject.addAccount(.fixture(profile: .fixture(
            creationDate: creationDate,
            hasPremiumPersonally: true,
        )))

        let isEligible = await subject.isPremiumUpgradeEligible()
        #expect(!isEligible)
    }

    /// `isPremiumUpgradeEligible()` returns `true` even when the banner has been dismissed,
    /// since dismissal is a separate concern checked via `isPremiumUpgradeBannerDismissed()`.
    @Test
    func isPremiumUpgradeEligible_bannerDismissedDoesNotAffectEligibility() async {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)
        timeProvider.timeConfig = .mockTime(fixedDate)
        let creationDate = fixedDate.addingTimeInterval(-Constants.premiumUpgradeBannerAccountAge - 1)
        await subject.addAccount(.fixture(profile: .fixture(
            creationDate: creationDate,
            hasPremiumPersonally: false,
        )))
        appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] = true

        let isEligible = await subject.isPremiumUpgradeEligible()
        #expect(isEligible)
    }

    /// `isPremiumUpgradeEligible()` returns `false` when account is less than 7 days old.
    @Test
    func isPremiumUpgradeEligible_accountTooNew() async {
        let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)
        timeProvider.timeConfig = .mockTime(fixedDate)
        let creationDate = fixedDate.addingTimeInterval(-Constants.premiumUpgradeBannerAccountAge + 1)
        await subject.addAccount(.fixture(profile: .fixture(
            creationDate: creationDate,
            hasPremiumPersonally: false,
        )))

        let isEligible = await subject.isPremiumUpgradeEligible()
        #expect(!isEligible)
    }

    /// `isPremiumUpgradeEligible()` returns `false` when account has no creation date.
    @Test
    func isPremiumUpgradeEligible_noCreationDate() async {
        await subject.addAccount(.fixture(profile: .fixture(
            creationDate: nil,
            hasPremiumPersonally: false,
        )))

        let isEligible = await subject.isPremiumUpgradeEligible()
        #expect(!isEligible)
    }

    /// `setPremiumUpgradeBannerDismissed(_:)` sets whether the Premium upgrade banner has been dismissed.
    @Test
    func setPremiumUpgradeBannerDismissed() async throws {
        await subject.addAccount(.fixture())
        try await subject.setPremiumUpgradeBannerDismissed(true, userId: nil)
        #expect(appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] == true)

        try await subject.setPremiumUpgradeBannerDismissed(false, userId: nil)
        #expect(appSettingsStore.premiumUpgradeBannerDismissedByUserId["1"] == false)
    }

    /// `setPremiumUpgradeBannerDismissed(_:userId:)` throws errors if no user exists.
    @Test
    func setPremiumUpgradeBannerDismissed_error() async {
        await #expect(throws: StateServiceError.noActiveAccount) {
            try await subject.setPremiumUpgradeBannerDismissed(true, userId: nil)
        }
    }

    // MARK: Premium Upgrade Pending

    /// `getPremiumUpgradePending()` returns `false` when no value has been set.
    @Test
    func getPremiumUpgradePending_defaultsFalse() async throws {
        await subject.addAccount(.fixture())

        let result = try await subject.getPremiumUpgradePending()
        #expect(!result)
    }

    /// `setPremiumUpgradePending(_:)` persists the value for the active account.
    @Test
    func setPremiumUpgradePending() async throws {
        await subject.addAccount(.fixture())

        try await subject.setPremiumUpgradePending(true)
        #expect(appSettingsStore.premiumUpgradePendingByUserId["1"] == true)

        try await subject.setPremiumUpgradePending(false)
        #expect(appSettingsStore.premiumUpgradePendingByUserId["1"] == false)
    }

    /// `getPremiumUpgradeLastSyncAttemptFailed()` returns `false` when no value has been set.
    @Test
    func getPremiumUpgradeLastSyncAttemptFailed_defaultsFalse() async throws {
        await subject.addAccount(.fixture())

        let result = try await subject.getPremiumUpgradeLastSyncAttemptFailed()
        #expect(!result)
    }

    /// `setPremiumUpgradeLastSyncAttemptFailed(_:)` persists the value for the active account.
    @Test
    func setPremiumUpgradeLastSyncAttemptFailed() async throws {
        await subject.addAccount(.fixture())

        try await subject.setPremiumUpgradeLastSyncAttemptFailed(true)
        #expect(appSettingsStore.premiumUpgradeLastSyncAttemptFailedByUserId["1"] == true)

        try await subject.setPremiumUpgradeLastSyncAttemptFailed(false)
        #expect(appSettingsStore.premiumUpgradeLastSyncAttemptFailedByUserId["1"] == false)
    }

    /// `getPremiumUpgradePending(userId:)` and `setPremiumUpgradePending(_:userId:)` operate on the
    /// given account regardless of which account is currently active.
    @Test
    func premiumUpgradePending_explicitUserId_notActiveAccount() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))
        try await subject.setActiveAccount(userId: "1")

        try await subject.setPremiumUpgradePending(true, userId: "2")

        let activeAccountPending = try await subject.getPremiumUpgradePending()
        let otherAccountPending = try await subject.getPremiumUpgradePending(userId: "2")
        #expect(!activeAccountPending)
        #expect(otherAccountPending)
    }

    // MARK: Subscription Attention Card

    /// `getSubscriptionAttentionCardVisible()` returns `false` when no value has been set.
    @Test
    func getSubscriptionAttentionCardVisible_defaultsFalse() async throws {
        await subject.addAccount(.fixture())

        let result = try await subject.getSubscriptionAttentionCardVisible()
        #expect(!result)
    }

    /// `getSubscriptionAttentionCardVisible()` returns `true` after `setSubscriptionAttentionCardVisible(true)`.
    @Test
    func getSubscriptionAttentionCardVisible_true() async throws {
        await subject.addAccount(.fixture())
        try await subject.setSubscriptionAttentionCardVisible(true)

        let result = try await subject.getSubscriptionAttentionCardVisible()
        #expect(result)
    }

    /// `getSubscriptionAttentionCardVisible()` returns `false` after `setSubscriptionAttentionCardVisible(false)`.
    @Test
    func getSubscriptionAttentionCardVisible_false() async throws {
        await subject.addAccount(.fixture())
        try await subject.setSubscriptionAttentionCardVisible(false)

        let result = try await subject.getSubscriptionAttentionCardVisible()
        #expect(!result)
    }

    // MARK: Upgraded to Premium Card

    /// `getUpgradedToPremiumActionCardVisible()` returns `false` when no value has been set.
    @Test
    func getUpgradedToPremiumActionCardVisible_defaultsFalse() async throws {
        await subject.addAccount(.fixture())
        let result = try await subject.getUpgradedToPremiumActionCardVisible()
        #expect(!result)
    }

    /// `getUpgradedToPremiumActionCardVisible()` returns the stored value for the active account.
    @Test
    func getUpgradedToPremiumActionCardVisible_storedValue() async throws {
        await subject.addAccount(.fixture())
        appSettingsStore.upgradedToPremiumCardVisibleByUserId["1"] = true

        let result = try await subject.getUpgradedToPremiumActionCardVisible()
        #expect(result)
    }

    /// `getUpgradedToPremiumActionCardVisible()` throws when there is no active account.
    @Test
    func getUpgradedToPremiumActionCardVisible_noActiveAccount() async {
        await #expect(throws: StateServiceError.noActiveAccount) {
            _ = try await subject.getUpgradedToPremiumActionCardVisible()
        }
    }

    /// `setUpgradedToPremiumActionCardVisible(_:)` persists the value for the active account.
    @Test
    func setUpgradedToPremiumActionCardVisible() async throws {
        await subject.addAccount(.fixture())

        try await subject.setUpgradedToPremiumActionCardVisible(true)
        #expect(appSettingsStore.upgradedToPremiumCardVisibleByUserId["1"] == true)

        try await subject.setUpgradedToPremiumActionCardVisible(false)
        #expect(appSettingsStore.upgradedToPremiumCardVisibleByUserId["1"] == false)
    }

    /// `getUpgradedToPremiumActionCardVisible(userId:)` and
    /// `setUpgradedToPremiumActionCardVisible(_:userId:)` operate on the given account regardless
    /// of which account is currently active.
    @Test
    func upgradedToPremiumActionCardVisible_explicitUserId_notActiveAccount() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))
        try await subject.setActiveAccount(userId: "1")

        try await subject.setUpgradedToPremiumActionCardVisible(true, userId: "2")

        let activeAccountVisible = try await subject.getUpgradedToPremiumActionCardVisible()
        let otherAccountVisible = try await subject.getUpgradedToPremiumActionCardVisible(userId: "2")
        #expect(!activeAccountVisible)
        #expect(otherAccountVisible)
    }
}
