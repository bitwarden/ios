import Foundation

@testable import BitwardenShared

class MockKeyConnectorService: KeyConnectorService {
    var convertNewUserToKeyConnectorCalled = false
    var convertNewUserToKeyConnectorHandler: (() -> Void)?
    var convertNewUserToKeyConnectorResult: Result<Void, Error> = .success(())

    var getManagingOrganizationResult: Result<Organization?, Error> = .success(nil)

    var getMasterKeyFromKeyConnectorResult: Result<String, Error> = .success("key")

    var migrateUserPassword: String?
    var migrateUserResult: Result<Void, Error> = .success(())

    var userNeedsMigrationResult: Result<Bool, Error> = .success(true)

    func convertNewUserToKeyConnector(keyConnectorUrl: URL, orgIdentifier: String) async throws {
        convertNewUserToKeyConnectorCalled = true
        convertNewUserToKeyConnectorHandler?()
        return try convertNewUserToKeyConnectorResult.get()
    }

    func getManagingOrganization() async throws -> Organization? {
        try getManagingOrganizationResult.get()
    }

    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String {
        try getMasterKeyFromKeyConnectorResult.get()
    }

    func migrateUser(password: String) async throws {
        migrateUserPassword = password
        try migrateUserResult.get()
    }

    func userNeedsMigration() async throws -> Bool {
        try userNeedsMigrationResult.get()
    }
}
