import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class RemoveMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: RemoveMasterPasswordProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = RemoveMasterPasswordProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter
            ),
            state: RemoveMasterPasswordState(
                organizationName: "Example Org",
                organizationId: "ORG_ID",
                keyConnectorUrl: "https://example.com"
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.continueFlow` removes the user's master password and completes auth.
    @MainActor
    func test_perform_continueFlow() async {
        authRepository.migrateUserToKeyConnectorResult = .success(())
        subject.state.masterPassword = "password"

        await subject.perform(.continueFlow)

        XCTAssertTrue(authRepository.migrateUserToKeyConnectorCalled)
        XCTAssertEqual(authRepository.migrateUserToKeyConnectorPassword, "password")
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.loading)])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events, [.didCompleteAuth])
    }

    /// `perform(_:)` with `.continueFlow` displays an alert if the user didn't enter a master password.
    @MainActor
    func test_perform_continueFlow_emptyPassword() async throws {
        await subject.perform(.continueFlow)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            Alert.inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            ))
        )
    }

    /// `perform(_:)` with `.continueFlow` displays an alert if the user enters an invalid password.
    @MainActor
    func test_perform_continueFlow_invalidPassword() async throws {
        authRepository.migrateUserToKeyConnectorResult = .failure(
            BitwardenSdk.BitwardenError.E(message: "invalid master password")
        )
        subject.state.masterPassword = "password"

        await subject.perform(.continueFlow)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            )
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `perform(_:)` with `.continueFlow` displays an alert and logs an error if one occurs.
    @MainActor
    func test_perform_continueFlow_error() async throws {
        authRepository.migrateUserToKeyConnectorResult = .failure(BitwardenTestError.example)
        subject.state.masterPassword = "password"

        await subject.perform(.continueFlow)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    @MainActor
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    @MainActor
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `perform(_:)` with `.leaveOrganizationFlow` displays a confirmation prompt of user to leave organization
    @MainActor
    func test_perform_leaveOrganizationFlow() async throws {
        authRepository.activeAccount = .fixture()

        await subject.perform(.leaveOrganizationFlow)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(
            alert,
            Alert.leaveOrganizationConfirmation(orgName: "Example Org") {}
        )

        try await alert.tapAction(title: Localizations.yes)

        XCTAssertTrue(authRepository.leaveOrganizationCalled)
        XCTAssertEqual(authRepository.leaveOrganizationOrganizationId, subject.state.organizationId)
        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertEqual(authRepository.logoutUserId, "1")
        XCTAssertTrue(authRepository.logoutUserInitiated)
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.events.last, .didLogout(userId: "1", userInitiated: true))
    }
}
