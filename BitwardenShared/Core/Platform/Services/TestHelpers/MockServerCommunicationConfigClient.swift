import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

final class MockServerCommunicationConfigClient: ServerCommunicationConfigClientProtocol {
    var acquireCookieCallsCount = 0
    var acquireCookieReceivedHostname: String?
    var acquireCookieError: Error?

    var cookiesReceivedHostname: String?
    var cookiesResult: [BitwardenSdk.AcquiredCookie] = []

    var getConfigCallsCount = 0
    var getConfigResult: Result<ServerCommunicationConfig, Error> = .failure(BitwardenTestError.example)

    var needsBootstrapReceivedHostname: String?
    var needsBootstrapResult = false

    var setCommunicationTypeCallsCount = 0
    var setCommunicationTypeReceivedHostname: String?
    var setCommunicationTypeReceivedConfig: ServerCommunicationConfig?
    var setCommunicationTypeError: Error?

    func acquireCookie(hostname: String) async throws {
        acquireCookieCallsCount += 1
        acquireCookieReceivedHostname = hostname
        if let acquireCookieError {
            throw acquireCookieError
        }
    }

    func cookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie] {
        cookiesReceivedHostname = hostname
        return cookiesResult
    }

    func getConfig(hostname: String) async throws -> ServerCommunicationConfig {
        getConfigCallsCount += 1
        return try getConfigResult.get()
    }

    func needsBootstrap(hostname: String) async -> Bool {
        needsBootstrapReceivedHostname = hostname
        return needsBootstrapResult
    }

    func setCommunicationType(hostname: String, config: ServerCommunicationConfig) async throws {
        setCommunicationTypeCallsCount += 1
        setCommunicationTypeReceivedHostname = hostname
        setCommunicationTypeReceivedConfig = config
        if let setCommunicationTypeError {
            throw setCommunicationTypeError
        }
    }
}
