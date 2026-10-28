import Foundation
import XCTest

@testable import BitwardenShared

class TextToInsertKeyboardSessionTests: BitwardenTestCase {
    // MARK: Tests

    /// `requiresFocusAnchor` is `true` before iOS 27 and `false` on iOS 27 and later.
    func test_requiresFocusAnchor() {
        let isAtLeastiOS27 = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0),
        )
        XCTAssertEqual(TextToInsertKeyboardSession.requiresFocusAnchor, !isAtLeastiOS27)
    }
}
