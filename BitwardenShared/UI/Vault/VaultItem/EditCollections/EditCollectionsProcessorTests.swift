import BitwardenSdk
import XCTest

@testable import BitwardenShared

class EditCollectionsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute>!
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
    func test_perform_fetchCipherOptions_error() async {
        vaultRepository.fetchCollectionsResult = .failure(StateServiceError.noActiveAccount)

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `receive(_:)` with `.collectionToggleChanged` updates the selected collection IDs for the cipher.
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
