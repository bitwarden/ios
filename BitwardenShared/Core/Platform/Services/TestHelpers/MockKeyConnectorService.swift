import Foundation

@testable import BitwardenShared

class MockKeyConnectorService: KeyConnectorService {
    var convertNewUserToKeyConnectorCalled = false
    var convertNewUserToKeyConnectorHandler: (() -> Void)?
    var convertNewUserToKeyConnectorResult: Result<KeyConnectorConversionResult, Error> = .success(
        KeyConnectorConversionResult(encryptedUserKey: "encryptedUserKey", masterKey: "masterKey"),
    )
    var convertNewUserToKeyConnectorKeyConnectorUrl: URL? // swiftlint:disable:this identifier_name
    var convertNewUserToKeyConnectorOrganizationId: String? // swiftlint:disable:this identifier_name

    var getManagingOrganizationResult: Result<Organization?, Error> = .success(nil)

    var migrateUserPassword: String?
    var migrateUserResult: Result<Void, Error> = .success(())

    var userNeedsMigrationResult: Result<Bool, Error> = .success(true)

    func convertNewUserToKeyConnector(
        keyConnectorUrl: URL,
        orgIdentifier: String,
    ) async throws -> KeyConnectorConversionResult {
        convertNewUserToKeyConnectorCalled = true
        convertNewUserToKeyConnectorKeyConnectorUrl = keyConnectorUrl
        convertNewUserToKeyConnectorOrganizationId = orgIdentifier
        convertNewUserToKeyConnectorHandler?()
        return try convertNewUserToKeyConnectorResult.get()
    }

    func getManagingOrganization() async throws -> Organization? {
        try getManagingOrganizationResult.get()
    }

    func migrateUser(password: String) async throws {
        migrateUserPassword = password
        try migrateUserResult.get()
    }

    func userNeedsMigration() async throws -> Bool {
        try userNeedsMigrationResult.get()
    }
}
