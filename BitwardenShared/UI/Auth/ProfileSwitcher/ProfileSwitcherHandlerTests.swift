import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

final class ProfileSwitcherHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var subject: MockProfileSwitcherHandlerProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()

        let account = ProfileSwitcherItem.anneAccount
        let state = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        subject = MockProfileSwitcherHandlerProcessor(
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter
            ),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleProfileSwitcherEffect(_:)` with `.accountLongPressed` shows the account options alert
    /// and when the remove account option is invoked, shows the remove account confirmation alert.
    @MainActor
    func test_didLongPressProfileSwitcherItem_confirmRemoveAccount_cancel() async throws {
        subject.profileSwitcherState = ProfileSwitcherState(
            accounts: [.fixtureLoggedOut],
            activeAccountId: ProfileSwitcherItem.fixtureLoggedOut.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.handleProfileSwitcherEffect(.accountLongPressed(.fixtureLoggedOut))

        let optionsAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(
            optionsAlert,
            .accountOptions(
                .fixtureLoggedOut,
                lockAction: {},
                logoutAction: {},
                removeAccountAction: {}
            )
        )
        try await optionsAlert.tapAction(title: Localizations.removeAccount)

        let confirmationAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(confirmationAlert, .removeAccountConfirmation(.fixtureLoggedOut, action: {}))
        try await confirmationAlert.tapCancel()

        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertTrue(subject.handleAuthEvents.isEmpty)
    }

    /// `handleProfileSwitcherEffect(_:)` with `.accountLongPressed` shows the account options alert
    /// and when the remove account option is invoked, shows the remove account confirmation alert
    /// and logs an error if one occurs.
    @MainActor
    func test_didLongPressProfileSwitcherItem_confirmRemoveAccount_error() async throws {
        subject.profileSwitcherState = ProfileSwitcherState(
            accounts: [.fixtureLoggedOut],
            activeAccountId: ProfileSwitcherItem.fixtureLoggedOut.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.handleProfileSwitcherEffect(.accountLongPressed(.fixtureLoggedOut))

        let optionsAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(
            optionsAlert,
            .accountOptions(
                .fixtureLoggedOut,
                lockAction: {},
                logoutAction: {},
                removeAccountAction: {}
            )
        )
        try await optionsAlert.tapAction(title: Localizations.removeAccount)

        let confirmationAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(confirmationAlert, .removeAccountConfirmation(.fixtureLoggedOut, action: {}))
        try await confirmationAlert.tapAction(title: Localizations.yes)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `handleProfileSwitcherEffect(_:)` with `.accountLongPressed` shows the account options
    /// alert, then the remove account alert, and removes an active account.
    @MainActor
    func test_didLongPressProfileSwitcherItem_confirmRemoveAccount_removeAccountActive() async throws {
        let loggedOutAccount = ProfileSwitcherItem.fixtureLoggedOut
        authRepository.activeAccount = .fixture(profile: .fixture(userId: loggedOutAccount.userId))
        subject.profileSwitcherState = ProfileSwitcherState(
            accounts: [loggedOutAccount],
            activeAccountId: loggedOutAccount.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        await subject.handleProfileSwitcherEffect(.accountLongPressed(loggedOutAccount))

        let optionsAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(
            optionsAlert,
            .accountOptions(
                loggedOutAccount,
                lockAction: {},
                logoutAction: {},
                removeAccountAction: {}
            )
        )
        try await optionsAlert.tapAction(title: Localizations.removeAccount)

        let confirmationAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(confirmationAlert, .removeAccountConfirmation(.fixtureLoggedOut, action: {}))
        try await confirmationAlert.tapAction(title: Localizations.yes)

        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertEqual(
            subject.handleAuthEvents,
            [
                .action(.logout(userId: loggedOutAccount.userId, userInitiated: true)),
            ]
        )
    }

    /// `handleProfileSwitcherEffect(_:)` with `.accountLongPressed` shows the account options
    /// alert, then the remove account alert, and removes an inactive account.
    @MainActor
    func test_didLongPressProfileSwitcherItem_confirmRemoveAccount_removeAccountInactive() async throws {
        let loggedOutAccount = ProfileSwitcherItem.fixtureLoggedOut
        let originalState = ProfileSwitcherState(
            accounts: [loggedOutAccount, .anneAccount],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: true,
            isVisible: true
        )
        let removedAccountState = ProfileSwitcherState(
            accounts: [.anneAccount],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        authRepository.activeAccount = .fixture(profile: .fixture(userId: ProfileSwitcherItem.anneAccount.userId))
        authRepository.profileSwitcherState = removedAccountState
        subject.profileSwitcherState = originalState

        await subject.handleProfileSwitcherEffect(.accountLongPressed(loggedOutAccount))

        let optionsAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(
            optionsAlert,
            .accountOptions(
                loggedOutAccount,
                lockAction: {},
                logoutAction: {},
                removeAccountAction: {}
            )
        )
        try await optionsAlert.tapAction(title: Localizations.removeAccount)

        let confirmationAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(confirmationAlert, .removeAccountConfirmation(loggedOutAccount, action: {}))
        try await confirmationAlert.tapAction(title: Localizations.yes)

        XCTAssertEqual(authRepository.logoutUserId, loggedOutAccount.userId)
        XCTAssertTrue(authRepository.logoutCalled)
        XCTAssertTrue(subject.handleAuthEvents.isEmpty)
        XCTAssertEqual(subject.toast, Toast(title: Localizations.accountRemovedSuccessfully))
        XCTAssertEqual(subject.state, removedAccountState)
    }

    /// `handleProfileSwitcherAction(_:)` with `.accessibility(.remove)` shows the remove account
    /// confirmation alert and then removes the account on confirmation.
    @MainActor
    func test_handleProfileSwitcherAction_accessibility_remove() async throws {
        let loggedOutAccount = ProfileSwitcherItem.fixtureLoggedOut
        authRepository.activeAccount = .fixture(profile: .fixture(userId: loggedOutAccount.userId))
        subject.profileSwitcherState = ProfileSwitcherState(
            accounts: [loggedOutAccount],
            activeAccountId: loggedOutAccount.userId,
            allowLockAndLogout: true,
            isVisible: true
        )

        subject.handleProfileSwitcherAction(.accessibility(.remove(loggedOutAccount)))

        let confirmationAlert = try XCTUnwrap(subject.alertsShown.last)
        XCTAssertEqual(confirmationAlert, .removeAccountConfirmation(loggedOutAccount, action: {}))
        try await confirmationAlert.tapAction(title: Localizations.yes)

        XCTAssertFalse(authRepository.logoutCalled)
        XCTAssertEqual(
            subject.handleAuthEvents,
            [
                .action(.logout(userId: loggedOutAccount.userId, userInitiated: true)),
            ]
        )
    }
}
