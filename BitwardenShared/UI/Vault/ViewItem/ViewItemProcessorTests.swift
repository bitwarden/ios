import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemProcessorTests

class ViewItemProcessorTests: BitwardenTestCase {
    // MARK: Propteries

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: ViewItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            vaultRepository: vaultRepository
        )
        subject = ViewItemProcessor(
            coordinator: coordinator,
            itemId: "id",
            services: services,
            state: ViewItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared() {
        let cipherItem = CipherView.fixture(
            id: "id",
            login: LoginView(
                username: "username",
                password: "password",
                passwordRevisionDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "Name",
            notes: "Notes",
            viewPassword: true
        )
        vaultRepository.cipherDetailsSubject.send(cipherItem)

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .data(.login(ViewLoginItemState(
            customFields: [],
            folder: nil,
            isPasswordVisible: true,
            name: "Name",
            notes: "Notes",
            password: "password",
            updatedDate: Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
            uris: [],
            username: "username"
        ))))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

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
        subject.state.loadingState = .data(.login(loginState))
        subject.receive(.passwordVisibilityPressed)

        loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(.login(loginState)))
    }
}
