// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - VaultListViewTests

class VaultListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListState, VaultListAction, VaultListEffect>!
    var subject: VaultListView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let account = ProfileSwitcherItem.fixture(
            email: "anne.account@bitwarden.com",
            userInitials: "AA",
        )
        let state = VaultListState(
            profileSwitcherState: ProfileSwitcherState(
                accounts: [account],
                activeAccountId: account.userId,
                allowLockAndLogout: true,
                isVisible: false,
            ),
        )
        processor = MockProcessor(state: state)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultListView(
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

    /// Tapping the add the new login button dispatches the `.addItemPressed` action.
    @MainActor
    func test_newLoginButton_tap() throws {
        processor.state.loadingState = .data([])
        let button = try subject.inspect().find(button: Localizations.newLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(.login))
    }

    /// Tapping the floating action button dispatches the `.addItemPressed` action for a new login type.
    @MainActor
    func test_addItemFloatingActionButton_tap() throws {
        let fab = try subject.inspect().find(viewWithAccessibilityIdentifier: "AddItemFloatingActionButton")
        try fab.find(button: Localizations.typeLogin).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(.login))
    }

    /// Tapping the floating action button dispatches the `.addItemPressed` action for a new identity type.
    @MainActor
    func test_addItemFloatingActionButton_tap_identity() throws {
        let fab = try subject.inspect().find(viewWithAccessibilityIdentifier: "AddItemFloatingActionButton")
        try fab.find(button: Localizations.typeIdentity).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed(.identity))
    }

    /// Tapping the add folder button in the FAB dispatches the `.addFolder` action.
    @MainActor
    func test_addItemFloatingActionButton_tap_addFolder() throws {
        let fab = try subject.inspect().find(viewWithAccessibilityIdentifier: "AddItemFloatingActionButton")
        try fab.find(button: Localizations.folder).tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addFolder)
    }

    /// The floating action button will be hidden if .
    @MainActor
    func test_addItemFloatingActionButton_hidden_policy_enable() throws {
        processor.state.loadingState = .data([])
        processor.state.itemTypesUserCanCreate = [.login, .identity, .secureNote]
        let fab = try subject.inspect().find(viewWithAccessibilityIdentifier: "AddItemFloatingActionButton")
        XCTAssertThrowsError(try fab.find(button: Localizations.typeCard))
    }

    /// Long pressing a profile row dispatches the `.accountLongPressed` action.
    @MainActor
    func test_accountRow_longPress_currentAccount() throws {
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test is for iOS < 26 and relies on the visibility of the profile switcher.")
        }

        processor.state.profileSwitcherState.isVisible = true
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        let currentAccount = processor.state.profileSwitcherState.activeAccountProfile!
        try accountRow.labelView().callOnLongPressGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.accountLongPressed(currentAccount)))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_accountRow_tap_currentAccount() throws {
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test is for iOS < 26 and relies on the visibility of the profile switcher.")
        }

        processor.state.profileSwitcherState.isVisible = true
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        let currentAccount = processor.state.profileSwitcherState.activeAccountProfile!
        try accountRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.accountPressed(currentAccount)))
    }

    /// Tapping the add account row dispatches the `.addAccountPressed ` action.
    @MainActor
    func test_accountRow_tap_addAccount() throws {
        guard #unavailable(iOS 26) else {
            throw XCTSkip("This test is for iOS < 26 and relies on the visibility of the profile switcher.")
        }

        processor.state.profileSwitcherState.isVisible = true
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .profileSwitcher(.addAccountPressed))
    }

    /// The action card is hidden if the import logins setup progress is set up later or complete.
    @MainActor
    func test_importLoginsActionCard_hidden() {
        processor.state.loadingState = .data([])

        // Hidden by default when set up progress is `nil`.
        XCTAssertThrowsError(try subject.inspect().find(actionCard: Localizations.importSavedLogins))

        processor.state.importLoginsSetupProgress = .setUpLater
        XCTAssertThrowsError(try subject.inspect().find(actionCard: Localizations.importSavedLogins))

        processor.state.importLoginsSetupProgress = .complete
        XCTAssertThrowsError(try subject.inspect().find(actionCard: Localizations.importSavedLogins))
    }

    /// The action card is visible if the import logins setup progress is incomplete.
    @MainActor
    func test_importLoginsActionCard_visible() async throws {
        processor.state.importLoginsSetupProgress = .incomplete
        processor.state.loadingState = .data([])
        XCTAssertNoThrow(try subject.inspect().find(actionCard: Localizations.importSavedLogins))
    }

    /// Tapping the dismiss button in the import logins action card sends the
    /// `.dismissImportLoginsActionCard` effect.
    @MainActor
    func test_importLoginsActionCard_visible_tapDismiss() async throws {
        processor.state.importLoginsSetupProgress = .incomplete
        processor.state.loadingState = .data([])
        let actionCard = try subject.inspect().find(actionCard: Localizations.importSavedLogins)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissImportLoginsActionCard])
    }

    /// Tapping the get started button in the set up unlock action card sends the
    /// `.showSetUpUnlock` action.
    @MainActor
    func test_importLoginsActionCard_visible_tapGetStarted() async throws {
        processor.state.importLoginsSetupProgress = .incomplete
        processor.state.loadingState = .data([])
        let actionCard = try subject.inspect().find(actionCard: Localizations.importSavedLogins)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.showImportLogins])
    }

    /// Tapping the profile button dispatches the `.requestedProfileSwitcher` effect.
    @MainActor
    func test_profileButton_tap_withProfilesViewNotVisible() async throws {
        processor.state.profileSwitcherState.isVisible = false
        let buttonUnselected = try subject.inspect().find(asyncButton: "AA")
        try await buttonUnselected.tap()
        XCTAssertEqual(
            processor.effects.last,
            .profileSwitcher(.requestedProfileSwitcher(visible: true)),
        )
    }

    /// Tapping the profile button dispatches the `.requestedProfileSwitcher` effect.
    @MainActor
    func test_profileButton_tap_withProfilesViewVisible() async throws {
        processor.state.profileSwitcherState.isVisible = true
        let buttonUnselected = try subject.inspect().find(asyncButton: "AA")
        try await buttonUnselected.tap()

        XCTAssertEqual(
            processor.effects.last,
            .profileSwitcher(.requestedProfileSwitcher(visible: false)),
        )
    }

    /// Tapping the search result dispatches the `.itemPressed` action.
    @MainActor
    func test_searchResult_tap() throws {
        let result = VaultListItem.fixture()
        processor.state.searchResults = [result]
        let button = try subject.inspect().find(button: "Bitwarden")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: result))
    }

    /// Tapping the go to settings button in the flight recorder toast banner dispatches the
    /// `.navigateToFlightRecorderSettings` action.
    @MainActor
    func test_toastBannerGoToSettings_tap() async throws {
        processor.state.flightRecorderToastBanner.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 4, day: 3),
        )
        let button = try subject.inspect().find(button: Localizations.goToSettings)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.navigateToFlightRecorderSettings])
    }

    /// Tapping the try again button dispatches the `.tryAgainTapped` action.
    @MainActor
    func test_tryAgainButton_tap() async throws {
        processor.state.loadingState = .error(
            errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs,
        )
        let button = try subject.inspect().find(asyncButton: Localizations.tryAgain)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.tryAgainTapped])
    }

    /// Tapping the vault item dispatches the `.itemPressed` action.
    @MainActor
    func test_vaultItem_tap() throws {
        let item = VaultListItem(id: "1", itemType: .group(.login, 123))
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(LoadingViewType.self)
            .find(ViewType.Button.self) { view in
                _ = try view.find { try $0.accessibilityIdentifier() == "ItemFilterCell" }
                return true
            }
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemPressed(item: item))
    }

    /// Tapping the vault item copy totp button dispatches the `.copyTOTPCode` action.
    @MainActor
    func test_vaultItem_copyTOTPButton_tap() throws {
        let item = VaultListItem.fixtureTOTP(totp: .fixture())
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode("123456"))
    }

    /// Tapping the vault item more button dispatches the `.morePressed` action.
    @MainActor
    func test_vaultItem_moreButton_tap() async throws {
        let item = VaultListItem.fixture()
        processor.state.loadingState = .data([VaultListSection(id: "1", items: [item], name: "Group")])
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.more)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .morePressed(item))
    }
}
