import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PortalUrlResponseModelTests

class PortalUrlResponseModelTests: BitwardenTestCase {
    // MARK: Init

    /// `init(url:)` sets the corresponding values.
    func test_init() {
        let subject = PortalUrlResponseModel(
            url: URL(string: "https://billing.stripe.com/p/session/test_portal_456")!,
        )
        XCTAssertEqual(subject.url, URL(string: "https://billing.stripe.com/p/session/test_portal_456")!)
    }

    // MARK: Decoding

    /// Validates decoding the `portalUrl` fixture.
    func test_decode() throws {
        let json = APITestData.portalUrl.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(PortalUrlResponseModel.self, from: json)
        XCTAssertEqual(subject.url, URL(string: "https://billing.stripe.com/p/session/test_portal_456")!)
    }
}
