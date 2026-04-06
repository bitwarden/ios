import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class BillingServiceTests: BitwardenTestCase {
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var subject: DefaultBillingService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        billingAPIService = MockBillingAPIService()
        subject = DefaultBillingService(billingAPIService: billingAPIService)
    }

    override func tearDown() {
        super.tearDown()

        billingAPIService = nil
        subject = nil
    }

    // MARK: Tests

    /// `createCheckoutSession()` returns the URL when it uses HTTPS scheme.
    func test_createCheckoutSession_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: expectedURL,
        )

        let result = try await subject.createCheckoutSession()

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
        XCTAssertEqual(result, expectedURL)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL uses HTTP scheme.
    func test_createCheckoutSession_invalidUrl_http() async throws {
        let httpURL = URL(string: "http://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: httpURL,
        )

        await assertAsyncThrows(error: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL has no scheme.
    func test_createCheckoutSession_invalidUrl_noScheme() async throws {
        let noSchemeURL = URL(string: "checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: noSchemeURL,
        )

        await assertAsyncThrows(error: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
    }

    /// `createCheckoutSession()` propagates errors from the API service.
    func test_createCheckoutSession_apiError() async throws {
        billingAPIService.createCheckoutSessionThrowableError = URLError(.notConnectedToInternet)

        await assertAsyncThrows {
            _ = try await subject.createCheckoutSession()
        }

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
    }
}
