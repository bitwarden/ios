import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockOrganizationService: OrganizationService {
    var fetchAllOrganizationsResult: Result<[Organization], Error> = .success([])

    var initializeOrganizationCryptoCalled = false
    var initializeOrganizationCryptoWithOrgsCalled = false // swiftlint:disable:this identifier_name

    var organizationsSubject = CurrentValueSubject<[Organization], Error>([])

    var replaceOrganizationsOrganizations: [ProfileOrganizationResponseModel]?
    var replaceOrganizationsUserId: String?

    func fetchAllOrganizations() async throws -> [Organization] {
        try fetchAllOrganizationsResult.get()
    }

    func initializeOrganizationCrypto() async throws {
        initializeOrganizationCryptoCalled = true
    }

    func initializeOrganizationCrypto(organizations: [Organization]) async {
        initializeOrganizationCryptoWithOrgsCalled = true
    }

    func organizationsPublisher() async throws -> AnyPublisher<[Organization], Error> {
        organizationsSubject.eraseToAnyPublisher()
    }

    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws {
        replaceOrganizationsOrganizations = organizations
        replaceOrganizationsUserId = userId
    }
}
