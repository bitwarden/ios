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

    // MARK: Plans

    static let premiumPlanResponse = APITestData(data: Data("""
    {
        "name": "Premium",
        "legacyYear": null,
        "available": true,
        "seat": {
            "stripePriceId": "premium-annually-2026",
            "price": 19.80,
            "provided": 0
        },
        "storage": {
            "stripePriceId": "personal-storage-gb-annually",
            "price": 4,
            "provided": 5
        }
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
