import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class EditCollectionsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockEditCollectionsProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var subject: EditCollectionsProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockEditCollectionsProcessorDelegate()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = EditCollectionsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: EditCollectionsState(cipher: .fixture(organizationId: "1"))
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher from the repository.
    @MainActor
    func test_perform_fetchCipherOptions() async {
        let collections: [CollectionView] = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]

        vaultRepository.fetchCollectionsResult = .success(
            collections + [.fixture(id: "1", name: "Other Org Collection", organizationId: "555")]
        )

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collections, collections)
        try XCTAssertFalse(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))
    }

    /// `perform(_:)` with `.fetchCipherOptions` reports an error if one occurs.
    @MainActor
    func test_perform_fetchCipherOptions_error() async {
        vaultRepository.fetchCollectionsResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `perform(_:)` with `.save` saves the updated cipher.
    @MainActor
    func test_perform_save() async {
        subject.state.collectionIds = ["1"]

        await subject.perform(.save)

        XCTAssertEqual(vaultRepository.updateCipherCollectionsCiphers, [subject.state.updatedCipher])
        let updatedCipher = vaultRepository.updateCipherCollectionsCiphers[0]
        XCTAssertEqual(updatedCipher.collectionIds, ["1"])

        guard case let .dismiss(dismissAction) = coordinator.routes.last else {
            return XCTFail("Expected a `.dismiss` route.")
        }
        dismissAction?.action()

        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.saving)])
        XCTAssertTrue(delegate.didUpdateCipherCalled)
    }

    /// `perform(_:)` with `.save` shows an alert if an error occurs updating the cipher.
    @MainActor
    func test_perform_save_error() async {
        subject.state.collectionIds = ["1"]

        struct UpdateCipherError: Error, Equatable {}
        vaultRepository.updateCipherCollectionsResult = .failure(UpdateCipherError())

        await subject.perform(.save)

        XCTAssertEqual(coordinator.errorAlertsShown as? [UpdateCipherError], [UpdateCipherError()])
        XCTAssertEqual(errorReporter.errors.last as? UpdateCipherError, UpdateCipherError())
    }

    /// `perform(_:)` with `.save` shows an alert if no collections have been selected.
    @MainActor
    func test_perform_moveCipher_errorNoCollections() async {
        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.selectOneCollection
            )
        )
    }

    /// `receive(_:)` with `.collectionToggleChanged` updates the selected collection IDs for the cipher.
    @MainActor
    func test_receive_collectionToggleChanged() {
        subject.state.collections = [
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        subject.receive(.collectionToggleChanged(true, collectionId: "1"))
        XCTAssertEqual(subject.state.collectionIds, ["1"])

        subject.receive(.collectionToggleChanged(true, collectionId: "2"))
        XCTAssertEqual(subject.state.collectionIds, ["1", "2"])

        subject.receive(.collectionToggleChanged(false, collectionId: "1"))
        XCTAssertEqual(subject.state.collectionIds, ["2"])
    }

    /// `receive(_:)` with `.dismissPressed` dismisses the view.
    @MainActor
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }
}

class MockEditCollectionsProcessorDelegate: EditCollectionsProcessorDelegate {
    var didUpdateCipherCalled = false

    func didUpdateCipher() {
        didUpdateCipherCalled = true
    }
}
