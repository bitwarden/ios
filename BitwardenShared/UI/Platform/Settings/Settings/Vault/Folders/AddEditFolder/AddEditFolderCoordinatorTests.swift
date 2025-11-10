import BitwardenKitMocks
import BitwardenSdk
import SwiftUI
import XCTest

@testable import BitwardenShared

class AddEditFolderCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: AddEditFolderCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = AddEditFolderCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.addEditFolder` and an existing folder replaces the stack navigator's
    /// stack with the add/edit folder view.
    @MainActor
    func test_navigateTo_addEditFolder_edit() throws {
        let folder = FolderView.fixture(name: "Test")
        subject.navigate(to: .addEditFolder(folder: folder))

        XCTAssertEqual(stackNavigator.actions.count, 1)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditFolderView)

        let view = try XCTUnwrap(action.view as? AddEditFolderView)
        XCTAssertEqual(view.store.state.folderName, "Test")
        XCTAssertEqual(view.store.state.mode, .edit(folder))
    }

    /// `navigate(to:)` with `.addEditFolder` replaces the stack navigator's stack with the add/edit
    /// folder view.
    @MainActor
    func test_navigateTo_addEditFolder_new() throws {
        subject.navigate(to: .addEditFolder(folder: nil))

        XCTAssertEqual(stackNavigator.actions.count, 1)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is AddEditFolderView)

        let view = try XCTUnwrap(action.view as? AddEditFolderView)
        XCTAssertEqual(view.store.state.folderName, "")
        XCTAssertEqual(view.store.state.mode, .add)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }
}
