import XCTest

@testable import BitwardenShared

class AuthAPIServiceTests: BitwardenTestCase {
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

    /// `getIdentityToken()` successfully decodes the identity token response.
    func test_getIdentityToken() async throws {
        client.result = .httpSuccess(testData: .identityToken)

        let response = try await subject.getIdentityToken(
            IdentityTokenRequestModel(
                authenticationMethod: .password(username: "username", password: "password"),
                captchaToken: nil,
                deviceInfo: .fixture()
            )
        )

        XCTAssertEqual(
            response,
            IdentityTokenResponseModel(
                forcePasswordReset: false,
                kdf: .pbkdf2sha256,
                kdfIterations: 600_000,
                kdkMemory: nil,
                kdfParallelism: nil,
                key: "KEY",
                masterPasswordPolicy: nil,
                privateKey: "PRIVATE_KEY",
                resetMasterPassword: false,
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: true,
                    keyConnectorOption: nil,
                    trustedDeviceOption: nil
                ),
                accessToken: "ACCESS_TOKEN",
                expiresIn: 3600,
                tokenType: "Bearer",
                refreshToken: "REFRESH_TOKEN"
            )
        )
    }
}
