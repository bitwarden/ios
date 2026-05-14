import BitwardenKit
import Foundation

// MARK: - BillingRepository

/// A protocol for a `BillingRepository` which manages access to billing-related data
/// needed by the UI layer.
///
protocol BillingRepository { // sourcery: AutoMockable
    /// Returns `true` when the in-app premium upgrade path is available for the active user.
    ///
    /// Does **not** check banner dismissal -- callers that need that check must do so separately.
    ///
    /// - Returns: Whether the in-app premium upgrade path is available.
    ///
    func isInAppUpgradeAvailable() async -> Bool
}

// MARK: - DefaultBillingRepository

/// The default implementation of `BillingRepository`.
///
class DefaultBillingRepository: BillingRepository {
    // MARK: Properties

    /// The service used to manage feature flags.
    private let configService: ConfigService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to manage the app's state.
    private let stateService: BillingStateService

    /// The service used to retrieve App Store storefront information.
    private let storefrontService: StorefrontService

    /// The repository used to manage vault data.
    private let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Creates a new `DefaultBillingRepository`.
    ///
    /// - Parameters:
    ///   - configService: The service used to manage feature flags.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used to manage the app's state.
    ///   - storefrontService: The service used to retrieve App Store storefront information.
    ///   - vaultRepository: The repository used to manage vault data.
    ///
    init(
        configService: ConfigService,
        errorReporter: ErrorReporter,
        stateService: BillingStateService,
        storefrontService: StorefrontService,
        vaultRepository: VaultRepository,
    ) {
        self.configService = configService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.storefrontService = storefrontService
        self.vaultRepository = vaultRepository
    }

    // MARK: Methods

    func isInAppUpgradeAvailable() async -> Bool {
        guard await configService.getFeatureFlag(.premiumUpgradePath),
              await storefrontService.isUSStorefront(),
              await stateService.isPremiumUpgradeEligible()
        else { return false }
        do {
            guard try await vaultRepository
                .hasMinimumCipherCount(Constants.minimumPremiumUpgradeBannerCipherCount)
            else { return false }
        } catch {
            errorReporter.log(error: error)
            return false
        }
        return true
    }
}
