import BitwardenKitMocks
import XCTest

@testable import BitwardenKit

class BundleExtensionsTests: BitwardenTestCase {
    func test_mockBundle_safariExtensionIdentifier() {
        let subject = MockBundle()

        XCTAssertEqual(subject.safariExtensionIdentifier, "com.8bit.bitwarden.safari-web-extension")
    }
}
