// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - LoginViewTests

class LoginViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginState, LoginAction, LoginEffect>!
    var subject: LoginView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: LoginState())
        let store = Store(processor: processor)
        subject = LoginView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.username = "user@bitwarden.com"
        processor.state.serverURLString = "bitwarden.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_passwordHidden() {
        processor.state.username = "user@bitwarden.com"
        processor.state.masterPassword = "Password"
        processor.state.serverURLString = "bitwarden.com"
        processor.state.isMasterPasswordRevealed = false
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_passwordRevealed() {
        processor.state.username = "user@bitwarden.com"
        processor.state.masterPassword = "Password"
        processor.state.serverURLString = "bitwarden.com"
        processor.state.isMasterPasswordRevealed = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_selfHosted() {
        processor.state.username = "user@bitwarden.com"
        processor.state.serverURLString = "selfhostedserver.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_withDevice() {
        processor.state.username = "user@bitwarden.com"
        processor.state.isLoginWithDeviceVisible = true
        processor.state.serverURLString = "bitwarden.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
