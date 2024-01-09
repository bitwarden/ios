import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: VaultGroupProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        vaultRepository = MockVaultRepository()

        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                vaultRepository: vaultRepository
            ),
            state: VaultGroupState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `itemDeleted()` delegate method shows the expected toast.
    func test_delegate_itemDeleted() {
        XCTAssertNil(subject.state.toast)

        subject.itemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.itemSoftDeleted)
    }

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

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for a card cipher.
    func test_perform_morePressed_card() async throws {
        // TODO: BIT-1365
        // TODO: BIT-1374
    }

    /// `perform(_:)` with `.morePressed` handles errors correctly.
    func test_perform_morePressed_error() async throws {
        vaultRepository.fetchCipherResult = .failure(BitwardenTestError.example)

        await subject.perform(.morePressed(.fixture()))

        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for a login cipher.
    func test_perform_morePressed_login() async throws {
        let item = try XCTUnwrap(VaultListItem(cipherListView: CipherListView.fixture(type: .login)))

        // If the login item has no username, password, or url, only the view and add buttons should display.
        vaultRepository.fetchCipherResult = .success(.loginFixture())
        await subject.perform(.morePressed(item))
        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        // If the item is in the trash, the edit option should not display.
        subject.state.group = .trash
        await subject.perform(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // A login with data should show the copy and launch actions.
        let loginWithData = CipherView.loginFixture(login: .fixture(
            password: "password",
            uris: [.init(uri: URL.example.relativeString, match: nil)],
            username: "username"
        ))
        vaultRepository.fetchCipherResult = .success(loginWithData)
        subject.state.group = .login
        await subject.perform(.morePressed(item))
        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.alertActions.count, 6)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.view)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.edit)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[3].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[4].title, Localizations.launch)
        XCTAssertEqual(alert.alertActions[5].title, Localizations.cancel)

        // Test the functionality of the buttons.

        // View navigates to the view item view.
        let viewAction = try XCTUnwrap(alert.alertActions[0])
        await viewAction.handler?(viewAction, [])
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: item.id))

        // Edit navigates to the edit view.
        let editAction = try XCTUnwrap(alert.alertActions[1])
        await editAction.handler?(editAction, [])
        XCTAssertEqual(coordinator.routes.last, .editItem(cipher: loginWithData))

        // Copy username copies the username.
        let copyUsernameAction = try XCTUnwrap(alert.alertActions[2])
        await copyUsernameAction.handler?(copyUsernameAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "username")

        // Copy password copies the user's username.
        let copyPasswordAction = try XCTUnwrap(alert.alertActions[3])
        await copyPasswordAction.handler?(copyPasswordAction, [])
        XCTAssertEqual(pasteboardService.copiedString, "password")

        // Launch action set's the url to open.
        let launchAction = try XCTUnwrap(alert.alertActions[4])
        await launchAction.handler?(launchAction, [])
        XCTAssertEqual(subject.state.url, .example)
    }

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for an identity cipher.
    func test_perform_morePressed_identity() async throws {
        // TODO: BIT-1364
        // TODO: BIT-1368
    }

    /// `perform(_:)` with `.morePressed` shows the appropriate more options alert for a secure note cipher.
    func test_perform_morePressed_secureNote() async throws {
        // TODO: BIT-1366
        // TODO: BIT-1375
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

    /// `receive(_:)` with `.clearURL` clears the url in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.itemPressed` on a cipher navigates to the `.viewItem` route.
    func test_receive_itemPressed_cipher() {
        subject.receive(.itemPressed(.fixture(cipherListView: .fixture(id: "id"))))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "id"))
    }

    /// `receive(_:)` with `.itemPressed` on a group navigates to the `.group` route.
    func test_receive_itemPressed_group() {
        subject.receive(.itemPressed(VaultListItem(id: "1", itemType: .group(.card, 2))))
        XCTAssertEqual(coordinator.routes.last, .group(.card))
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
