import BitwardenKitMocks
import Networking
import TestHelpers
import XCTest

@testable import BitwardenKit

class FlightRecorderHTTPLoggerTests: BitwardenTestCase {
    // MARK: Properties

    var flightRecorder: MockFlightRecorder!
    var subject: FlightRecorderHTTPLogger!

    let requestID = UUID(uuidString: "773CC135-A878-4851-A28D-180FD7D945FA")!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        flightRecorder = MockFlightRecorder()

        subject = FlightRecorderHTTPLogger(flightRecorder: flightRecorder)
    }

    override func tearDown() {
        super.tearDown()

        flightRecorder = nil
        subject = nil
    }

    // MARK: Tests

    /// `logRequest(_:)` logs a GET request to the flight recorder.
    @MainActor
    func test_logRequest_get() async {
        let request = HTTPRequest(url: .example, method: .get, requestID: requestID)
        await subject.logRequest(request)
        XCTAssertEqual(
            flightRecorder.logMessages,
            ["Request 773CC135-A878-4851-A28D-180FD7D945FA: GET https://example.com"],
        )
    }

    /// `logRequest(_:)` logs a POST request to the flight recorder.
    @MainActor
    func test_logRequest_post() async {
        let request = HTTPRequest(url: .example, method: .post, requestID: requestID)
        await subject.logRequest(request)
        XCTAssertEqual(
            flightRecorder.logMessages,
            ["Request 773CC135-A878-4851-A28D-180FD7D945FA: POST https://example.com"],
        )
    }

    /// `logResponse(_:)` logs a 200 response to the flight recorder.
    @MainActor
    func test_logResponse_200() async {
        let response = HTTPResponse(
            url: .example,
            statusCode: 200,
            headers: [:],
            body: Data(),
            requestID: requestID,
        )
        await subject.logResponse(response)
        XCTAssertEqual(
            flightRecorder.logMessages,
            ["Response 773CC135-A878-4851-A28D-180FD7D945FA: https://example.com 200"],
        )
    }

    /// `logResponse(_:)` logs a 400 response to the flight recorder.
    @MainActor
    func test_logResponse_400() async {
        let response = HTTPResponse(
            url: .example,
            statusCode: 400,
            headers: [:],
            body: Data(),
            requestID: requestID,
        )
        await subject.logResponse(response)
        XCTAssertEqual(
            flightRecorder.logMessages,
            ["Response 773CC135-A878-4851-A28D-180FD7D945FA: https://example.com 400"],
        )
    }
}
