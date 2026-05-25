import BitwardenSdk
import TestHelpers

@testable import BitwardenKit

public final class MockServerCommunicationConfigClient: ServerCommunicationConfigClientProtocol {
    public var acquireCookieCallsCount = 0
    public var acquireCookieReceivedDomain: String?
    public var acquireCookieError: Error?

    public var cookiesReceivedDomain: String?
    public var cookiesResult: [BitwardenSdk.AcquiredCookie] = []

    public var getConfigCallsCount = 0
    public var getConfigResult: Result<ServerCommunicationConfig, Error> = .success(
        ServerCommunicationConfig(
            bootstrap: .direct,
        ),
    )

    public var getCookiesCallsCount = 0
    public var getCookiesReceivedDomain: String?
    public var getCookiesResult: Result<[BitwardenSdk.AcquiredCookie], Error> = .success([])

    public var needsBootstrapReceivedDomain: String?
    public var needsBootstrapResult = false

    public var setCommunicationTypeCallsCount = 0
    public var setCommunicationTypeReceivedDomain: String?
    public var setCommunicationTypeReceivedRequest: SetCommunicationTypeRequest?
    public var setCommunicationTypeError: Error?

    public var setCommunicationTypeV2CallsCount = 0
    public var setCommunicationTypeV2ReceivedRequest: SetCommunicationTypeRequest?
    public var setCommunicationTypeV2Error: Error?

    public init() {}

    public func acquireCookie(domain: String) async throws {
        acquireCookieCallsCount += 1
        acquireCookieReceivedDomain = domain
        if let acquireCookieError {
            throw acquireCookieError
        }
    }

    public func cookies(domain: String) async -> [BitwardenSdk.AcquiredCookie] {
        cookiesReceivedDomain = domain
        return cookiesResult
    }

    public func getConfig(domain: String) async throws -> ServerCommunicationConfig {
        getConfigCallsCount += 1
        return try getConfigResult.get()
    }

    public func getCookies(domain: String) async throws -> [BitwardenSdk.AcquiredCookie] {
        getCookiesCallsCount += 1
        getCookiesReceivedDomain = domain
        return try getCookiesResult.get()
    }

    public func needsBootstrap(domain: String) async -> Bool {
        needsBootstrapReceivedDomain = domain
        return needsBootstrapResult
    }

    public func setCommunicationType(domain: String, request: SetCommunicationTypeRequest) async throws {
        setCommunicationTypeCallsCount += 1
        setCommunicationTypeReceivedDomain = domain
        setCommunicationTypeReceivedRequest = request
        if let setCommunicationTypeError {
            throw setCommunicationTypeError
        }
    }

    public func setCommunicationTypeV2(request: SetCommunicationTypeRequest) async throws {
        setCommunicationTypeV2CallsCount += 1
        setCommunicationTypeV2ReceivedRequest = request
        if let setCommunicationTypeV2Error {
            throw setCommunicationTypeV2Error
        }
    }
}
