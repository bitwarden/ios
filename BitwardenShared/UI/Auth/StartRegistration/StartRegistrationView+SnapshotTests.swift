// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationViewTests

class StartRegistrationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<StartRegistrationState, StartRegistrationAction, StartRegistrationEffect>!
    var subject: StartRegistrationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: StartRegistrationState())
        let store = Store(processor: processor)
        subject = StartRegistrationView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text fields are all empty.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark])
    }

    /// Tests the view renders correctly when the text fields are all populated.
    @MainActor
    func disabletest_snapshot_textFields_populated() throws {
        processor.state.emailText = "email@example.com"
        processor.state.nameText = "user name"

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the text fields are all populated with long text.
    @MainActor
    func disabletest_snapshot_textFields_populated_long() throws {
        processor.state.emailText = "emailmmmmmmmmmmmmmmmmmmmmm@exammmmmmmmmmmmmmmmmmmmmmmmmmmmmmmple.com"
        processor.state.nameText = "user name name name name name name name name name name name name name name"

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the toggles are on.
    @MainActor
    func disabletest_snapshot_toggles_on() throws {
        processor.state.isReceiveMarketingToggleOn = true

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the marketing toggle is hidden.
    @MainActor
    func disabletest_snapshot_marketingToggle_hidden() throws {
        processor.state.showReceiveMarketingToggle = false

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
