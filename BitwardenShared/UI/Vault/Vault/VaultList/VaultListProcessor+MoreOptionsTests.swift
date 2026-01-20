// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessor MoreOptions Tests

class VaultListProcessorMoreOptionsTests: BitwardenTestCase {
    @MainActor
    func test_vault_moreOptions_login_canViewPassword() async throws { // swiftlint:disable:this function_body_length
        var capturedAction: MoreOptionsAction?
        let action: (MoreOptionsAction) -> Void = { action in
            capturedAction = action
        }
        let cipher = CipherView.fixture(
            edit: false,
            id: "123",
            login: .fixture(
                password: "password",
                username: "username",
            ),
            name: "Test Cipher",
            type: .login,
            viewPassword: true,
        )
        let alert = Alert.moreOptions(
            context: MoreOptionsAlertContext(
                canArchive: false,
                canCopyTotp: false,
                canUnarchive: false,
                cipherView: cipher,
                id: cipher.id!,
                showEdit: true,
            ),
            action: action,
        )
        XCTAssertEqual(alert.title, cipher.name)
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 5)

        // Test the first action is a view action.
        let first = try XCTUnwrap(alert.alertActions[0])
        XCTAssertEqual(first.title, Localizations.view)
        await first.handler?(first, [])
        XCTAssertEqual(capturedAction, .view(id: "123"))
        capturedAction = nil

        // Test the second action is edit.
        let second = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(second.title, Localizations.edit)
        await second.handler?(second, [])
        XCTAssertEqual(
            capturedAction,
            .edit(cipherView: cipher),
        )
        capturedAction = nil

        // Test the third action is copy username.
        let third = try XCTUnwrap(alert.alertActions[2])
        XCTAssertEqual(third.title, Localizations.copyUsername)
        await third.handler?(third, [])
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.username,
                value: "username",
                requiresMasterPasswordReprompt: false,
                logEvent: nil,
                cipherId: nil,
            ),
        )
        capturedAction = nil

        // Test the fourth action is copy password.
        let fourth = try XCTUnwrap(alert.alertActions[3])
        XCTAssertEqual(fourth.title, Localizations.copyPassword)
        await fourth.handler?(fourth, [])
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.password,
                value: "password",
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedPassword,
                cipherId: "123",
            ),
        )
        capturedAction = nil

        // Test the fifth action is a cancel action.
        let fifth = try XCTUnwrap(alert.alertActions[4])
        XCTAssertEqual(fifth.title, Localizations.cancel)
        await fifth.handler?(fifth, [])
        XCTAssertNil(capturedAction)
    }

    @MainActor
    func test_vault_moreOptions_login_cannotViewPassword() async throws {
        var capturedAction: MoreOptionsAction?
        let action: (MoreOptionsAction) -> Void = { action in
            capturedAction = action
        }
        let cipher = CipherView.fixture(
            edit: false,
            id: "123",
            login: .fixture(
                password: "password",
                username: nil,
            ),
            name: "Test Cipher",
            type: .login,
            viewPassword: false,
        )
        let alert = Alert.moreOptions(
            context: MoreOptionsAlertContext(
                canArchive: false,
                canCopyTotp: false,
                canUnarchive: false,
                cipherView: cipher,
                id: cipher.id!,
                showEdit: true,
            ),
            action: action,
        )
        XCTAssertEqual(alert.title, cipher.name)
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 3)

        // Test the first action is a view action.
        let first = try XCTUnwrap(alert.alertActions[0])
        XCTAssertEqual(first.title, Localizations.view)
        await first.handler?(first, [])
        XCTAssertEqual(capturedAction, .view(id: "123"))
        capturedAction = nil

        // Test the second action is edit.
        let second = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(second.title, Localizations.edit)
        await second.handler?(second, [])
        XCTAssertEqual(
            capturedAction,
            .edit(cipherView: cipher),
        )
        capturedAction = nil

        // Test the third action is a cancel action.
        let third = try XCTUnwrap(alert.alertActions[2])
        XCTAssertEqual(third.title, Localizations.cancel)
        await third.handler?(third, [])
        XCTAssertNil(capturedAction)
    }
}
