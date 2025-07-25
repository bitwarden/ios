import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class MoveToOrganizationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockMoveToOrganizationProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var subject: MoveToOrganizationProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockMoveToOrganizationProcessorDelegate()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = MoveToOrganizationProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: MoveToOrganizationState(cipher: .fixture())
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
            .fixture(id: "1", name: "Design"),
            .fixture(id: "2", name: "Engineering"),
        ]

        vaultRepository.fetchCipherOwnershipOptions = [.organization(id: "1", name: "Organization")]
        vaultRepository.fetchCollectionsResult = .success(collections)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.collections, collections)
        XCTAssertEqual(subject.state.ownershipOptions, [.organization(id: "1", name: "Organization")])
        try XCTAssertFalse(XCTUnwrap(vaultRepository.fetchCollectionsIncludeReadOnly))
        try XCTAssertFalse(XCTUnwrap(vaultRepository.fetchCipherOwnershipOptionsIncludePersonal))
    }

    /// `perform(_:)` with `.fetchCipherOptions` reports an error if one occurs.
    func test_perform_fetchCipherOptions_error() async {
        vaultRepository.fetchCollectionsResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `perform(_:)` with `.moveCipher` shares the updated cipher.
    @MainActor
    func test_perform_moveCipher() async {
        subject.state.ownershipOptions = [.organization(id: "123", name: "Organization")]
        subject.state.collectionIds = ["1"]
        subject.state.organizationId = "123"

        await subject.perform(.moveCipher)

        XCTAssertEqual(vaultRepository.shareCipherCiphers, [subject.state.cipher])

        guard case let .dismiss(dismissAction) = coordinator.routes.last else {
            return XCTFail("Expected a `.dismiss` route.")
        }
        dismissAction?.action()

        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.saving)])
        XCTAssertEqual(delegate.didMoveCipherCipher, subject.state.cipher)
        XCTAssertEqual(delegate.didMoveCipherOrganization, .organization(id: "123", name: "Organization"))
    }

    /// `perform(_:)` with `.moveCipher` shows an alert if an error occurs sharing the cipher.
    @MainActor
    func test_perform_moveCipher_error() async {
        subject.state.ownershipOptions = [.organization(id: "123", name: "Organization")]
        subject.state.collectionIds = ["1"]
        subject.state.organizationId = "123"

        struct ShareCipherError: Error, Equatable {}
        vaultRepository.shareCipherResult = .failure(ShareCipherError())

        await subject.perform(.moveCipher)

        XCTAssertEqual(coordinator.errorAlertsShown as? [ShareCipherError], [ShareCipherError()])
        XCTAssertEqual(errorReporter.errors.last as? ShareCipherError, ShareCipherError())
    }

    /// `perform(_:)` with `.moveCipher` shows an alert if no collections have been selected.
    @MainActor
    func test_perform_moveCipher_errorNoCollections() async {
        await subject.perform(.moveCipher)

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

    /// `receive(_:)` with `.ownerChanged` updates the state correctly.
    @MainActor
    func test_receive_ownerChanged() {
        let organization1 = CipherOwner.organization(id: "1", name: "Organization 1")
        let organization2 = CipherOwner.organization(id: "2", name: "Organization 2")
        subject.state.ownershipOptions = [organization1, organization2]

        XCTAssertEqual(subject.state.owner, organization1)

        subject.receive(.ownerChanged(organization2))

        XCTAssertEqual(subject.state.owner, organization2)
    }
}

class MockMoveToOrganizationProcessorDelegate: MoveToOrganizationProcessorDelegate {
    var didMoveCipherCipher: CipherView?
    var didMoveCipherOrganization: CipherOwner?

    func didMoveCipher(_ cipher: CipherView, to organization: CipherOwner) {
        didMoveCipherCipher = cipher
        didMoveCipherOrganization = organization
    }
}
