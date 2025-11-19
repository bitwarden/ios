import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - UserVerificationHelperFactoryTests

class UserVerificationHelperFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var localAuthService: MockLocalAuthService!
    var subject: DefaultUserVerificationHelperFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        localAuthService = MockLocalAuthService()
        subject = DefaultUserVerificationHelperFactory(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService,
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        localAuthService = nil
        subject = nil
    }

    // MARK: Tests

    /// `create()` creates an instance of `DefaultUserVerificationHelper`.
    func test_create() {
        let result = subject.create()
        XCTAssertTrue(result is DefaultUserVerificationHelper)
    }
}
