// swiftlint:disable:this file_name
import AVFoundation
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ScanCodeViewTests

class ScanCodeViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ScanCodeState, ScanCodeAction, ScanCodeEffect>!
    var subject: ScanCodeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: .init())
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
