import BitwardenKit
import Combine
import Foundation

// MARK: - BillingService

/// A protocol for a service used to manage billing operations.
///
protocol BillingService: AnyObject { // sourcery: AutoMockable
    /// Creates a checkout session for premium upgrade and returns the checkout URL.
    ///
    /// - Returns: A validated HTTPS URL for the checkout session.
    /// - Throws: `BillingError.invalidCheckoutUrl` if the URL is invalid or not HTTPS.
    ///
    func createCheckoutSession() async throws -> URL

    /// Gets the premium subscription plan details.
    ///
    /// - Returns: A `PremiumPlanResponseModel` containing the premium plan details.
    ///
    func getPremiumPlan() async throws -> PremiumPlanResponseModel

    /// Gets the user's subscription details.
    ///
    /// - Returns: A `BitwardenSubscriptionResponseModel` containing the subscription details.
    ///
    func getSubscription() async throws -> BitwardenSubscriptionResponseModel

    /// Notifies that the user canceled the Stripe checkout without completing payment,
    /// and publishes a `.canceled` status update.
    ///
    func premiumCheckoutCanceled()

    /// A publisher that emits the status of the premium checkout sync process.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Notifies that a premium status change was detected (via deep link or push notification),
    /// triggers a sync, and publishes status updates.
    ///
    func premiumStatusChanged() async
}

// MARK: - DefaultBillingService

/// The default implementation of `BillingService`.
///
class DefaultBillingService: BillingService {
    // MARK: Properties

    /// The API service used for billing requests.
    private let billingAPIService: BillingAPIService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Subject that emits the premium checkout sync status.
    private let premiumCheckoutStatusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()

    /// The service used to manage the app's state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    // MARK: Initialization

    /// Creates a new `DefaultBillingService`.
    ///
    /// - Parameters:
    ///   - billingAPIService: The API service used for billing requests.
    ///   - errorReporter: The service used to report non-fatal errors.
    ///   - stateService: The service used to manage the app's state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        billingAPIService: BillingAPIService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        syncService: SyncService,
    ) {
        self.billingAPIService = billingAPIService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

    func createCheckoutSession() async throws -> URL {
        let response = try await billingAPIService.createCheckoutSession()
        let url = response.checkoutSessionUrl
        // Ensure the checkout URL uses HTTPS to prevent man-in-the-middle attacks
        // when redirecting users to the payment provider.
        guard url.scheme == "https" else {
            throw BillingError.invalidCheckoutUrl
        }
        return url
    }

    func getPremiumPlan() async throws -> PremiumPlanResponseModel {
        try await billingAPIService.getPremiumPlan()
    }

    func getSubscription() async throws -> BitwardenSubscriptionResponseModel {
        try await billingAPIService.getSubscription()
    }

    func premiumCheckoutCanceled() {
        premiumCheckoutStatusSubject.send(.canceled)
    }

    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never> {
        premiumCheckoutStatusSubject.eraseToAnyPublisher()
    }

    func premiumStatusChanged() async {
        premiumCheckoutStatusSubject.send(.syncing)
        do {
            try await syncService.fetchSync(forceSync: false)
        } catch {
            errorReporter.log(error: error)
        }
        let hasPremium = await stateService.doesActiveAccountHavePremium()
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
    }
}
