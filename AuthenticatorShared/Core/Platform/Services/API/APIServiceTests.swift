import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import AuthenticatorShared
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

    /// `init(client:)` sets the default base URLs for the HTTP services.
    func test_init_defaultURLs() {
        let apiUnauthenticatedServiceBaseURL = subject.apiUnauthenticatedService.baseURL
        XCTAssertEqual(apiUnauthenticatedServiceBaseURL, URL(string: "https://example.com/api")!)
        XCTAssertTrue(
            subject.apiUnauthenticatedService.requestHandlers.contains(where: { $0 is DefaultHeadersRequestHandler }),
        )
        XCTAssertNil(subject.apiUnauthenticatedService.tokenProvider)
    }

    /// `init(client:)` configures the API service to use `FlightRecorderHTTPLogger` for logging
    /// API requests.
    func test_init_configuresFlightRecorderLogger() {
        let mockFlightRecorder = MockFlightRecorder()
        let subject = APIService(
            client: MockHTTPClient(),
            environmentService: MockEnvironmentService(),
            flightRecorder: mockFlightRecorder,
        )

        XCTAssertTrue(
            subject.apiUnauthenticatedService.loggers.contains(where: { $0 is FlightRecorderHTTPLogger }),
        )
    }
}
