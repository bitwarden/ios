import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: VaultGroupProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        vaultRepository = MockVaultRepository()
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(vaultRepository: vaultRepository),
            state: VaultGroupState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts streaming vault items.
    func test_perform_appeared() {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListGroupSubject.send([
            vaultListItem,
        ])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        XCTAssertEqual(subject.state.loadingState, .data([vaultListItem]))
        XCTAssertFalse(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` requests a fetch sync update with the vault repository.
    func test_perform_refreshed() async {
        await subject.perform(.refresh)
        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    func test_receive_addItemPressed() {
        subject.state.group = .card
        subject.receive(.addItemPressed)
        XCTAssertEqual(coordinator.routes.last, .addItem(group: .card))
    }

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed() {
        subject.receive(.itemPressed(.fixture(cipherListView: .fixture(id: "id"))))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "id"))
    }

    /// `receive(_:)` with `.morePressed` navigates to the more menu.
    func test_receive_morePressed() {
        subject.receive(.morePressed(.fixture()))
        // TODO: BIT-375 Assert navigation to the more menu
    }

    /// `receive(_:)` with `.searchTextChanged` and no value sets the state correctly.
    func test_receive_searchTextChanged_withoutValue() {
        subject.state.searchText = "search"
        subject.receive(.searchTextChanged(""))
        XCTAssertEqual(subject.state.searchText, "")
    }

    /// `receive(_:)` with `.searchTextChanged` and a value sets the state correctly.
    func test_receive_searchTextChanged_withValue() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))
        XCTAssertEqual(subject.state.searchText, "search")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }
}
