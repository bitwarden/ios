import BitwardenResources
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

    /// Tapping the close button dispatches the `.dismiss` action.
    @MainActor
    func test_closeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the password generator button dispatches the `.generatePasswordPressed` action.
    @MainActor
    func test_passwordGeneratorButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.checkOutThePassphraseGenerator)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .generatePasswordPressed)
    }

    // MARK: Snapshots

    /// The master password guidance view renders correctly.
    @MainActor
    func test_snapshot_masterPasswordGuidance() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
                .defaultLandscape,
            ]
        )
    }
}
