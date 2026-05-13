import BitwardenSdk
import TestHelpers

@testable import BitwardenKit

public final class MockServerCommunicationConfigClient: ServerCommunicationConfigClientProtocol {
    public var acquireCookieCallsCount = 0
    public var acquireCookieReceivedHostname: String?
    public var acquireCookieError: Error?

    public var cookiesReceivedHostname: String?
    public var cookiesResult: [BitwardenSdk.AcquiredCookie] = []

    public var getConfigCallsCount = 0
    public var getConfigResult: Result<ServerCommunicationConfig, Error> = .success(
        ServerCommunicationConfig(
            bootstrap: .direct,
        ),
    )

    public var needsBootstrapReceivedHostname: String?
    public var needsBootstrapResult = false

    public var setCommunicationTypeCallsCount = 0
    public var setCommunicationTypeReceivedHostname: String?
    public var setCommunicationTypeReceivedRequest: SetCommunicationTypeRequest?
    public var setCommunicationTypeError: Error?

    public init() {}

    public func acquireCookie(hostname: String) async throws {
        acquireCookieCallsCount += 1
        acquireCookieReceivedHostname = hostname
        if let acquireCookieError {
            throw acquireCookieError
        }
    }

    public func cookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie] {
        cookiesReceivedHostname = hostname
        return cookiesResult
    }

    public func getConfig(hostname: String) async throws -> ServerCommunicationConfig {
        getConfigCallsCount += 1
        return try getConfigResult.get()
    }

    public func needsBootstrap(hostname: String) async -> Bool {
        needsBootstrapReceivedHostname = hostname
        return needsBootstrapResult
    }

    public func setCommunicationType(hostname: String, request: SetCommunicationTypeRequest) async throws {
        setCommunicationTypeCallsCount += 1
        setCommunicationTypeReceivedHostname = hostname
        setCommunicationTypeReceivedRequest = request
        if let setCommunicationTypeError {
            throw setCommunicationTypeError
        }
    }
}
