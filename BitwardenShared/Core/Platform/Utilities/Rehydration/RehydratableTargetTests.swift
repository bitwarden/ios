import XCTest

@testable import BitwardenShared

class RehydratableTargetTests: BitwardenTestCase {
    // MARK: Tests

    /// `getter:appRoute` returns the correct route for the given target.
    func test_appRoute() {
        XCTAssertEqual(
            RehydratableTarget.viewCipher(cipherId: "1").appRoute,
            AppRoute.tab(.vault(.viewItem(id: "1"))),
        )
        XCTAssertEqual(
            RehydratableTarget.editCipher(cipherId: "1").appRoute,
            AppRoute.tab(.vault(.editItemFrom(id: "1"))),
        )
    }
}
