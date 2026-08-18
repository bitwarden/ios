import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests+CheckoutTests

extension BillingServiceTests {
    // MARK: Tests

    /// `createCheckoutSession()` propagates errors from the API service.
    @Test
    func createCheckoutSession_apiError() async throws {
        billingAPIService.createCheckoutSessionThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `createCheckoutSession()` does not mark the upgrade pending when the API call fails —
    /// nothing would ever be left to clear a pending mark set before an attempt actually began.
    @Test
    func createCheckoutSession_apiError_doesNotMarkPending() async throws {
        billingAPIService.createCheckoutSessionThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await subject.createCheckoutSession()
        }

        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `createCheckoutSession()` clears a stale `lastAttemptFailed` flag left over from a prior
    /// attempt before starting a new one.
    @Test
    func createCheckoutSession_clearsLastAttemptFailed() async throws {
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "https://checkout.stripe.com/session")!,
        )

        _ = try await subject.createCheckoutSession()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    /// `createCheckoutSession()` does not mark the upgrade pending when the returned URL fails
    /// the HTTPS check, for the same reason as the API-error case.
    @Test
    func createCheckoutSession_invalidUrl_doesNotMarkPending() async throws {
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "http://checkout.stripe.com/session")!,
        )

        await #expect(throws: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL uses HTTP scheme.
    @Test
    func createCheckoutSession_invalidUrl_http() async throws {
        let httpURL = URL(string: "http://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: httpURL,
        )

        await #expect(throws: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL has no scheme.
    @Test
    func createCheckoutSession_invalidUrl_noScheme() async throws {
        let noSchemeURL = URL(string: "checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: noSchemeURL,
        )

        await #expect(throws: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `createCheckoutSession()` marks the upgrade as pending — this is the only place that
    /// happens, so a `.premiumStatusChanged` push for an account that never started a checkout
    /// has nothing to act on.
    @Test
    func createCheckoutSession_marksPending() async throws {
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "https://checkout.stripe.com/session")!,
        )

        _ = try await subject.createCheckoutSession()

        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `createCheckoutSession()` returns the URL when it uses HTTPS scheme.
    @Test
    func createCheckoutSession_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: expectedURL,
        )

        let result = try await subject.createCheckoutSession()

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
        #expect(result == expectedURL)
    }

    /// `premiumCheckoutCanceled()` publishes `.canceled` and then resets the publisher value to nil.
    @Test
    func premiumCheckoutCanceled() async throws {
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumCheckoutCanceled()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.canceled])

        // After .canceled + nil are sent, a new subscriber should receive nothing (nil is filtered).
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }
        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// `premiumCheckoutCanceled()` clears the pending mark `createCheckoutSession()` made for
    /// this attempt — no attempt is actually in flight anymore once the user cancels.
    @Test
    func premiumCheckoutCanceled_clearsPending() async throws {
        stateService.premiumUpgradePendingResult = true

        await subject.premiumCheckoutCanceled()

        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// A subscriber connecting after `.pending` is emitted receives the pending status immediately
    /// (CurrentValueSubject replays the last value to new subscribers).
    @Test
    func premiumCheckoutStatusPublisher_lateSubscriberReceivesPendingStatus() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        var earlyStatuses = [PremiumCheckoutStatus]()
        let earlyCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { earlyStatuses.append($0) }

        await subject.premiumStatusChanged()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // Late subscriber connects after .pending was emitted and should receive it.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        try await waitForAsync { !lateStatuses.isEmpty }

        #expect(lateStatuses == [.pending])
        _ = earlyCancellable
        _ = lateCancellable
    }
}
