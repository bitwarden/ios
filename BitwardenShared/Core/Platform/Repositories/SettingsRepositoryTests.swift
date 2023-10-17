import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()

        subject = DefaultSettingsRepository(stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }
}
