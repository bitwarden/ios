import BitwardenSdk
import XCTest

@testable import BitwardenShared

class SendTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `sdkType` maps to the correct `BitwardenSdk.SendType` values.
    func test_sdkType() {
        XCTAssertEqual(SendType.text.sdkType, .text)
        XCTAssertEqual(SendType.file.sdkType, .file)
    }
}
