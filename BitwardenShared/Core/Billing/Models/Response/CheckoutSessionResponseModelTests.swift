import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CheckoutSessionResponseModelTests

class CheckoutSessionResponseModelTests: BitwardenTestCase {
    // MARK: Init

    /// `init(checkoutSessionUrl:)` sets the corresponding values.
    func test_init() {
        let subject = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "https://checkout.stripe.com/c/pay/test_session_123")!,
        )
        XCTAssertEqual(subject.checkoutSessionUrl, URL(string: "https://checkout.stripe.com/c/pay/test_session_123")!)
    }

    // MARK: Decoding

    /// Validates decoding the `checkoutSession` fixture.
    func test_decode() throws {
        let json = APITestData.checkoutSession.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(CheckoutSessionResponseModel.self, from: json)
        XCTAssertEqual(subject.checkoutSessionUrl, URL(string: "https://checkout.stripe.com/c/pay/test_session_123")!)
    }
}
