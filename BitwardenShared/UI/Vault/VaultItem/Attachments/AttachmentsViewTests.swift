import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AttachmentsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect>!
    var subject: AttachmentsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AttachmentsState())
        let store = Store(processor: processor)

        subject = AttachmentsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismissPressed` action.
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the choose file button dispatches the `.chooseFilePressed` action.
    func test_chooseFileButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.chooseFile)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .chooseFilePressed)
    }

    /// Tapping the save button performs the `.savePressed` effect.
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }

    // MARK: Previews

    /// The empty view renders correctly in dark mode.
    func test_snapshot_attachments_empty_dark() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortraitDark)
    }

    /// The empty view renders correctly.
    func test_snapshot_attachments_empty_default() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// The empty view renders correctly with large text.
    func test_snapshot_attachments_empty_large() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortraitAX5)
    }
}
