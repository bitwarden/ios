import XCTest

@testable import BitwardenShared
@testable import Networking

class APIServiceTests: BitwardenTestCase {
    var subject: APIService!

    override func setUp() {
        super.setUp()

        subject = APIService(
            baseUrlService: DefaultBaseUrlService(baseUrl: .example)
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    /// `init(client:)` sets the default base URLs for the HTTP services.
    func test_init_defaultURLs() {
        let apiServiceBaseURL = subject.apiService.baseURL
        XCTAssertEqual(apiServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )

        let eventsServiceBaseURL = subject.eventsService.baseURL
        XCTAssertEqual(eventsServiceBaseURL, URL(string: "https://example.com/events")!)
        XCTAssertTrue(
            subject.eventsService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )

        let hibpServiceBaseURL = subject.hibpService.baseURL
        XCTAssertEqual(hibpServiceBaseURL, URL(string: "https://api.pwnedpasswords.com")!)

        let identityServiceBaseURL = subject.identityService.baseURL
        XCTAssertEqual(identityServiceBaseURL, URL(string: "https://example.com/identity")!)
        XCTAssertTrue(
            subject.identityService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler })
        )
    }
}
