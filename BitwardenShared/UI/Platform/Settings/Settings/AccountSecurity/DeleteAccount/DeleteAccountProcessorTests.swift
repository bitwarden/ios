import XCTest

@testable import BitwardenShared

class DeleteAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DeleteAccountProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DeleteAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                stateService: stateService
            ),
            state: DeleteAccountState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    func test_perform_deleteAccount() async {
        await subject.perform(.deleteAccount)

        XCTAssertEqual(try coordinator.unwrapLastRouteAsAlert(), .masterPasswordPrompt(completion: { _ in }))
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    /// Pressing submit on the alert deletes the user's account.
    func test_perform_deleteAccount_submitPressed_noOtherAccounts() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))

        await stateService.addAccount(account)
        await subject.perform(.deleteAccount)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        let textField = try XCTUnwrap(alert.alertTextFields.first)
        textField.text = "password"

        let action = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [textField])

        await assertAsyncThrows {
            _ = try await stateService.getAccounts()
            XCTAssertEqual(errorReporter.errors as? [StateServiceError], [StateServiceError.noAccounts])
        }
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    /// Pressing submit on the alert deletes the user's account.
    func test_perform_deleteAccount_submitPressed_otherAccounts() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        let account2 = Account.fixture(profile: Account.AccountProfile.fixture(userId: "2"))

        await stateService.addAccount(account)
        await stateService.addAccount(account2)
        await subject.perform(.deleteAccount)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        let textField = try XCTUnwrap(alert.alertTextFields.first)
        textField.text = "password"

        let action = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [textField])

        XCTAssertEqual(stateService.activeAccount, account2)
    }
}
