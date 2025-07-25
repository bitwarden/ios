import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultSettingsState, VaultSettingsAction, VaultSettingsEffect>!
    var subject: VaultSettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultSettingsState())
        let store = Store(processor: processor)

        subject = VaultSettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the export vault button dispatches the `.exportVaultTapped` action.
    @MainActor
    func test_exportVaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportVault)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportVaultTapped)
    }

    /// Tapping the folders button dispatches the `.foldersTapped` action.
    @MainActor
    func test_foldersButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.folders)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .foldersTapped)
    }

    /// Tapping the version button dispatches the `.importItemsTapped` action.
    @MainActor
    func test_importItemsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.importItems)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .importItemsTapped)
    }

    /// The action card is hidden if the import logins setup progress is incomplete or complete.
    @MainActor
    func test_importLoginsActionCard_hidden() {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .incomplete)
        XCTAssertThrowsError(try subject.inspect().find(actionCard: Localizations.importSavedLogins))

        processor.state.badgeState = .fixture(importLoginsSetupProgress: .complete)
        XCTAssertThrowsError(try subject.inspect().find(actionCard: Localizations.importSavedLogins))
    }

    /// The action card is visible if the import logins setup progress is set up later.
    @MainActor
    func test_importLoginsActionCard_visible() async throws {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.importSavedLogins)

        let badge = try actionCard.find(BitwardenBadge.self)
        try XCTAssertEqual(badge.text().string(), "1")
    }

    /// Tapping the dismiss button in the import logins action card sends the
    /// `.dismissImportLoginsActionCard` effect.
    @MainActor
    func test_importLoginsActionCard_visible_tapDismiss() async throws {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.importSavedLogins)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissImportLoginsActionCard])
    }

    /// Tapping the get started button in the import logins action card sends the
    /// `.showImportLogins` action.
    @MainActor
    func test_importLoginsActionCard_visible_tapGetStarted() async throws {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.importSavedLogins)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.showImportLogins])
    }

    // MARK: Snapshots

    /// The view renders correctly with the import logins action card displayed.
    @MainActor
    func test_snapshot_actionCardImportLogins() async {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The default view renders correctly.
    @MainActor
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
