import XCTest

@testable import BitwardenShared

// MARK: - AppContextTests

class AppContextTests: BitwardenTestCase {
    // MARK: Tests

    /// `isAppIntent()` returns whether the context is from an `AppIntent`.
    func test_isAppIntent() {
        XCTAssertFalse(AppContext.mainApp.isAppIntent())
        XCTAssertFalse(AppContext.appExtension.isAppIntent())
        XCTAssertTrue(AppContext.appIntent(.lockAll).isAppIntent())
    }

    /// `isAppIntentAction(_:)` returns whether the context is from an `AppIntent` with the specified action.
    func test_isAppIntentAction() {
        XCTAssertFalse(AppContext.mainApp.isAppIntentAction(.lockAll))
        XCTAssertFalse(AppContext.appExtension.isAppIntentAction(.lockAll))
        XCTAssertTrue(AppContext.appIntent(.lockAll).isAppIntentAction(.lockAll))
    }
}
