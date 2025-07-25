import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddEditCustomFieldsViewTests

class AddEditCustomFieldsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditCustomFieldsState, AddEditCustomFieldsAction, Void>!
    var subject: AddEditCustomFieldsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: .init(
                cipherType: .login,
                customFields: [.init(name: "custom1", type: .text)]
            )
        )
        let store = Store(processor: processor)
        subject = AddEditCustomFieldsView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the edit option dispatches the `.editCustomFieldNamePressed(index:)` action.
    @MainActor
    func test_edit_tap() throws {
        let button = try subject.inspect().find(button: Localizations.edit)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editCustomFieldNamePressed(index: 0))
    }

    /// Tapping the move down option dispatches the `.moveDownCustomFieldPressed(index:)` action.
    @MainActor
    func test_moveDown_tap() throws {
        let button = try subject.inspect().find(button: Localizations.moveDown)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .moveDownCustomFieldPressed(index: 0))
    }

    /// Tapping the move up option dispatches the `.moveUpCustomFieldPressed(index:)` action.
    @MainActor
    func test_moveUp_tap() throws {
        let button = try subject.inspect().find(button: Localizations.moveUp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .moveUpCustomFieldPressed(index: 0))
    }

    /// Tapping the new custom field button dispatches the `.removeCustomFieldPressed(index:)` action.
    @MainActor
    func test_newCustomField_tap() throws {
        let button = try subject.inspect().find(button: Localizations.newCustomField)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .newCustomFieldPressed)
    }

    /// Tapping the remove option dispatches the `.removeCustomFieldPressed(index:)` action.
    @MainActor
    func test_remove_tap() throws {
        let button = try subject.inspect().find(button: Localizations.remove)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .removeCustomFieldPressed(index: 0))
    }

    /// The view with all types of custom fields renders correctly.
    @MainActor
    func test_snapshot_allFields() {
        for preview in AddEditCustomFieldsView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .defaultPortraitAX5,
                ]
            )
        }
    }
}
