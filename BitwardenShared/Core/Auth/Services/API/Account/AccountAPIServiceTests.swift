import XCTest

@testable import BitwardenShared

// MARK: - AccountAPIServiceTests

class AccountAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

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

    // MARK: Account creation

    /// `createNewAccount(email:masterPasswordHash)` throws an error if the request fails.
    func test_create_account_httpFailure() async {
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.createNewAccount(
                body: CreateAccountRequestModel(
                    email: "example@email.com",
                    masterPasswordHash: "1234"
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
                    masterPasswordHash: "1234"
                )
            )
        }
    }

    /// `createNewAccount(email:masterPasswordHash)` returns the correct value from the API with a successful request.
    func test_create_account_success() async throws {
        let resultData = APITestData.createAccountResponse
        client.result = .httpSuccess(testData: resultData)

        let successfulResponse = try await subject.createNewAccount(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                masterPasswordHash: "1234"
            )
        )

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.relativePath, "/api/accounts/register")
        XCTAssertEqual(successfulResponse.captchaBypassToken, "captchaBypassToken")
        XCTAssertNotNil(request.body)
    }
}
