// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - CompleteRegistrationViewTests

class CompleteRegistrationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<CompleteRegistrationState, CompleteRegistrationAction, CompleteRegistrationEffect>!
    var subject: CompleteRegistrationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: CompleteRegistrationState(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "email@example.com",
        ))
        let store = Store(processor: processor)
        subject = CompleteRegistrationView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    @MainActor
    func disabletest_snapshot_empty_nativeCreateAccountFlow() throws {
        assertSnapshots(
            of: subject,
            as: [
                .tallPortrait,
                .portraitDark(heightMultiple: 2),
                .tallPortraitAX5(),
            ],
        )
    }

    /// Tests the view renders correctly when text fields are hidden.
    @MainActor
    func disabletest_snapshot_textFields_hidden_nativeCreateAccountFlow() throws {
        processor.state.arePasswordsVisible = false
        processor.state.userEmail = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the text fields are all populated.
    @MainActor
    func disabletest_snapshot_textFields_populated_nativeCreateAccountFlow() throws {
        processor.state.arePasswordsVisible = true
        processor.state.userEmail = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the toggles are on.
    @MainActor
    func disabletest_snapshot_toggles_on_nativeCreateAccountFlow() throws {
        processor.state.isCheckDataBreachesToggleOn = true

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
