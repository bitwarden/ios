import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenKit
@testable import Networking

// MARK: - HTTPServiceBuilderTests

struct HTTPServiceBuilderTests {
    // MARK: Properties

    let subject: HTTPServiceBuilder

    // MARK: Initialization

    init() {
        subject = HTTPServiceBuilder(
            client: MockHTTPClient(),
            defaultHeadersRequestHandler: DefaultHeadersRequestHandler(
                appVersion: "2023.8.0",
                userAgentBuilder: UserAgentBuilder(
                    appName: "Bitwarden",
                    appVersion: "2023.8.0",
                    systemDevice: MockSystemDevice(),
                ),
            ),
            deviceIdentifierRequestHandler: DeviceIdentifierRequestHandler(
                appIDService: AppIDService(appIDSettingsStore: MockAppIDSettingsStore()),
            ),
            loggers: [],
            ssoCookieVendorRequestHandler: StubRequestHandler(),
            ssoCookieVendorResponseHandler: StubResponseHandler(),
        )
    }

    // MARK: Tests

    /// `makeService(baseURLGetter:tokenProvider:includeDeviceIdentifier:)` builds a service with the
    /// default request and response handlers, without the `DeviceIdentifierRequestHandler` by default.
    @Test
    func makeService_default() {
        let service = subject.makeService(baseURLGetter: { URL(string: "https://example.com")! })

        #expect(service.baseURL == URL(string: "https://example.com"))
        #expect(service.requestHandlers.count == 2)
        #expect(service.requestHandlers[0] is DefaultHeadersRequestHandler)
        #expect(service.requestHandlers[1] is StubRequestHandler)
        #expect(!service.requestHandlers.contains(where: { $0 is DeviceIdentifierRequestHandler }))
        #expect(service.responseHandlers.count == 2)
        #expect(service.responseHandlers[0] is StubResponseHandler)
        #expect(service.responseHandlers[1] is ResponseValidationHandler)
        #expect(service.tokenProvider == nil)
    }

    /// `makeService(baseURLGetter:tokenProvider:includeDeviceIdentifier:)` appends the
    /// `DeviceIdentifierRequestHandler` after the default request handlers when
    /// `includeDeviceIdentifier` is `true`.
    @Test
    func makeService_includeDeviceIdentifier_true() {
        let service = subject.makeService(
            baseURLGetter: { URL(string: "https://example.com")! },
            includeDeviceIdentifier: true,
        )

        #expect(service.requestHandlers.count == 3)
        #expect(service.requestHandlers[0] is DefaultHeadersRequestHandler)
        #expect(service.requestHandlers[1] is StubRequestHandler)
        #expect(service.requestHandlers[2] is DeviceIdentifierRequestHandler)
        #expect(service.responseHandlers.count == 2)
    }

    /// `makeService(baseURLGetter:tokenProvider:includeDeviceIdentifier:)` doesn't include the
    /// `DeviceIdentifierRequestHandler` when `includeDeviceIdentifier` is `false`.
    @Test
    func makeService_includeDeviceIdentifier_false() {
        let service = subject.makeService(
            baseURLGetter: { URL(string: "https://example.com")! },
            includeDeviceIdentifier: false,
        )

        #expect(service.requestHandlers.count == 2)
        #expect(!service.requestHandlers.contains(where: { $0 is DeviceIdentifierRequestHandler }))
    }
}

// MARK: - StubRequestHandler

/// A `RequestHandler` that returns requests unmodified, used in place of the SSO cookie vendor
/// request handler.
///
private final class StubRequestHandler: RequestHandler {
    func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        request
    }
}

// MARK: - StubResponseHandler

/// A `ResponseHandler` that returns responses unmodified, used in place of the SSO cookie vendor
/// response handler.
///
private final class StubResponseHandler: ResponseHandler {
    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
        response
    }
}
