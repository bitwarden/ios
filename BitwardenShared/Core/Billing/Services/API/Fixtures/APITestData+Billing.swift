import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Checkout Session

    static let checkoutSession = APITestData(data: Data("""
    {
        "checkoutSessionUrl": "https://checkout.stripe.com/c/pay/test_session_123"
    }
    """.utf8))

    // MARK: Portal URL

    static let portalUrl = APITestData(data: Data("""
    {
        "url": "https://billing.stripe.com/p/session/test_portal_456"
    }
    """.utf8))
}

// swiftlint:enable missing_docs
