import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenKit
@testable import BitwardenShared
@testable import BitwardenSharedMocks
@testable import Networking

class APIServiceTests: BitwardenTestCase {
    var accountTokenProvider: MockAccountTokenProvider!
    var subject: APIService!

    override func setUp() {
        super.setUp()

        accountTokenProvider = MockAccountTokenProvider()
        subject = APIService(accountTokenProvider: accountTokenProvider, client: MockHTTPClient())
    }

    override func tearDown() {
        super.tearDown()

        accountTokenProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildKeyConnectorService(baseURL:)` builds a `HTTPService` for communicating with the key
    /// connector API.
    func test_buildKeyConnectorService() {
        let service = subject.buildKeyConnectorService(baseURL: URL(string: "https://example.com/api")!)

        XCTAssertEqual(service.responseHandlers.count, 2)
        XCTAssertTrue(service.responseHandlers.contains(where: { $0 is ResponseValidationHandler }))
        XCTAssertTrue(service.responseHandlers.contains(where: { $0 is SSOCookieVendorResponseHandler }))
        XCTAssertEqual(service.requestHandlers.count, 2)
        XCTAssertTrue(service.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }))
        XCTAssertTrue(service.requestHandlers.contains(where: { $0 is SSOCookieVendorRequestHandler }))
        XCTAssertFalse(service.requestHandlers.contains(where: { $0 is DeviceIdentifierRequestHandler }))
        XCTAssertTrue(service.tokenProvider is AccountTokenProvider)
    }

    /// `init(client:)` applies the `DeviceIdentifierRequestHandler` only to the unauthenticated
    /// services that send requests to Bitwarden hosts.
    func test_init_deviceIdentifierRequestHandler() {
        func hasDeviceIdentifierHandler(_ service: HTTPService) -> Bool {
            service.requestHandlers.contains(where: { $0 is DeviceIdentifierRequestHandler })
        }

        XCTAssertTrue(hasDeviceIdentifierHandler(subject.apiUnauthenticatedService))
        XCTAssertTrue(hasDeviceIdentifierHandler(subject.identityService))

        XCTAssertFalse(hasDeviceIdentifierHandler(subject.apiService))
        XCTAssertFalse(hasDeviceIdentifierHandler(subject.eventsService))
        XCTAssertFalse(hasDeviceIdentifierHandler(subject.fileTransferService))
        XCTAssertFalse(hasDeviceIdentifierHandler(subject.fillAssistService))
        XCTAssertFalse(hasDeviceIdentifierHandler(subject.hibpService))
    }

    /// `init(client:)` builds the file transfer service with the default headers and SSO cookie
    /// vendor handlers, but without the `DeviceIdentifierRequestHandler`, since its requests may
    /// target non-Bitwarden hosts.
    func test_init_fileTransferService() {
        let service = subject.fileTransferService

        XCTAssertEqual(service.requestHandlers.count, 2)
        XCTAssertTrue(service.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }))
        XCTAssertTrue(service.requestHandlers.contains(where: { $0 is SSOCookieVendorRequestHandler }))
        XCTAssertFalse(service.requestHandlers.contains(where: { $0 is DeviceIdentifierRequestHandler }))
        XCTAssertEqual(
            service.responseHandlers.map { String(describing: type(of: $0)) },
            subject.apiUnauthenticatedService.responseHandlers.map { String(describing: type(of: $0)) },
        )
    }

    /// `init(client:)` builds the default account token provider with a service that sends the
    /// `Device-Identifier` header on token refresh requests.
    @MainActor
    func test_init_tokenRefreshService_sendsDeviceIdentifier() async throws {
        let activeAccountStateProvider = MockActiveAccountStateProvider()
        activeAccountStateProvider.getActiveAccountIdReturnValue = "1"
        let appIDSettingsStore = MockAppIDSettingsStore()
        appIDSettingsStore.appID = "APP_ID"
        let client = MockHTTPClient()
        client.result = .httpSuccess(testData: .identityTokenRefresh)
        let subject = APIService(
            activeAccountStateProvider: activeAccountStateProvider,
            appIDService: AppIDService(appIDSettingsStore: appIDSettingsStore),
            client: client,
        )

        _ = try await subject.accountTokenProvider.refreshToken()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.url, URL(string: "https://example.com/identity/connect/token"))
        XCTAssertEqual(request.headers["Device-Identifier"], "APP_ID")
    }

    /// `init(client:)` sets the default base URLs for the HTTP services.
    func test_init_defaultURLs() {
        let apiServiceBaseURL = subject.apiService.baseURL
        XCTAssertEqual(apiServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertTrue(subject.apiService.tokenProvider is AccountTokenProvider)

        let apiUnauthenticatedServiceBaseURL = subject.apiUnauthenticatedService.baseURL
        XCTAssertEqual(apiUnauthenticatedServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiUnauthenticatedService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertNil(subject.apiUnauthenticatedService.tokenProvider)

        let eventsServiceBaseURL = subject.eventsService.baseURL
        XCTAssertEqual(eventsServiceBaseURL, URL(string: "https://example.com/events")!)
        XCTAssertTrue(
            subject.eventsService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertTrue(subject.eventsService.tokenProvider is AccountTokenProvider)

        let fileTransferServiceBaseURL = subject.fileTransferService.baseURL
        XCTAssertEqual(fileTransferServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.fileTransferService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertNil(subject.fileTransferService.tokenProvider)

        let hibpServiceBaseURL = subject.hibpService.baseURL
        XCTAssertEqual(hibpServiceBaseURL, URL(string: "https://api.pwnedpasswords.com")!)
        XCTAssertNil(subject.hibpService.tokenProvider)

        let identityServiceBaseURL = subject.identityService.baseURL
        XCTAssertEqual(identityServiceBaseURL, URL(string: "https://example.com/identity")!)
        XCTAssertTrue(
            subject.identityService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertNil(subject.identityService.tokenProvider)

        let fillAssistServiceBaseURL = subject.fillAssistService.baseURL
        XCTAssertEqual(fillAssistServiceBaseURL, URL(string: "https://example.com/fill-assist-rules")!)
        XCTAssertNil(subject.fillAssistService.tokenProvider)
    }

    /// `setupAccountTokenProviderDelegate(:)` sets up the delegate in the account token provider.
    func test_setupAccountTokenProviderDelegate() async {
        await subject.setAccountTokenProviderDelegate(delegate: MockAccountTokenProviderDelegate())
        let delegate = accountTokenProvider.setDelegateReceivedDelegate
        XCTAssertNotNil(delegate)
    }
}
