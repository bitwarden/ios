import BitwardenResources
import SnapshotTesting
import ViewInspector
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

    /// Tapping on the export items button performs the `.mainButtonTapped` effect.
    @MainActor
    func test_mainButton_tapped() async throws {
        processor.state.status = .prepared(itemsToExport: [])
        let button = try subject.inspect().find(asyncButton: Localizations.exportItems)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .mainButtonTapped)
    }

    /// Tapping on the cancel button performs the `.cancel` effect.
    @MainActor
    func test_cancelButton_tapped() async throws {
        processor.state.status = .start
        let button = try subject.inspect().find(asyncButton: Localizations.cancel)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .cancel)
    }

    /// Test a snapshot on start status.
    func test_snapshot_start() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot on prepared status.
    @MainActor
    func test_snapshot_prepared() {
        processor.state.status = .prepared(itemsToExport: [
            CXFCredentialsResult(count: 10, type: .password),
            CXFCredentialsResult(count: 90, type: .passkey),
            CXFCredentialsResult(count: 2, type: .identity),
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

    /// Test a snapshot on failure status but when feature unavailable.
    @MainActor
    func test_snapshot_failureFeatureUnavailable() {
        processor.state.isFeatureUnavailable = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
