// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class EditCollectionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EditCollectionsState, EditCollectionsAction, EditCollectionsEffect>!
    var subject: EditCollectionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: EditCollectionsState(cipher: .fixture()))
        let store = Store(processor: processor)

        subject = EditCollectionsView(store: store)
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

    /// Tapping the save button dispatches the `.save` action.
    @MainActor
    func test_saveButton_tap() async throws {
        let button = try subject.inspect().findSaveToolbarButton()
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .save)
    }
}
