import SnapshotTesting
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
                vaultFilterType: .allVaults
            )
        )
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultGroupView(
            store: Store(processor: processor),
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addAnItemButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add an item toolbar button dispatches the `.addItemPressed` action.
    func test_addAnItemToolbarButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping a vault item dispatches the `.itemPressed` action.
    func test_vaultItem_tap() throws {
        let item = VaultListItem.fixture(cipherView: .fixture(name: "Item"))
        processor.state.loadingState = .data([item])
        let button = try subject.inspect().find(button: "Item")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item))
    }

    /// Tapping the vault item copy totp button dispatches the `.copyTOTPCode` action.
    func test_vaultItem_copyTOTPButton_tap() throws {
        processor.state.loadingState = .data(
            [
                .fixtureTOTP(
                    totp: .fixture(
                        timeProvider: timeProvider
                    )
                ),
            ]
        )
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode("123456"))
    }

    /// Tapping the more button on a vault item dispatches the `.morePressed` action.
    func test_vaultItem_moreButton_tap() throws {
        let item = VaultListItem.fixture()
        processor.state.loadingState = .data([.fixture()])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed(item))
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_emptyCollection() {
        processor.state.group = .collection(id: "id", name: "name", organizationId: "12345")
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_emptyTrash() {
        processor.state.group = .trash
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_loading() {
        processor.state.loadingState = .loading
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_multipleItems() {
        processor.state.loadingState = .data([
            .fixture(
                cipherView: .fixture(
                    id: "1",
                    login: .fixture(username: "email@example.com"),
                    name: "Example"
                )
            ),
            .fixture(cipherView: .fixture(
                id: "2",
                login: .fixture(
                    username: "An equally long subtitle that should also take up more than one line"
                ),
                name: "An extra long name that should take up more than one line"
            )),
            .fixture(cipherView: .fixture(
                id: "3",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
            .fixture(cipherView: .fixture(
                id: "4",
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
        ])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_oneItem() {
        processor.state.loadingState = .data([
            .fixture(cipherView: .fixture(
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
        ])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_search_oneItem() {
        processor.state.isSearching = true
        processor.state.searchResults = [
            .fixture(cipherView: .fixture(
                login: .fixture(username: "email@example.com"),
                name: "Example"
            )),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func test_snapshot_search_oneTOTPItem() {
        timeProvider.timeConfig = .mockTime(
            .init(
                year: 2023,
                month: 5,
                day: 19,
                second: 33
            )
        )
        processor.state.isSearching = true
        processor.state.searchResults = [
            .fixtureTOTP(
                name: "Example",
                totp: .fixture(
                    loginView: .fixture(
                        uris: [
                            .init(uri: "www.example.com", match: nil),
                        ],
                        username: "email@example.com"
                    ),
                    totpCode: .init(
                        code: "034543",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30
                    )
                )
            ),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
