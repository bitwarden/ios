import TestHelpers
import XCTest

@testable import BitwardenShared

class OrganizationAPIServiceTests: BitwardenTestCase {
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

    /// `getOrganizationAutoEnrollStatus(identifier:)` successfully decodes the organization's
    /// auto-enroll status response.
    func test_getOrganizationAutoEnrollStatus() async throws {
        client.result = .httpSuccess(testData: .organizationAutoEnrollStatus)

        let response = try await subject.getOrganizationAutoEnrollStatus(identifier: "ORG_IDENTIFIER")

        XCTAssertEqual(
            response,
            OrganizationAutoEnrollStatusResponseModel(
                id: "af0d946f-8a7c-41eb-af0e-4b2e4e9fb8f5",
                resetPasswordEnabled: true,
            ),
        )
    }

    /// `getOrganizationKeys(organizationId:)` successfully decodes the organizations keys response.
    func test_getOrganizationKeys() async throws {
        client.result = .httpSuccess(testData: .organizationKeys)

        let response = try await subject.getOrganizationKeys(organizationId: "ORG_ID")

        XCTAssertEqual(
            response,
            OrganizationKeysResponseModel(
                privateKey: nil,
                publicKey: "MIIBIjAN...2QIDAQAB",
            ),
        )
    }

    /// `getSingleSignOnVerifiedDomains(email:)` successfully decodes the single sign on verified domains response.
    func test_getSingleSignOnVerifiedDomains() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerified)

        let response = try await subject.getSingleSignOnVerifiedDomains(email: "example@email.com")

        XCTAssertEqual(
            response,
            SingleSignOnDomainsVerifiedResponse(
                verifiedDomains: [
                    SingleSignOnDomainVerifiedDetailResponse(
                        domainName: "domain",
                        organizationIdentifier: "TestID",
                        organizationName: "TestName",
                    ),
                ],
            ),
        )
    }

    /// `leaveOrganization(organizationId:)` successfully runs the leaveOrganization
    func test_leaveOrganization() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        await assertAsyncDoesNotThrow {
            try await subject.leaveOrganization(organizationId: "ORG_IDENTIFIER")
        }
    }

    /// `revokeSelfFromOrganization(organizationId:)` successfully runs the revokeSelfFromOrganization
    func test_revokeSelfFromOrganization() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        await assertAsyncDoesNotThrow {
            try await subject.revokeSelfFromOrganization(organizationId: "ORG_IDENTIFIER")
        }
    }
}
