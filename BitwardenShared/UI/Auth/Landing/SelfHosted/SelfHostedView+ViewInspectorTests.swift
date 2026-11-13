// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class SelfHostedViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect>!
    var subject: SelfHostedView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SelfHostedState())

        subject = SelfHostedView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the save button dispatches the `.saveEnvironment` action.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().findSaveToolbarButton()
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveEnvironment)
    }
}
