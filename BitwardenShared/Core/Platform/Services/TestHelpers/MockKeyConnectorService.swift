@testable import BitwardenShared

class MockKeyConnectorService: KeyConnectorService {
    var getMasterKeyFromKeyConnectorResult: Result<String, Error> = .success("key")

    func getMasterKeyFromKeyConnector() async throws -> String {
        try getMasterKeyFromKeyConnectorResult.get()
    }
}
