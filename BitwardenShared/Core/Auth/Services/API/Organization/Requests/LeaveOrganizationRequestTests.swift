import Networking
import XCTest

@testable import BitwardenShared

class LeaveOrganizationRequestTests: BitwardenTestCase {
    // MARK: Properties

    let subject = LeaveOrganizationRequest(organizationId: "org-id")

    // MARK: Tests

    /// Validate that the request's body is `nil`.
    func test_body() {
        XCTAssertNil(subject.body)
    }

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/organizations/org-id/leave")
    }
}
