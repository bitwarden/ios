import Foundation

@testable import BitwardenShared

class MockKeyConnectorService: KeyConnectorService {
    var convertNewUserToKeyConnectorCalled = false
    var convertNewUserToKeyConnectorHandler: (() -> Void)?
    var convertNewUserToKeyConnectorResult: Result<Void, Error> = .success(())

    var getMasterKeyFromKeyConnectorResult: Result<String, Error> = .success("key")

    func convertNewUserToKeyConnector(keyConnectorUrl: URL, orgIdentifier: String) async throws {
        convertNewUserToKeyConnectorCalled = true
        convertNewUserToKeyConnectorHandler?()
        return try convertNewUserToKeyConnectorResult.get()
    }

    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String {
        try getMasterKeyFromKeyConnectorResult.get()
    }
}
