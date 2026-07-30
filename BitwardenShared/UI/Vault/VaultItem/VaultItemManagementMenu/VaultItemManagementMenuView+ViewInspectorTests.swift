// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
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
            isArchiveEnabled: true,
            isCloneEnabled: true,
            isCollectionsEnabled: true,
            isDeleteEnabled: true,
            isMoveToOrganizationEnabled: true,
            isRestoreEnabled: true,
            isUnarchiveEnabled: false,
            isVfo1FoundationFeatureFlagEnabled: false,
            store: store,
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the archive option dispatches the `.archive` action.
    @MainActor
    func test_archiveOption_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.archive)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .archiveItem)
    }

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

    /// Tapping the move to organization option dispatches the `.moveToOrganization` action when
    /// the `vfo1-foundation` feature flag is disabled.
    @MainActor
    func test_moveToOrgOption_tap_vfo1FoundationDisabled() throws {
        let button = try subject.inspect().find(button: Localizations.moveToOrganization)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .moveToOrganization)
    }

    /// Tapping the move to organization option dispatches the `.moveToOrganization` action when
    /// the `vfo1-foundation` feature flag is enabled.
    @MainActor
    func test_moveToOrgOption_tap_vfo1FoundationEnabled() throws {
        subject = VaultItemManagementMenuView(
            isArchiveEnabled: true,
            isCloneEnabled: true,
            isCollectionsEnabled: true,
            isDeleteEnabled: true,
            isMoveToOrganizationEnabled: true,
            isRestoreEnabled: true,
            isUnarchiveEnabled: false,
            isVfo1FoundationFeatureFlagEnabled: true,
            store: Store(processor: processor),
        )
        let button = try subject.inspect().find(button: Localizations.move)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .moveToOrganization)
    }

    /// Tapping the restore option dispatches the `.restore` action.
    @MainActor
    func test_restore_tap() throws {
        let button = try subject.inspect().find(button: Localizations.restore)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .restore)
    }
}
