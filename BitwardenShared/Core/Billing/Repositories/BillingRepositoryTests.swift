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

    /// `isInAppUpgradeAvailable()` returns `true` when the feature flag is enabled and the storefront is US.
    @Test
    func isInAppUpgradeAvailable_allConditionsMet() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true

        let result = await subject.isInAppUpgradeAvailable()

        #expect(result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the feature flag is disabled.
    @Test
    func isInAppUpgradeAvailable_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        storefrontService.isUSStorefrontReturnValue = true

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the storefront is not US.
    @Test
    func isInAppUpgradeAvailable_nonUSStorefront() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = false

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `true` when all conditions are met.
    @Test
    func isPremiumUpgradeBannerAvailable_allConditionsMet() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        billingStateService.isPremiumUpgradeEligibleReturnValue = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(result)
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

    /// `isPremiumUpgradeBannerAvailable()` returns `false` when the vault has fewer than the minimum cipher count.
    @Test
    func isPremiumUpgradeBannerAvailable_insufficientCipherCount() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        billingStateService.isPremiumUpgradeEligibleReturnValue = true
        vaultRepository.hasMinimumCipherCountResult = .success(false)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(!result)
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `false` when the storefront is not US.
    @Test
    func isPremiumUpgradeBannerAvailable_nonUSStorefront() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = false
        billingStateService.isPremiumUpgradeEligibleReturnValue = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(!result)
    }

    /// `isPremiumUpgradeBannerAvailable()` returns `false` when the user is not eligible for Premium upgrade.
    @Test
    func isPremiumUpgradeBannerAvailable_notEligible() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        billingStateService.isPremiumUpgradeEligibleReturnValue = false
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isPremiumUpgradeBannerAvailable()

        #expect(!result)
    }
}
