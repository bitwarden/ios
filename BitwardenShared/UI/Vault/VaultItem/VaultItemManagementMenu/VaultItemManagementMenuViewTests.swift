import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultItemManagementMenuViewTests

class VaultItemManagementMenuViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, VaultItemManagementMenuAction, VaultItemManagementMenuEffect>!
    var subject: VaultItemManagementMenuView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ())
        let store = Store(processor: processor)
        subject = VaultItemManagementMenuView(
            isCloneEnabled: true,
            isCollectionsEnabled: true,
            isDeleteEnabled: true,
            isMoveToOrganizationEnabled: true,
            store: store
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the attachments option dispatches the `.attachments` action.
    @MainActor
    func test_attachmentsOption_tap() throws {
        let button = try subject.inspect().find(button: Localizations.attachments)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .attachments)
    }

    /// Tapping the attachments option dispatches the `.clone` action.
    @MainActor
    func test_cloneOption_tap() throws {
        let button = try subject.inspect().find(button: Localizations.clone)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .clone)
    }

    /// Tapping the attachments option dispatches the `.clone` action.
    @MainActor
    func test_collectionsOption_tap() throws {
        let button = try subject.inspect().find(button: Localizations.collections)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editCollections)
    }

    /// Tapping the delete option performs the `.deleteItem` effect.
    @MainActor
    func test_deleteOption_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.delete)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deleteItem)
    }

    /// Tapping the move to organization option dispatches the `.moveToOrganization` action.
    @MainActor
    func test_moveToOrgOption_tap() throws {
        let button = try subject.inspect().find(button: Localizations.moveToOrganization)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .moveToOrganization)
    }
}
