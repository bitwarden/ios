import BitwardenKit
import BitwardenSdk

// MARK: - CipherOwnershipHelperError

/// Errors thrown by `CipherOwnershipHelper`.
enum CipherOwnershipHelperError: Error, Equatable {
    /// No eligible organization is available for cipher ownership when personal ownership is disabled.
    case noEligibleOrganization
}

// MARK: - CipherOwnershipHelper

/// A helper to create cipher views with proper ownership based on policies.
protocol CipherOwnershipHelper { // sourcery: AutoMockable
    /// Creates a `CipherView` from a Fido2 credential with proper organization/collection
    /// ownership based on personal ownership policies.
    ///
    /// - Parameter fido2CredentialNewView: The Fido2 credential new view containing the credential data.
    /// - Returns: A `CipherView` configured with the appropriate organization and collection IDs
    ///   based on the user's personal ownership policy.
    /// - Throws: `CipherOwnershipHelperError.noEligibleOrganization` if personal ownership is disabled
    ///   but no eligible organization is available.
    func createCipherView(from fido2CredentialNewView: Fido2CredentialNewView) async throws -> CipherView
}

// MARK: - DefaultCipherOwnershipHelper

/// Default implementation of `CipherOwnershipHelper`.
class DefaultCipherOwnershipHelper: CipherOwnershipHelper {
    // MARK: Properties

    /// The service for managing the polices for the user.
    private let policyService: PolicyService

    /// Provides the present time for cipher creation.
    private let timeProvider: TimeProvider

    /// The repository used to manage vault data.
    private let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Initializes a new `DefaultCipherOwnershipHelper`.
    ///
    /// - Parameters:
    ///   - policyService: The service for managing the polices for the user.
    ///   - timeProvider: Provides the present time for cipher creation.
    ///   - vaultRepository: The repository used to manage vault data.
    init(
        policyService: PolicyService,
        timeProvider: TimeProvider,
        vaultRepository: VaultRepository,
    ) {
        self.policyService = policyService
        self.timeProvider = timeProvider
        self.vaultRepository = vaultRepository
    }

    // MARK: Methods

    func createCipherView(from fido2CredentialNewView: Fido2CredentialNewView) async throws -> CipherView {
        // Check if personal ownership is disabled and get the default owner/collections
        let organizationsWithPersonalOwnershipPolicy = await policyService
            .organizationsApplyingPolicyToUser(.personalOwnership)
        let isPersonalOwnershipDisabled = !organizationsWithPersonalOwnershipPolicy.isEmpty

        var organizationId: String?
        var collectionIds: [String] = []

        if isPersonalOwnershipDisabled {
            let ownershipOptions = try await vaultRepository
                .fetchCipherOwnershipOptions(includePersonal: false)

            // Find an org that both has the policy AND is eligible for ownership
            let eligibleOwner = ownershipOptions.first { owner in
                guard let orgId = owner.organizationId else { return false }
                return organizationsWithPersonalOwnershipPolicy.contains(orgId)
            }

            guard let defaultOwner = eligibleOwner,
                  let ownerOrgId = defaultOwner.organizationId else {
                // No eligible organization available - abort with error
                throw CipherOwnershipHelperError.noEligibleOrganization
            }

            organizationId = ownerOrgId

            // Get the default collection for the organization
            let collections = try await vaultRepository.fetchCollections(includeReadOnly: false)
            let collectionsForOwner = collections.filter { $0.organizationId == ownerOrgId }

            if let defaultCollection = collectionsForOwner.first(where: {
                $0.type == .defaultUserCollection
            }),
                let defaultCollectionId = defaultCollection.id {
                collectionIds = [defaultCollectionId]
            }
        }

        return CipherView(
            fido2CredentialNewView: fido2CredentialNewView,
            organizationId: organizationId,
            collectionIds: collectionIds,
            timeProvider: timeProvider,
        )
    }
}
