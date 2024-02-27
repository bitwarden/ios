import Networking
import XCTest

@testable import BitwardenShared

// swiftlint:disable:next type_name
class OrganizationUserResetPasswordEnrollmentRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: OrganizationUserResetPasswordEnrollmentRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = OrganizationUserResetPasswordEnrollmentRequest(
            organizationId: "ORGANIZATION_ID",
            requestModel: OrganizationUserResetPasswordEnrollmentRequestModel(
                masterPasswordHash: "MASTER_PASSWORD_HASH",
                resetPasswordKey: "RESET_PASSWORD_KEY"
            ),
            userId: "USER_ID"
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns a `nil` body.
    func test_body() throws {
        XCTAssertEqual(
            subject.body,
            OrganizationUserResetPasswordEnrollmentRequestModel(
                masterPasswordHash: "MASTER_PASSWORD_HASH",
                resetPasswordKey: "RESET_PASSWORD_KEY"
            )
        )
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/organizations/ORGANIZATION_ID/users/USER_ID/reset-password-enrollment")
    }
}
