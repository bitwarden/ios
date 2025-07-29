import AVFoundation
import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - ScanCodeViewTests

class ScanCodeViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ScanCodeState, ScanCodeAction, ScanCodeEffect>!
    var subject: ScanCodeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ScanCodeState(showManualEntry: true))
        let store = Store(processor: processor)
        subject = ScanCodeView(
            cameraSession: .init(),
            store: store
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    // MARK: Snapshots

    /// Test a snapshot of the ProfileSwitcherView previews.
    func test_snapshot_scanCodeView_previews() {
        for preview in ScanCodeView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultLandscape,
                    .defaultPortraitAX5,
                ]
            )
        }
    }
}
