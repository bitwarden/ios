import BitwardenKit
import TestHelpers
import XCTest

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        // Apply default appearances for snapshot tests.
        UI.applyDefaultAppearances()
    }

    @MainActor
    override open func setUp() {
        super.setUp()
        UI.animated = false
        UI.sizeCategory = .large
    }

    override open func tearDown() {
        super.tearDown()
        UI.animated = false
    }
}
