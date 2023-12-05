import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemProcessorTests

class ViewItemProcessorTests: BitwardenTestCase {
    // MARK: Propteries

    var coordinator: MockCoordinator<VaultItemRoute>!
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
        vaultRepository = nil
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

        let expectedState = LoginItemState(cipherView: cipherItem)!

        XCTAssertEqual(subject.state.loadingState, .data(.login(expectedState)))
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

    func test_receive_customFieldVisiblePressed_withValidField() throws {
        let customField1 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 1",
            type: .hidden,
            value: "value 1"
        )
        let customField2 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 2",
            type: .hidden,
            value: "value 2"
        )
        let customField3 = CustomFieldState(
            isPasswordVisible: false,
            linkedIdType: nil,
            name: "name 3",
            type: .hidden,
            value: "value 3"
        )
        var loginState = LoginItemState(
            cipherView: CipherView.loginFixture()
        )!
        loginState.properties.customFields = [
            customField1,
            customField2,
            customField3,
        ]
        let state = ViewItemState(
            loadingState: .data(.login(
                loginState
            ))
        )
        subject.state = state

        subject.receive(.customFieldVisibilityPressed(customField2))
        let newLoadingState = try XCTUnwrap(subject.state.loadingState.wrappedData)
        guard case let ViewItemState.ItemTypeState.login(alteredState) = newLoadingState else {
            XCTFail("ViewItemState has incorrect value: \(newLoadingState)")
            return
        }
        let customFields = alteredState.properties.customFields
        XCTAssertEqual(customFields.count, 3)
        XCTAssertFalse(customFields[0].isPasswordVisible)
        XCTAssertTrue(customFields[1].isPasswordVisible)
        XCTAssertFalse(customFields[2].isPasswordVisible)
    }

    /// `receive` with `.dismissPressed` navigates to the `.dismiss` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive` with `.editPressed` has no change when the state is loading.
    func test_receive_editPressed_loading() {
        subject.receive(.editPressed)
        XCTAssertEqual(coordinator.routes, [])
    }

    /// `receive` with `.editPressed`with data navigates to the edit item route.
    func test_receive_editPressed_data() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        let loginState = LoginItemState(cipherView: cipherView)!
        subject.state.loadingState = .data(.login(loginState))
        subject.receive(.editPressed)
        XCTAssertEqual(coordinator.routes, [.editItem(cipher: cipherView)])
    }

    /// `receive` with `.morePressed` presents the item options menu.
    func test_receive_morePressed() {
        subject.receive(.morePressed)
        // TODO: BIT-1131 Assertion for menu
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_passwordVisibilityPressed_withLoginState() {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            revisionDate: Date()
        )
        var loginState = LoginItemState(cipherView: cipherView)!
        subject.state.loadingState = .data(.login(loginState))
        subject.receive(.passwordVisibilityPressed)

        loginState.isPasswordVisible = true
        XCTAssertEqual(subject.state.loadingState, .data(.login(loginState)))
    }

    /// `receive` with `.passwordVisibilityPressed` with a login state toggles the value
    /// for `isPasswordVisible`.
    func test_receive_passwordVisibilityPressed_withLoginState_withMasterPasswordReprompt() throws {
        let cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            reprompt: .password,
            revisionDate: Date()
        )
        let loginState = LoginItemState(cipherView: cipherView)!
        subject.state.loadingState = .data(.login(loginState))
        subject.receive(.passwordVisibilityPressed)

        XCTAssertEqual(try coordinator.unwrapLastRouteAsAlert(), .masterPasswordPrompt(completion: { _ in }))
    }

    /// Tapping the "Submit" button in the master password reprompt alert validates the entered
    /// password and completes the action.
    func test_masterPasswordReprompt_submitButtonPressed() async throws {
        var cipherView = CipherView.fixture(
            id: "123",
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            name: "name",
            reprompt: .password,
            revisionDate: Date()
        )
        var loginState = LoginItemState(cipherView: cipherView)!
        subject.state.loadingState = .data(.login(loginState))
        subject.receive(.passwordVisibilityPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        try await alert.tapAction(title: Localizations.submit)

        cipherView.reprompt = .none
        loginState = LoginItemState(cipherView: cipherView)!
        loginState.isPasswordVisible = true
        subject.state.loadingState = .data(.login(loginState))
        XCTAssertEqual(subject.state.loadingState, .data(.login(loginState)))
    }
}
