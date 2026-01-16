import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class MigrateToMyItemsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var delegate: MockMigrateToMyItemsProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var subject: MigrateToMyItemsProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockMigrateToMyItemsProcessorDelegate()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = MigrateToMyItemsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
            state: MigrateToMyItemsState(organizationId: "org-123"),
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

    // MARK: Tests - AcceptTransferTapped Effect

    /// `perform(_:)` with `.acceptTransferTapped` migrates the personal vault and dismisses.
    @MainActor
    func test_perform_acceptTransferTapped_success() async {
        vaultRepository.migratePersonalVaultResult = .success(())

        await subject.perform(.acceptTransferTapped)

        XCTAssertEqual(vaultRepository.migratePersonalVaultOrganizationId, "org-123")
        XCTAssertEqual(coordinator.routes.last, .dismiss())
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.acceptTransferTapped` shows an error alert and dismisses when migration fails.
    @MainActor
    func test_perform_acceptTransferTapped_error() async {
        vaultRepository.migratePersonalVaultResult = .failure(BitwardenTestError.example)

        await subject.perform(.acceptTransferTapped)

        XCTAssertEqual(vaultRepository.migratePersonalVaultOrganizationId, "org-123")
        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

        // Simulate alert dismissal to trigger the dismiss navigation.
        coordinator.alertOnDismissed?()

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    // MARK: Tests - Appeared Effect

    /// `perform(_:)` with `.appeared` loads the organization name from the vault repository.
    @MainActor
    func test_perform_appeared_success() async {
        let organization = Organization(
            enabled: true,
            id: "org-123",
            key: nil,
            keyConnectorEnabled: false,
            keyConnectorUrl: nil,
            name: "Test Organization",
            permissions: Permissions(),
            status: .confirmed,
            type: .user,
            useEvents: false,
            usePolicies: false,
            userIsManagedByOrganization: false,
            usersGetPremium: false,
        )
        vaultRepository.fetchOrganizationResult = .success(organization)

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.organizationName, "Test Organization")
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }

    /// `perform(_:)` with `.appeared` shows an alert and dismisses when the organization is not found.
    @MainActor
    func test_perform_appeared_organizationNotFound() async {
        vaultRepository.fetchOrganizationResult = .success(nil)

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.organizationName, "")
        XCTAssertEqual(coordinator.alertShown.count, 1)
        XCTAssertEqual(coordinator.alertShown.last?.title, Localizations.organizationNotFound)

        // Simulate alert dismissal to trigger the dismiss navigation.
        coordinator.alertOnDismissed?()

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `perform(_:)` with `.appeared` shows an error alert and logs the error when fetching fails.
    @MainActor
    func test_perform_appeared_error() async {
        vaultRepository.fetchOrganizationResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.organizationName, "")
        XCTAssertEqual(coordinator.alertShown.count, 1)
        XCTAssertEqual(coordinator.alertShown.last?.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }
}

// MARK: - MockMigrateToMyItemsProcessorDelegate

class MockMigrateToMyItemsProcessorDelegate: MigrateToMyItemsProcessorDelegate {
    var didLeaveOrganizationCalled = false

    func didLeaveOrganization() {
        didLeaveOrganizationCalled = true
    }
}
