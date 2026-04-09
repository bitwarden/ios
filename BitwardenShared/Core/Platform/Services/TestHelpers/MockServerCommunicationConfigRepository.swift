import BitwardenSdk

final class MockServerCommunicationConfigRepository: ServerCommunicationConfigRepository {
    var getHostname: String?
    var getResult = Result<ServerCommunicationConfig?, Error>.success(nil)

    var setHostname: String?
    var setConfig: ServerCommunicationConfig?

    func get(hostname: String) async throws -> ServerCommunicationConfig? {
        getHostname = hostname
        return try getResult.get()
    }

    func save(hostname: String, config: ServerCommunicationConfig) async throws {
        setHostname = hostname
        setConfig = config
    }
}
