import BitwardenResources
import SnapshotTesting
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
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the save button dispatches the `.saveEnvironment` action.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveEnvironment)
    }

    // MARK: Snapshots

    /// Tests that the view renders correctly.
    func test_viewRender() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }
}
