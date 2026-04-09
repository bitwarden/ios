import BitwardenKit
import BitwardenShared
import TestHelpers
import XCTest

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        // Apply default appearances for snapshot tests.
        UI.applyDefaultAppearances()
    }

    /// Executes any logic that should be applied before each test runs.
    ///
    @MainActor
    override open func setUp() {
        super.setUp()
        UI.animated = false
        UI.sizeCategory = .large
    }

    /// Executes any logic that should be applied after each test runs.
    ///
    override open func tearDown() {
        super.tearDown()
        UI.animated = false
    }
}
