import XCTest

@testable import BitwardenShared

// MARK: - ViewItemProcessorTests

class ViewItemProcessorTests: BitwardenTestCase {
    // MARK: Propteries

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: ViewItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = ViewItemProcessor(
            coordinator: coordinator,
            itemId: "id",
            state: ViewItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive` with `.checkPasswordPressed` checks the password with the HIBP service.
    func test_receive_checkPasswordPressed() {
        subject.receive(.checkPasswordPressed)
        // TODO: BIT-1130 Assertion for check password service call
    }

    /// `receive` with `.copyPressed` copies the value with the pasteboard service.
    func test_receive_copyPressed() {
        subject.receive(.copyPressed(value: "value"))
        // TODO: BIT-1121 Assertion for pasteboard service
    }

    /// `receive` with `.dismissPressed` navigates to the `.dismiss` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive` with `.editPressed` navigates to the edit item route.
    func test_receive_editPressed() {
        subject.receive(.editPressed)
        // TODO: BIT-220 Assertion for edit route
    }

    /// `receive` with `.morePressed` presents the item options menu.
    func test_receive_morePressed() {
        subject.receive(.morePressed)
        // TODO: BIT-1131 Assertion for menu
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_passwordVisibilityPressed_withLoginState() {
        var loginState = ViewLoginItemState(
            isPasswordVisible: false,
            name: "name",
            updatedDate: Date()
        )
        subject.state.typeState = .login(loginState)
        subject.receive(.passwordVisibilityPressed)

        loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.typeState, .login(loginState))
    }
}
