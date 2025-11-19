// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - ExportCXFViewTests

class ExportCXFViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportCXFState, ExportCXFAction, ExportCXFEffect>!
    var subject: ExportCXFView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExportCXFState())
        let store = Store(processor: processor)

        subject = ExportCXFView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot on start status.
    func disabletest_snapshot_start() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot on prepared status.
    @MainActor
    func disabletest_snapshot_prepared() {
        processor.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
            CXFCredentialsResult(count: 90, type: .passkey),
            CXFCredentialsResult(count: 2, type: .identity),
        ])
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot on failure status.
    @MainActor
    func disabletest_snapshot_failure() {
        processor.state.status = .failure(message: "Something went wrong")
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot on failure status but when feature unavailable.
    @MainActor
    func disabletest_snapshot_failureFeatureUnavailable() {
        processor.state.isFeatureUnavailable = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
