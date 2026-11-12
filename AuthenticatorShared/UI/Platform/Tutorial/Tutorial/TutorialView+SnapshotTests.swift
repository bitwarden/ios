// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AuthenticatorShared

// MARK: - TutorialViewTests

class TutorialViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<TutorialState, TutorialAction, TutorialEffect>!
    var subject: TutorialView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = TutorialState()
        processor = MockProcessor(state: state)
        subject = TutorialView(
            store: Store(processor: processor),
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the intro page.
    @MainActor
    func test_snapshot_intro() {
        processor.state.page = .intro
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
                .defaultLandscapeAX5,
            ],
        )
    }

    /// Test a snapshot of the QR scanner page.
    @MainActor
    func test_snapshot_qrScanner() {
        processor.state.page = .qrScanner
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
                .defaultLandscapeAX5,
            ],
        )
    }

    /// Test a snapshot of the unique codes page.
    @MainActor
    func test_snapshot_uniqueCodes() {
        processor.state.page = .uniqueCodes
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
                .defaultLandscapeAX5,
            ],
        )
    }
}
