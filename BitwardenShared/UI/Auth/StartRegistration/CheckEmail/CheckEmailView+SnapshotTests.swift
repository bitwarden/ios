// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - CheckEmailViewTests

class CheckEmailViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<CheckEmailState, CheckEmailAction, Void>!
    var subject: CheckEmailView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: CheckEmailState(email: "example@email.com"))
        let store = Store(processor: processor)
        subject = CheckEmailView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    func disabletest_snapshot_empty() {
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ],
        )
    }
}
