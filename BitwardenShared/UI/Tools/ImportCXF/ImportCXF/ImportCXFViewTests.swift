import BitwardenResources
import SnapshotTesting
import ViewInspector
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

    /// Tapping on the continue button performs the `.mainButtonTapped` effect.
    @MainActor
    func test_mainButton_tapped() throws {
        processor.state.status = .start
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        waitFor {
            processor.effects.last == .mainButtonTapped
        }
    }

    /// Tapping on the cancel button performs the `.cancel` effect.
    @MainActor
    func test_cancelButton_tapped() throws {
        processor.state.status = .start
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        waitFor {
            processor.effects.last == .cancel
        }
    }

    /// Test a snapshot on start status.
    func test_snapshot_start() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot on importing status.
    @MainActor
    func test_snapshot_importing() {
        processor.state.progress = 0.3
        processor.state.status = .importing
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot on success status.
    @MainActor
    func test_snapshot_success() {
        processor.state.status = .success(totalImportedCredentials: 10, importedResults: [
            CXFCredentialsResult(count: 13, type: .password),
            CXFCredentialsResult(count: 7, type: .passkey),
            CXFCredentialsResult(count: 10, type: .card),
        ])
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot on failure status.
    @MainActor
    func test_snapshot_failure() {
        processor.state.status = .failure(message: "Something went wrong")
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
