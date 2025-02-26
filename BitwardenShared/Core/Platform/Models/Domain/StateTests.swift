import XCTest

@testable import BitwardenShared

class StateTests: BitwardenTestCase {
    // MARK: Tests

    /// `init()` initializes the state with the provided list of accounts.
    func test_init_account() {
        let subject = State(accounts: ["1": .fixture()], activeUserId: "1")

        XCTAssertEqual(subject.accounts, ["1": .fixture()])
        XCTAssertEqual(subject.activeUserId, "1")
    }

    /// `init()` initializes the state with an empty account list by default.
    func test_init_defaultValues() {
        let subject = State()

        XCTAssertTrue(subject.accounts.isEmpty)
        XCTAssertNil(subject.activeUserId)
    }
}
