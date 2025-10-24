// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - ExpiredLinkViewTests

class ExpiredLinkViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExpiredLinkState, ExpiredLinkAction, Void>!
    var subject: ExpiredLinkView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ExpiredLinkState())
        subject = ExpiredLinkView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tests the view renders correctly.
    @MainActor
    func disabletest_snapshot_toggles_on() throws {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
