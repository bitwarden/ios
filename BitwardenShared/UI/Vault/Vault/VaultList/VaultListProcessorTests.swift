import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

class VaultListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute>!
    var subject: VaultListProcessor!
    var vaultRepository: MockVaultRepository!

    let profile1 = ProfileSwitcherItem()
    let profile2 = ProfileSwitcherItem()

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        vaultRepository = MockVaultRepository()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
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
        authRepository = nil
        coordinator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts listening for updates with the vault repository.
    func test_perform_appeared() async {
        await subject.perform(.appeared)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `.refreshed` requests a fetch sync update with the vault repository.
    func test_perform_refresh() async {
        await subject.perform(.refreshVault)

        XCTAssertTrue(vaultRepository.fetchSyncCalled)
    }

    /// `perform(.refreshAccountProfiles)` without profiles for the profile switcher.
    func test_perform_refresh_profiles_empty() async {
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [])
    }

    // swiftlint:disable:next line_length
    /// `perform(.refreshAccountProfiles)` with mismatched active account and accounts should yield an empty profile switcher state.
    func test_perform_refresh_profiles_mismatch() async {
        let profile = ProfileSwitcherItem()
        authRepository.accountsResult = .success([])
        authRepository.activeAccountResult = .success(profile)
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [])
    }

    /// `perform(.refreshAccountProfiles)` with an active account and accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_active() async {
        authRepository.accountsResult = .success([profile1])
        authRepository.activeAccountResult = .success(profile1)
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(profile1, subject.state.profileSwitcherState.activeAccountProfile)
    }

    // swiftlint:disable:next line_length
    /// `perform(.refreshAccountProfiles)` with no active account and accounts should yield an empty profile switcher state.
    func test_perform_refresh_profiles_single_notActive() async {
        authRepository.accountsResult = .success([profile1])
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual(subject.state.profileSwitcherState.activeAccountInitials, "..")
        XCTAssertEqual(subject.state.profileSwitcherState.alternateAccounts, [profile1])
        XCTAssertEqual(subject.state.profileSwitcherState.accounts, [profile1])
    }

    // swiftlint:disable:next line_length
    /// `perform(.refreshAccountProfiles)` with an active account and multiple accounts should yield a profile switcher state.
    func test_perform_refresh_profiles_single_multiAccount() async {
        authRepository.accountsResult = .success([profile1, profile2])
        authRepository.activeAccountResult = .success(profile1)
        await subject.perform(.refreshAccountProfiles)

        XCTAssertEqual([profile2], subject.state.profileSwitcherState.alternateAccounts)
        XCTAssertEqual(profile1, subject.state.profileSwitcherState.activeAccountProfile)
    }

    /// `perform(_:)` with `.streamOrganizations` updates the state's organizations whenever it changes.
    func test_perform_streamOrganizations() {
        let task = Task {
            await subject.perform(.streamOrganizations)
        }

        let organizations = [
            Organization.fixture(id: "1", name: "Organization1"),
            Organization.fixture(id: "2", name: "Organization2"),
        ]

        vaultRepository.organizationsSubject.value = organizations

        waitFor { !subject.state.organizations.isEmpty }
        task.cancel()

        XCTAssertEqual(subject.state.organizations, organizations)
    }

    /// `perform(_:)` with `.streamVaultList` updates the state's vault list whenever it changes.
    func test_perform_streamVaultList() throws {
        let vaultListItem = VaultListItem.fixture()
        vaultRepository.vaultListSubject.send([
            VaultListSection(
                id: "1",
                items: [vaultListItem],
                name: "Name"
            ),
        ])

        let task = Task {
            await subject.perform(.streamVaultList)
        }

        waitFor(subject.state.loadingState != .loading)
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [vaultListItem])
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

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for add Account
    func test_perform_rowAppeared_add() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.addAccount)))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should not update the state for alternate account
    func test_perform_rowAppeared_alternate() async {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: true
        )

        await subject.perform(.profileSwitcher(.rowAppeared(.alternate(alternate))))

        XCTAssertFalse(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
    }

    /// `perform(.profileSwitcher(.rowAppeared))` should update the state for active account
    func test_perform_rowAppeared_active() {
        let profile = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem()
        subject.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [profile, alternate],
            activeAccountId: profile.userId,
            isVisible: true
        )

        let task = Task {
            await subject.perform(.profileSwitcher(.rowAppeared(.active(profile))))
        }

        waitFor(subject.state.profileSwitcherState.hasSetAccessibilityFocus, timeout: 0.5)
        task.cancel()
        XCTAssertTrue(subject.state.profileSwitcherState.hasSetAccessibilityFocus)
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

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
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

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.toggleProfilesViewVisibility` updates the state correctly.
    func test_receive_toggleProfilesViewVisibility() {
        subject.state.profileSwitcherState.isVisible = false
        subject.receive(.profileSwitcherAction(.requestedProfileSwitcher(visible: true)))

        XCTAssertTrue(subject.state.profileSwitcherState.isVisible)
    }

    /// `receive(_:)` with `.vaultFilterChanged` updates the state correctly.
    func test_receive_vaultFilterChanged() {
        let organization = Organization.fixture()

        subject.state.vaultFilterType = .myVault
        subject.receive(.vaultFilterChanged(.organization(organization)))

        XCTAssertEqual(subject.state.vaultFilterType, .organization(organization))
    }
}
