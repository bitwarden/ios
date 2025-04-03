import TestHelpers
import XCTest

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        TestDataHelpers.defaultBundle = Bundle(for: Self.self)
    }
}
