import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

class VaultListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: VaultListProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            vaultRepository: vaultRepository
        )
        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: VaultListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared() {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListSubject.send([
            VaultListSection(
                id: "1",
                items: [vaultListItem],
                name: "Name"
            ),
        ])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!subject.state.sections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.sections.count, 1)
        XCTAssertEqual(subject.state.sections[0].items, [vaultListItem])
        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` requests a fetch sync update with the vault repository.
    func test_perform_refresh() async {
        await subject.perform(.refresh)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `receive(_:)` with `.addAccountPressed` updates the state correctly
    func test_receive_accountPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcherAction(.accountPressed(ProfileSwitcherItem())))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.addAccountPressed` updates the state correctly
    func test_receive_addAccountPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcherAction(.addAccountPressed))

        XCTAssertEqual(coordinator.routes.last, .addAccount)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed)

        XCTAssertEqual(coordinator.routes.last, .addItem())
    }

    /// `receive(_:)` with `.addItemPressed` hides the profile switcher view
    func test_receive_addItemPressed_hideProfiles() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.addItemPressed)

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed() {
        let item = VaultListItem.fixture()
        subject.receive(.itemPressed(item: item))

        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))
    }

    /// `receive(_:)` with `ProfileSwitcherAction.backgroundPressed` turns off the Profile Switcher Visibility.
    func test_receive_profileSwitcherBacgroundPressed() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.profileSwitcherAction(.backgroundPressed))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: false)` hides the profile switcher
    func test_receive_searchTextChanged_false_noProfilesChange() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: false))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchStateChanged(isSearching: true)` hides the profile switcher
    func test_receive_searchStateChanged_true_profilesHide() {
        subject.state.profileSwitcherState.isVisible = true
        subject.receive(.searchStateChanged(isSearching: true))

        XCTAssertFalse(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.searchTextChanged` without a matching search term updates the state correctly.
    func test_receive_searchTextChanged_withoutResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
        XCTAssertEqual(subject.state.searchResults.count, 0)
    }

    /// `receive(_:)` with `.searchTextChanged` with a matching search term updates the state correctly.
    func test_receive_searchTextChanged_withResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("example"))

        // TODO: BIT-628 Replace assertion with mock vault assertion
        XCTAssertEqual(subject.state.searchResults.count, 1)
    }

    /// `receive(_:)` with `.toggleProfilesViewVisibility` updates the state correctly.
    func test_receive_toggleProfilesViewVisibility() {
        subject.state.profileSwitcherState.isVisible = false
        subject.receive(.requestedProfileSwitcher(visible: true))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }
}
