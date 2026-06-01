import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherOwnershipHelperTests

class CipherOwnershipHelperTests: BitwardenTestCase {
    // MARK: Properties

    var policyService: MockPolicyService!
    var timeProvider: MockTimeProvider!
    var vaultRepository: MockVaultRepository!
    var subject: DefaultCipherOwnershipHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        policyService = MockPolicyService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 2, day: 14)))
        vaultRepository = MockVaultRepository()
        subject = DefaultCipherOwnershipHelper(
            policyService: policyService,
            timeProvider: timeProvider,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        policyService = nil
        timeProvider = nil
        vaultRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `createCipherView(from:)` throws `noDefaultCollection` when the default collection has a nil id.
    func test_createCipherView_defaultCollectionNilId() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )
        let organizationId = "org-123"

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = [organizationId]
        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: organizationId, name: "Test Organization"),
        ]
        // Return a default collection with nil id
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(
                id: nil,
                name: "Default Collection",
                organizationId: organizationId,
                type: .defaultUserCollection,
            ),
        ])

        await assertAsyncThrows(error: CipherOwnershipHelperError.noDefaultCollection) {
            _ = try await subject.createCipherView(from: fido2CredentialNewView)
        }
    }

    /// `createCipherView(from:)` selects the first eligible organization when multiple
    /// organizations have the policy.
    func test_createCipherView_multipleOrganizationsWithPolicy() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )
        let orgId1 = "org-1"
        let orgId2 = "org-2"
        let collectionId1 = "collection-1"

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = [orgId1, orgId2]
        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: orgId1, name: "First Organization"),
            .organization(id: orgId2, name: "Second Organization"),
        ]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(
                id: collectionId1,
                name: "Default Collection 1",
                organizationId: orgId1,
                type: .defaultUserCollection,
            ),
            .fixture(
                id: "collection-2",
                name: "Default Collection 2",
                organizationId: orgId2,
                type: .defaultUserCollection,
            ),
        ])

        let cipher = try await subject.createCipherView(from: fido2CredentialNewView)

        // Should select the first eligible organization
        XCTAssertEqual(cipher.organizationId, orgId1)
        XCTAssertEqual(cipher.collectionIds, [collectionId1])
    }

    /// `createCipherView(from:)` throws `noDefaultCollection` when personal ownership is disabled
    /// and an eligible organization is available but has no default collection.
    func test_createCipherView_noDefaultCollection() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )
        let organizationId = "org-123"

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = [organizationId]
        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: organizationId, name: "Test Organization"),
        ]
        // Return only shared collections, no default user collection
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(
                id: "collection-shared",
                name: "Shared Collection",
                organizationId: organizationId,
                type: .sharedCollection,
            ),
        ])

        await assertAsyncThrows(error: CipherOwnershipHelperError.noDefaultCollection) {
            _ = try await subject.createCipherView(from: fido2CredentialNewView)
        }
    }

    /// `createCipherView(from:)` throws `noEligibleOrganization` when personal ownership is disabled
    /// but no eligible organization is available.
    func test_createCipherView_noEligibleOrganization() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )
        let policyOrgId = "org-with-policy"

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = [policyOrgId]
        // Ownership options returns a different org (simulating the policy org not being confirmed)
        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: "different-org", name: "Different Organization"),
        ]

        await assertAsyncThrows(error: CipherOwnershipHelperError.noEligibleOrganization) {
            _ = try await subject.createCipherView(from: fido2CredentialNewView)
        }
    }

    /// `createCipherView(from:)` creates a cipher with the eligible organization and default collection
    /// when personal ownership is disabled.
    func test_createCipherView_personalOwnershipDisabled() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )
        let organizationId = "org-123"
        let collectionId = "collection-456"

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = [organizationId]
        vaultRepository.fetchCipherOwnershipOptions = [
            .organization(id: organizationId, name: "Test Organization"),
        ]
        vaultRepository.fetchCollectionsResult = .success([
            .fixture(
                id: collectionId,
                name: "Default Collection",
                organizationId: organizationId,
                type: .defaultUserCollection,
            ),
        ])

        let cipher = try await subject.createCipherView(from: fido2CredentialNewView)

        XCTAssertEqual(cipher.organizationId, organizationId)
        XCTAssertEqual(cipher.collectionIds, [collectionId])
        XCTAssertEqual(cipher.name, "Example App")
        XCTAssertEqual(cipher.login?.username, "testuser")
        XCTAssertEqual(vaultRepository.fetchCipherOwnershipOptionsIncludePersonal, false)
        XCTAssertEqual(vaultRepository.fetchCollectionsIncludeReadOnly, false)
    }

    /// `createCipherView(from:)` creates a cipher with nil organizationId and empty collectionIds
    /// when personal ownership is enabled (no policy).
    func test_createCipherView_personalOwnershipEnabled() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: "Example App",
        )

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = []

        let cipher = try await subject.createCipherView(from: fido2CredentialNewView)

        XCTAssertNil(cipher.organizationId)
        XCTAssertEqual(cipher.collectionIds, [])
        XCTAssertEqual(cipher.name, "Example App")
        XCTAssertEqual(cipher.login?.username, "testuser")
        XCTAssertEqual(cipher.login?.uris?.first?.uri, "example.com")
    }

    /// `createCipherView(from:)` uses rpId as name when rpName is nil.
    func test_createCipherView_usesRpIdWhenRpNameNil() async throws {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            rpId: "example.com",
            userName: "testuser",
            rpName: nil,
        )

        policyService.organizationsApplyingPolicyToUserResult[.personalOwnership] = []

        let cipher = try await subject.createCipherView(from: fido2CredentialNewView)

        XCTAssertEqual(cipher.name, "example.com")
    }
}
