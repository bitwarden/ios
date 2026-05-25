import BitwardenSdk

final class MockServerCommunicationConfigRepository: ServerCommunicationConfigRepository {
    var getDomain: String?
    var getResult = Result<ServerCommunicationConfig?, Error>.success(nil)

    var setDomain: String?
    var setConfig: ServerCommunicationConfig?

    func get(domain: String) async throws -> ServerCommunicationConfig? {
        getDomain = domain
        return try getResult.get()
    }

    func save(domain: String, config: ServerCommunicationConfig) async throws {
        setDomain = domain
        setConfig = config
    }
}
