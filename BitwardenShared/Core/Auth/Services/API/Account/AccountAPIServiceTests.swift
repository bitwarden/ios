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
}
