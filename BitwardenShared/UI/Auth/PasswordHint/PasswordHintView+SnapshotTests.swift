// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintViewTests

class PasswordHintViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordHintState, PasswordHintAction, PasswordHintEffect>!
    var subject: PasswordHintView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = PasswordHintState()
        processor = MockProcessor(state: state)
        subject = PasswordHintView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// A snapshot of the view without any values set.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.emailAddress = ""
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// A snapshot of the view with a value in the email address field.
    @MainActor
    func disabletest_snapshot_withEmailAddress() {
        processor.state.emailAddress = "email@example.com"
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitAX5, .defaultPortraitDark])
    }
}
