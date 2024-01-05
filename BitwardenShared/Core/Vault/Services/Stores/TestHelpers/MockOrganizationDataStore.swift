import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockOrganizationDataStore: OrganizationDataStore {
    var deleteAllOrganizationsUserId: String?

    var fetchAllOrganizationsResult: Result<[Organization], Error> = .success([])

    var organizationSubject = CurrentValueSubject<[Organization], Error>([])

    var replaceOrganizationsValue: [ProfileOrganizationResponseModel]?
    var replaceOrganizationsUserId: String?

    func deleteAllOrganizations(userId: String) async throws {
        deleteAllOrganizationsUserId = userId
    }

    func fetchAllOrganizations(userId: String) async throws -> [Organization] {
        try fetchAllOrganizationsResult.get()
    }

    func organizationPublisher(userId: String) -> AnyPublisher<[Organization], Error> {
        organizationSubject.eraseToAnyPublisher()
    }

    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws {
        replaceOrganizationsValue = organizations
        replaceOrganizationsUserId = userId
    }
}
