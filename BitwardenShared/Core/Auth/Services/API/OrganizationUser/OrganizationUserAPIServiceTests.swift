import XCTest

@testable import BitwardenShared

class OrganizationUserAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `organizationUserResetPasswordEnrollment()` successfully decodes the response.
    func test_organizationUserResetPasswordEnrollment() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        await assertAsyncDoesNotThrow {
            try await subject.organizationUserResetPasswordEnrollment(
                organizationId: "ORG_ID",
                requestModel: OrganizationUserResetPasswordEnrollmentRequestModel(
                    masterPasswordHash: "MASTER_PASSWORD_HASH",
                    resetPasswordKey: "RESET_PASSWORD_KEY"
                ),
                userId: "USER_ID"
            )
        }
    }
}
