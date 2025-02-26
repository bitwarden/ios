import Networking
import XCTest

@testable import BitwardenShared

class PreValidateSingleSignOnRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: PreValidateSingleSignOnRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = PreValidateSingleSignOnRequest(organizationIdentifier: "TeamLivefront")
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/sso/prevalidate")
    }

    /// `query` returns the queries of the request.
    func test_query() {
        XCTAssertEqual(subject.query, [URLQueryItem(name: "domainHint", value: "TeamLivefront")])
    }
}
