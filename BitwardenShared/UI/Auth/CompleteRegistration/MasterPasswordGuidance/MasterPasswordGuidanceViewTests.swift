import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class MasterPasswordGuidanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, MasterPasswordGuidanceAction, Void>!
    var subject: MasterPasswordGuidanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())

        subject = MasterPasswordGuidanceView(store: Store(processor: processor))
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
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the password generator button dispatches the `.generatePasswordPressed` action.
    @MainActor
    func test_passwordGeneratorButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.tryItOut)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    // MARK: Snapshots

    /// The master password guidance view renders correctly.
    @MainActor
    func test_snapshot_masterPasswordGuidance() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape]
        )
    }
}
