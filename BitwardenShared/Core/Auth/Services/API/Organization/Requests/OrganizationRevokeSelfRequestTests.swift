import Networking
import XCTest

@testable import BitwardenShared

class OrganizationRevokeSelfRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: OrganizationRevokeSelfRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = OrganizationRevokeSelfRequest(organizationId: "ORGANIZATION_ID")
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns a `nil` body.
    func test_body() throws {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/organizations/ORGANIZATION_ID/users/revoke-self")
    }
}
