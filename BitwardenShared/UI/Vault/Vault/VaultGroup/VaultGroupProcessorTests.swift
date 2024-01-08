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

    /// `receive` with `.copyTOTPCode` copies the value with the pasteboard service.
    func test_receive_copyTOTPCode() {
        subject.receive(.copyTOTPCode("123456"))
        XCTAssertEqual(pasteboardService.copiedString, "123456")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.verificationCode))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed() {
        subject.receive(.itemPressed(.fixture(cipherListView: .fixture(id: "id"))))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: "id"))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.group` route.
    func test_receive_itemPressed_group() {
        let groupItem = VaultListItem.fixtureGroup(group: .identity)
        subject.receive(.itemPressed(groupItem))
        XCTAssertEqual(coordinator.routes.last, .group(.identity))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed_totp() {
        let totpItem = VaultListItem.fixtureTOTP()
        subject.receive(.itemPressed(totpItem))
        XCTAssertEqual(coordinator.routes.last, .viewItem(id: totpItem.id))
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

    /// TOTP Code expiration updates the state's TOTP codes.
    func test_receive_appeared_totpExpired_single() throws {
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    date: .distantPast,
                    period: 30
                )
            )
        )
        let newResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "345678",
                    date: Date(),
                    period: 30
                )
            )
        )
        vaultRepository.refreshTOTPCodesResult = .success([
            newResult,
        ])
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListGroupSubject.send([result])
        waitFor(!vaultRepository.refreshTOTPCodes.isEmpty)
        waitFor(subject.state.loadingState.data == [newResult])
        task.cancel()
        XCTAssertEqual([result], vaultRepository.refreshTOTPCodes)
        let first = try XCTUnwrap(subject.state.loadingState.data?.first)
        XCTAssertEqual(first, newResult)
    }

    /// TOTP Code expiration updates the state's TOTP codes.
    func test_receive_appeared_totpExpired_multi() throws {
        let expiredResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "123",
                totpCode: .init(
                    code: "",
                    date: .distantPast,
                    period: 30
                )
            )
        )
        let expectedUpdate = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "123",
                totpCode: .init(
                    code: "345678",
                    date: Date(),
                    period: 30
                )
            )
        )
        let newResults: [VaultListItem] = [
            expectedUpdate,
            .fixtureTOTP(
                totp: .fixture(
                    id: "456",
                    totpCode: .init(
                        code: "345678",
                        date: Date(),
                        period: 30
                    )
                )
            ),
        ]
        vaultRepository.refreshTOTPCodesResult = .success(newResults)
        let task = Task {
            await subject.perform(.appeared)
        }
        let stableResult = VaultListItem.fixtureTOTP(
            totp: .fixture(
                id: "789",
                totpCode: .init(
                    code: "",
                    date: Date(),
                    period: 30
                )
            )
        )
        vaultRepository.vaultListGroupSubject.send([
            expiredResult,
            stableResult,
        ])
        waitFor(!vaultRepository.refreshTOTPCodes.isEmpty)
        waitFor(subject.state.loadingState.data == [expectedUpdate, stableResult])
        task.cancel()
        XCTAssertEqual([expiredResult], vaultRepository.refreshTOTPCodes)
    }

    /// `receive(_:)` with `.totpCodeExpired` handles errors.
    func test_receive_totpExpired_error() throws {
        struct TestError: Error, Equatable {}
        let result = VaultListItem.fixtureTOTP(
            totp: .fixture(
                totpCode: .init(
                    code: "",
                    date: .distantPast,
                    period: 30
                )
            )
        )
        vaultRepository.refreshTOTPCodesResult = .failure(TestError())
        let task = Task {
            await subject.perform(.appeared)
        }
        vaultRepository.vaultListGroupSubject.send([result])
        waitFor(!vaultRepository.refreshTOTPCodes.isEmpty)
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        let first = try XCTUnwrap(errorReporter.errors.first as? TestError)
        XCTAssertEqual(first, TestError())
    }

    /// `receive(_:)` with `.totpCodeExpired` does nothing in a loading state.
    func test_receive_totpExpired_loading() throws {
        let result = VaultListItem.fixtureTOTP()
        subject.state.loadingState = .loading
        subject.receive(.totpCodeExpired(.fixture()))
        XCTAssertTrue(vaultRepository.refreshTOTPCodes.isEmpty)
    }
}
