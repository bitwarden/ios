import XCTest

@testable import BitwardenShared
@testable import Networking

class APIServiceTests: BitwardenTestCase {
    var subject: APIService!

    override func setUp() {
        super.setUp()

        subject = APIService(client: MockHTTPClient())
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `buildKeyConnectorService(baseURL:)` builds a `HTTPService` for communicating with the key
    /// connector API.
    func test_buildKeyConnectorService() {
        let service = subject.buildKeyConnectorService(baseURL: URL(string: "https://example.com/api")!)

        XCTAssertEqual(service.responseHandlers.count, 1)
        XCTAssertTrue(service.responseHandlers.contains(where: { $0 is ResponseValidationHandler }))
        XCTAssertEqual(service.requestHandlers.count, 1)
        XCTAssertTrue(service.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }))
        XCTAssertTrue(service.tokenProvider is AccountTokenProvider)
    }

    /// `init(client:)` sets the default base URLs for the HTTP services.
    func test_init_defaultURLs() {
        let apiServiceBaseURL = subject.apiService.baseURL
        XCTAssertEqual(apiServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )
        XCTAssertTrue(subject.apiService.tokenProvider is AccountTokenProvider)

        let apiUnauthenticatedServiceBaseURL = subject.apiUnauthenticatedService.baseURL
        XCTAssertEqual(apiUnauthenticatedServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiUnauthenticatedService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )
        XCTAssertNil(subject.apiUnauthenticatedService.tokenProvider)

        let eventsServiceBaseURL = subject.eventsService.baseURL
        XCTAssertEqual(eventsServiceBaseURL, URL(string: "https://example.com/events")!)
        XCTAssertTrue(
            subject.eventsService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )
        XCTAssertTrue(subject.eventsService.tokenProvider is AccountTokenProvider)

        let hibpServiceBaseURL = subject.hibpService.baseURL
        XCTAssertEqual(hibpServiceBaseURL, URL(string: "https://api.pwnedpasswords.com")!)
        XCTAssertNil(subject.hibpService.tokenProvider)

        let identityServiceBaseURL = subject.identityService.baseURL
        XCTAssertEqual(identityServiceBaseURL, URL(string: "https://example.com/identity")!)
        XCTAssertTrue(
            subject.identityService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )
        XCTAssertNil(subject.identityService.tokenProvider)
    }
}
