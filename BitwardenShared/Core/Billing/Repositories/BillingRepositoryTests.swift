import BitwardenKitMocks
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
struct BillingRepositoryTests {
    // MARK: Properties

    let billingStateService: MockBillingStateService
    let configService: MockConfigService
    let errorReporter: MockErrorReporter
    let storefrontService: MockStorefrontService
    let subject: DefaultBillingRepository
    let vaultRepository: MockVaultRepository

    // MARK: Setup

    init() {
        billingStateService = MockBillingStateService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        storefrontService = MockStorefrontService()
        vaultRepository = MockVaultRepository()

        subject = DefaultBillingRepository(
            billingStateService: billingStateService,
            configService: configService,
            errorReporter: errorReporter,
            storefrontService: storefrontService,
            vaultRepository: vaultRepository,
        )
    }

    // MARK: Tests

    /// `isInAppUpgradeAvailable()` returns `false` when the feature flag is disabled.
    @Test
    func isInAppUpgradeAvailable_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        storefrontService.isUSStorefrontReturnValue = true

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `true` only when the storefront is US.
    @Test(arguments: [
        (isUSStorefront: false, expectedResult: false),
        (isUSStorefront: true, expectedResult: true),
    ])
    func isInAppUpgradeAvailable_storefront(isUSStorefront: Bool, expectedResult: Bool) async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = isUSStorefront

        let result = await subject.isInAppUpgradeAvailable()

        #expect(result == expectedResult)
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `false` and logs the error when `hasMinimumCipherCount` throws.
    @Test
    func isPremiumUpgradeBannerAvailable_cipherCountThrows() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        billingStateService.isPremiumUpgradeEligibleReturnValue = true
        vaultRepository.hasMinimumCipherCountResult = .failure(BitwardenTestError.example)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(!result)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `true` only when the vault has the minimum cipher count,
    /// the user is eligible for Premium upgrade, and the storefront is US.
    @Test(arguments: [
        (hasMinimumCipherCount: false, isEligible: true, isUSStorefront: true, expectedResult: false),
        (hasMinimumCipherCount: true, isEligible: false, isUSStorefront: true, expectedResult: false),
        (hasMinimumCipherCount: true, isEligible: true, isUSStorefront: false, expectedResult: false),
        (hasMinimumCipherCount: true, isEligible: true, isUSStorefront: true, expectedResult: true),
    ])
    func isPremiumUpgradeBannerAvailable_conditions(
        hasMinimumCipherCount: Bool,
        isEligible: Bool,
        isUSStorefront: Bool,
        expectedResult: Bool,
    ) async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = isUSStorefront
        billingStateService.isPremiumUpgradeEligibleReturnValue = isEligible
        vaultRepository.hasMinimumCipherCountResult = .success(hasMinimumCipherCount)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(result == expectedResult)
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `false` when the feature flag is disabled.
    @Test
    func isPremiumUpgradeBannerAvailable_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        storefrontService.isUSStorefrontReturnValue = true
        billingStateService.isPremiumUpgradeEligibleReturnValue = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(!result)
    }
}
