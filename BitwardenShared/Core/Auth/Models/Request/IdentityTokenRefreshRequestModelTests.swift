import XCTest

@testable import BitwardenShared

class IdentityTokenRefreshRequestModelTests: BitwardenTestCase {
    // MARK: Properties

    var subject: IdentityTokenRefreshRequestModel!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = IdentityTokenRefreshRequestModel(
            refreshToken: "REFRESH_TOKEN"
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `values` returns the form values to be encoded in the body of the request.
    func test_values() {
        XCTAssertEqual(
            subject.values,
            [
                URLQueryItem(name: "client_id", value: "mobile"),
                URLQueryItem(name: "grant_type", value: "refresh_token"),
                URLQueryItem(name: "refresh_token", value: "REFRESH_TOKEN"),
            ]
        )
    }
}
