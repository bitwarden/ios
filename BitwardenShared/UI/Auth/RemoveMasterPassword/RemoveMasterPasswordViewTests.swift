import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class RemoveMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<RemoveMasterPasswordState, RemoveMasterPasswordAction, Void>!
    var subject: RemoveMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: RemoveMasterPasswordState(organizationName: "Example Org"))

        subject = RemoveMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the continue button dispatches the continue flow action.
    @MainActor
    func test_continue_tap() throws {
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .continueFlow)
    }

    // MARK: Snapshots

    /// The remove master password view renders correctly.
    @MainActor
    func test_snapshot_removeMasterPassword() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.5)]
        )
    }
}
