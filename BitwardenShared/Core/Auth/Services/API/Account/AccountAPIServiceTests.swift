import XCTest

@testable import BitwardenShared

// MARK: - AccountAPIServiceTests

class AccountAPIServiceTests: BitwardenTestCase {
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

    /// `accountRevisionDate()` returns the account's last revision date.
    func test_accountRevisionDate() async throws {
        client.result = .httpSuccess(testData: .accountRevisionDate())

        let date = try await subject.accountRevisionDate()
        XCTAssertEqual(date, Date(timeIntervalSince1970: 1_704_067_200))
    }

    /// `accountRevisionDate()` throws an error if the request fails.
    func test_accountRevisionDate_httpFailure() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.accountRevisionDate()
        }
    }

    /// `createNewAccount(email:masterPasswordHash)` throws an error if the request fails.
    func test_create_account_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.createNewAccount(
                body: CreateAccountRequestModel(
                    email: "example@email.com",
                    kdfConfig: KdfConfig(),
                    key: "key",
                    keys: KeysRequestModel(encryptedPrivateKey: "private"),
                    masterPasswordHash: "1a2b3c",
                    masterPasswordHint: "hint"
                )
            )
        }
    }

    /// `createNewAccount(email:masterPasswordHash)` throws a decoding error if the response is not the expected type.
    func test_create_account_failure() async throws {
        let resultData = APITestData(data: Data("this should fail".utf8))
        client.result = .httpSuccess(testData: resultData)

        await assertAsyncThrows {
            _ = try await subject.createNewAccount(
                body: CreateAccountRequestModel(
                    email: "example@email.com",
                    kdfConfig: KdfConfig(),
                    key: "key",
                    keys: KeysRequestModel(encryptedPrivateKey: "private"),
                    masterPasswordHash: "1a2b3c",
                    masterPasswordHint: "hint"
                )
            )
        }
    }

    /// `createNewAccount(email:masterPasswordHash)` returns the correct value from the API with a successful request.
    func test_create_account_success() async throws {
        let resultData = APITestData.createAccountSuccess
        client.result = .httpSuccess(testData: resultData)

        let successfulResponse = try await subject.createNewAccount(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                key: "key",
                keys: KeysRequestModel(encryptedPrivateKey: "private"),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint"
            )
        )

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.relativePath, "/identity/accounts/register")
        XCTAssertEqual(successfulResponse.captchaBypassToken, "captchaBypassToken")
        XCTAssertNotNil(request.body)
    }

    /// `deleteAccount(body:)` hits the correct API endpoint using the correct HTTPMethod.
    /// This call returns no data.
    func test_delete_account_success() async throws {
        let resultData = APITestData(data: Data())
        client.result = .httpSuccess(testData: resultData)

        _ = try await subject.deleteAccount(
            body: DeleteAccountRequestModel(masterPasswordHash: "1234")
        )

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .delete)
        XCTAssertEqual(request.url.relativePath, "/api/accounts")
    }

    /// `checkDataBreaches(password:)` returns the correct value from the API when the password
    /// has been found in data breaches.
    func test_password_foundInBreaches() async throws {
        let resultData = APITestData.hibpLeakedPasswords
        client.result = .httpSuccess(testData: resultData)

        let password = "12345abcde"
        let successfulResponse = try await subject.checkDataBreaches(password: password)

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/range/dec7d")
        XCTAssertEqual(successfulResponse, 33288)
    }

    /// `checkDataBreaches(password:)` returns the correct value from the API when the password
    /// has not been found in data breaches.
    func test_password_notFoundInBreaches() async throws {
        let resultData = APITestData.hibpLeakedPasswords
        client.result = .httpSuccess(testData: resultData)

        // Password that has not been found in breach.
        let password = "iqpeor,kmn!JO8932jldfasd"
        let successfulResponse = try await subject.checkDataBreaches(password: password)

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/range/c3ed8")
        XCTAssertEqual(successfulResponse, 0)
    }

    /// `preLogin(email:)` throws an error is the request fails.
    func test_preLogin_httpFailure() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows {
            _ = try await subject.preLogin(email: "email@example.com")
        }
    }

    /// `preLogin(email:)` returns the correct value from the API with a successful request.
    func test_preLogin_success() async throws {
        client.result = .httpSuccess(testData: .preLoginSuccess)

        let response = try await subject.preLogin(email: "email@example.com")
        XCTAssertEqual(response.kdf, .pbkdf2sha256)
        XCTAssertEqual(response.kdfIterations, 600_000)
        XCTAssertNil(response.kdfMemory)
        XCTAssertNil(response.kdfParallelism)
    }

    /// `requestOtp()` performs a request to request a one-time password for the user.
    func test_requestOtp() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.requestOtp()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/request-otp")
    }

    /// `setPassword(_:)` performs the request to set the user's password.
    func test_setPassword() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        let requestModel = SetPasswordRequestModel(
            kdfConfig: KdfConfig(),
            key: "KEY",
            keys: KeysRequestModel(encryptedPrivateKey: "ENCRYPTED_PRIVATE_KEY", publicKey: "PUBLIC_KEY"),
            masterPasswordHash: "MASTER_PASSWORD_HASH",
            masterPasswordHint: "MASTER_PASSWORD_HINT",
            orgIdentifier: "ORG_ID"
        )
        try await subject.setPassword(requestModel)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/set-password")
    }

    /// `updatePassword()` doesn't throw an error when receiving the empty response.
    func test_updatePassword() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        let requestModel = UpdatePasswordRequestModel(
            key: "KEY",
            masterPasswordHash: "MASTER_PASSWORD_HASH",
            masterPasswordHint: "MASTER_PASSWORD_HINT",
            newMasterPasswordHash: "NEW_MASTER_PASSWORD_HASH"
        )
        try await subject.updatePassword(requestModel)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/password")
    }

    /// `updateTempPassword()` doesn't throw an error when receiving the empty response.
    func test_updateTempPassword() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        let requestModel = UpdateTempPasswordRequestModel(
            key: "KEY",
            masterPasswordHint: "MASTER_PASSWORD_HINT",
            newMasterPasswordHash: "NEW_MASTER_PASSWORD_HASH"
        )
        try await subject.updateTempPassword(requestModel)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/update-temp-password")
    }

    /// `verifyOtp()` performs a request to verify a one-time password for the user.
    func test_verifyOtp() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.verifyOtp("OTP")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/verify-otp")
    }
}
