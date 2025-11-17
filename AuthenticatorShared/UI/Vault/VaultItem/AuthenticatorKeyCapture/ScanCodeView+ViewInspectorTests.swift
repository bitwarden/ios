// swiftlint:disable:this file_name
import AVFoundation
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import ViewInspectorTestHelpers
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
            store: store,
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
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }
}
