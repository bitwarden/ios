// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupViewTests

class VaultGroupViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect>!
    var subject: VaultGroupView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults,
            ),
        )
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultGroupView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the add item button dispatches the `.addItemPressed` action.
    @MainActor
    func test_addItemEmptyStateButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.newLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(nil))
    }

    /// Tapping an item in the add item menu dispatches the `.addItemPressed` action.
    @MainActor
    func test_addItemEmptyStateButton_hidden_restrictItemPolicy_enabled() throws {
        processor.state.loadingState = .data([])
        processor.state.group = .card
        processor.state.itemTypesUserCanCreate = [.login, .identity, .secureNote]
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.newCard))
    }

    /// Add item floating action button is hidden when in card group and restrict item policy is enabled.
    @MainActor
    func test_addItemFloatingActionButton_hidden_restrictItemPolicy_enabled() async throws {
        processor.state.loadingState = .data([])
        processor.state.group = .card
        processor.state.itemTypesUserCanCreate = [.login, .identity, .secureNote]

        XCTAssertThrowsError(
            try subject.inspect().find(
                floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
            ),
        )
    }

    /// Tapping an item in the add item menu dispatches the `.addItemPressed` action.
    @MainActor
    func test_addItemMenuEmptyState_tap() throws {
        processor.state.loadingState = .data([])
        processor.state.group = .folder(id: "1", name: "Folder")
        let button = try subject.inspect()
            .find(viewWithAccessibilityIdentifier: "AddItemButton")
            .find(button: Localizations.typeSecureNote)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(.secureNote))
    }

    /// Tapping the add item floating action button dispatches the `.addItemPressed` action.`
    @MainActor
    func test_addItemFloatingActionButton_tap() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(nil))
    }

    /// Tapping the add item floating action menu dispatches the `.addItemPressed` action.`
    @MainActor
    func test_addItemFloatingActionMenu_tap() throws {
        processor.state.group = .folder(id: "1", name: "Folder")
        let button = try subject.inspect().find(button: Localizations.typeCard)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(.card))
    }

    /// Tapping a vault item dispatches the `.itemPressed` action.
    @MainActor
    func test_vaultItem_tap() throws {
        let item = VaultListItem.fixture(cipherListView: .fixture(name: "Item"))
        let section = VaultListSection(id: "Items", items: [item], name: Localizations.items)
        processor.state.loadingState = .data([section])
        let button = try subject.inspect().find(button: "Item")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item))
    }

    /// Tapping the vault item copy totp button dispatches the `.copyTOTPCode` action.
    @MainActor
    func test_vaultItem_copyTOTPButton_tap() throws {
        processor.state.loadingState = .data(
            [
                VaultListSection(
                    id: "Items",
                    items: [
                        .fixtureTOTP(
                            totp: .fixture(
                                timeProvider: timeProvider,
                            ),
                        ),
                    ],
                    name: Localizations.items,
                ),
            ],
        )
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode("123456"))
    }

    /// Tapping the more button on a vault item dispatches the `.morePressed` action.
    @MainActor
    func test_vaultItem_moreButton_tap() async throws {
        let item = VaultListItem.fixture()
        let section = VaultListSection(id: "Items", items: [item], name: Localizations.items)
        processor.state.loadingState = .data([section])
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.more)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .morePressed(item))
    }
}
