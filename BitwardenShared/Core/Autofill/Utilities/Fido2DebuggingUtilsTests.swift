#if DEBUG
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

class Fido2DebuggingUtilsTests: BitwardenTestCase {
    // MARK: Tests

    /// `static describeAuthDataFlags(_:)` returns the formatted string successfully for the flags.
    func test_describeAuthDataFlags() {
        var authData: [UInt8] = []
        // add some 32 bytes
        let firstPart = Data((0 ..< 32).map { _ in 1 })
        authData.append(contentsOf: firstPart)
        authData.append(217)

        let result = Fido2DebuggingUtils.describeAuthDataFlags(Data(authData))
        XCTAssertEqual(result, "Flags: UP: 1 - UV: 0 - BE: 1 - BS: 1 - AD: 1 - ED: 1")
    }
}
#endif
