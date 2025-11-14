// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
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
            ],
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
        let button = try subject.inspect().findCancelToolbarButton()
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
        guard #unavailable(iOS 26) else {
            // TODO: PM-26079 Remove when toolbar AsyncButton is used.
            throw XCTSkip("Remove this when the toolbar save button gets updated to use AsyncButton.")
        }

        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }
}
