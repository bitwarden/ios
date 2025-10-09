import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - RefreshableAPIServiceTests

class RefreshableAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var accountTokenProvider: MockAccountTokenProvider!
    var subject: RefreshableAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        accountTokenProvider = MockAccountTokenProvider()
        subject = APIService(
            accountTokenProvider: accountTokenProvider,
            environmentService: MockEnvironmentService(),
            flightRecorder: MockFlightRecorder(),
            stateService: MockStateService(),
            tokenService: MockTokenService(),
        )
    }

    override func tearDown() {
        super.tearDown()

        accountTokenProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `refreshAccessToken()` calls the token provider to refresh the token.
    @MainActor
    func test_refreshAccessToken() async throws {
        try await subject.refreshAccessToken()

        XCTAssertTrue(accountTokenProvider.refreshTokenCalled)
    }

    /// `refreshAccessToken()` throws when the token provider to refresh the token throws.
    @MainActor
    func test_refreshAccessToken_throws() async throws {
        accountTokenProvider.refreshTokenResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.refreshAccessToken()
        }
    }
}
