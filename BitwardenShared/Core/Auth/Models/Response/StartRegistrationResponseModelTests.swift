import XCTest

@testable import BitwardenShared
@testable import Networking

// MARK: - StartRegistrationResponseModelTests

class StartRegistrationResponseModelTests: BitwardenTestCase {
    /// Tests that a response is initialized correctly.
    func test_init() {
        let subject = StartRegistrationResponseModel(
            response: HTTPResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                headers: [:],
                body: "0018A45C4D1DEF81644B54AB7F969B88D65".data(using: .utf8)!,
                requestID: UUID()
            )
        )
        XCTAssertEqual(subject.token, "0018A45C4D1DEF81644B54AB7F969B88D65")
    }
}
