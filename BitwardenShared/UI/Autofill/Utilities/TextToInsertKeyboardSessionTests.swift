import Foundation
import XCTest

@testable import BitwardenShared

class TextToInsertKeyboardSessionTests: BitwardenTestCase {
    // MARK: Tests

    /// `releasesFocusOnItemTap` is `false` before iOS 27 and `true` on iOS 27 and later.
    func test_releasesFocusOnItemTap() {
        let isAtLeastiOS27 = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0),
        )
        XCTAssertEqual(TextToInsertKeyboardSession.releasesFocusOnItemTap, isAtLeastiOS27)
    }
}
