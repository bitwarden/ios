// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

class PreventAccountLockViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, PreventAccountLockAction, Void>!
    var subject: PreventAccountLockView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())
        subject = PreventAccountLockView(store: Store(processor: processor))
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
        let button = try subject.inspect().findCloseToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }
}
