import XCTest

@testable import BitwardenShared

// MARK: - PendingAppIntentActionTests

class PendingAppIntentActionTests: BitwardenTestCase {
    // MARK: Tests

    /// `isLock()` returns whether the current action is `.lock`.
    func test_isLock() {
        XCTAssertTrue(PendingAppIntentAction.lock("1").isLock())
        XCTAssertFalse(PendingAppIntentAction.lockAll.isLock())
    }
}
