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

    // MARK: Tests

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

    /// `isPremiumUpgradeEligible()` returns `false` when user has premium.
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
}
