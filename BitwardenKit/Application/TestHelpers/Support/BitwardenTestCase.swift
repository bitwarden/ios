import BitwardenKitMocks
import TestHelpers
import XCTest

let bundle = Bundle(for: BitwardenTestCase.self)

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        TestDataHelpers.defaultBundle = BitwardenKitTests.bundle
    }
}
