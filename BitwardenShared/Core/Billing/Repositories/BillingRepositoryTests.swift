import BitwardenKitMocks
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
struct BillingRepositoryTests {
    // MARK: Properties

    let configService: MockConfigService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let storefrontService: MockStorefrontService
    let subject: DefaultBillingRepository
    let vaultRepository: MockVaultRepository

    // MARK: Setup

    init() {
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        storefrontService = MockStorefrontService()
        vaultRepository = MockVaultRepository()

        subject = DefaultBillingRepository(
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService,
            storefrontService: storefrontService,
            vaultRepository: vaultRepository,
        )
    }

    // MARK: Tests

    /// `isInAppUpgradeAvailable()` returns `true` when all conditions are met.
    @Test
    func isInAppUpgradeAvailable_allConditionsMet() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        stateService.isPremiumUpgradeEligibleResult = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the feature flag is disabled.
    @Test
    func isInAppUpgradeAvailable_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        storefrontService.isUSStorefrontReturnValue = true
        stateService.isPremiumUpgradeEligibleResult = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the storefront is not US.
    @Test
    func isInAppUpgradeAvailable_nonUSStorefront() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = false
        stateService.isPremiumUpgradeEligibleResult = true
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the user is not eligible for premium upgrade.
    @Test
    func isInAppUpgradeAvailable_notEligible() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        stateService.isPremiumUpgradeEligibleResult = false
        vaultRepository.hasMinimumCipherCountResult = .success(true)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` when the vault has fewer than the minimum cipher count.
    @Test
    func isInAppUpgradeAvailable_insufficientCipherCount() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        stateService.isPremiumUpgradeEligibleResult = true
        vaultRepository.hasMinimumCipherCountResult = .success(false)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
    }

    /// `isInAppUpgradeAvailable()` returns `false` and logs the error when `hasMinimumCipherCount` throws.
    @Test
    func isInAppUpgradeAvailable_cipherCountThrows() async {
        configService.featureFlagsBool[.premiumUpgradePath] = true
        storefrontService.isUSStorefrontReturnValue = true
        stateService.isPremiumUpgradeEligibleResult = true
        vaultRepository.hasMinimumCipherCountResult = .failure(BitwardenTestError.example)

        let result = await subject.isInAppUpgradeAvailable()

        #expect(!result)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }
}
