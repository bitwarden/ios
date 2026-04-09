// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - ImportCXFViewTests

class ImportCXFViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportCXFState, Void, ImportCXFEffect>!
    var subject: ImportCXFView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportCXFState())
        let store = Store(processor: processor)

        subject = ImportCXFView(store: store)
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

    /// Test a snapshot on importing status.
    @MainActor
    func disabletest_snapshot_importing() {
        processor.state.progress = 0.3
        processor.state.status = .importing
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot on success status.
    @MainActor
    func disabletest_snapshot_success() {
        processor.state.status = .success(totalImportedCredentials: 10, importedResults: [
            CXFCredentialsResult(count: 13, type: .password),
            CXFCredentialsResult(count: 7, type: .passkey),
            CXFCredentialsResult(count: 10, type: .card),
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
}
