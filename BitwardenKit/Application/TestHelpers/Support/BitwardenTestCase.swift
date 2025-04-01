import TestHelpers
import XCTest

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        TestDataHelpers.bundleClass = Self.self
    }
}
