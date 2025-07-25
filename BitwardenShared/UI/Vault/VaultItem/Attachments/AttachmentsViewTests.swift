import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AttachmentsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect>!
    var subject: AttachmentsView!

    var cipherWithAttachments: CipherView {
        .fixture(
            attachments: [
                .fixture(fileName: "selfieWithACat.png", id: "1", sizeName: "10 MB"),
                .fixture(fileName: "selfieWithADog.png", id: "2", sizeName: "11.2 MB"),
                .fixture(fileName: "selfieWithAPotato.png", id: "3", sizeName: "201.2 MB"),
            ]
        )
    }

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
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the choose file button dispatches the `.chooseFilePressed` action.
    @MainActor
    func test_chooseFileButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.chooseFile)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .chooseFilePressed)
    }

    /// Tapping the delete button dispatches the `.delete` action.
    @MainActor
    func test_deleteButton_tap() throws {
        processor.state.cipher = .fixture(attachments: [.fixture()])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.delete)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .deletePressed(.fixture()))
    }

    /// Tapping the save button performs the `.savePressed` effect.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }

    // MARK: Previews

    /// The empty view renders correctly in dark mode.
    @MainActor
    func test_snapshot_attachments_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view with a selected attachment renders correctly.
    @MainActor
    func test_snapshot_attachments_selected() {
        processor.state.fileName = "photo.jpg"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view with several attachments renders correctly in dark mode.
    @MainActor
    func test_snapshot_attachments_several() {
        processor.state.cipher = cipherWithAttachments
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ]
        )
    }
}
