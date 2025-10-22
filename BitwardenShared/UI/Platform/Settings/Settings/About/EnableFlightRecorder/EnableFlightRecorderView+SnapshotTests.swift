// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class EnableFlightRecorderViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EnableFlightRecorderState, EnableFlightRecorderAction, EnableFlightRecorderEffect>!
    var subject: EnableFlightRecorderView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: EnableFlightRecorderState())
        let store = Store(processor: processor)

        subject = EnableFlightRecorderView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The enable flight recorder view renders correctly.
    @MainActor
    func disabletest_snapshot_enableFlightRecorder() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 3)])
    }
}
