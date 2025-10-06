import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - TextAutofillHelperFactoryTests

class TextAutofillHelperFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var eventService: MockEventService!
    var subject: TextAutofillHelperFactory!
    var userVerificationHelperFactory: MockUserVerificationHelperFactory!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        eventService = MockEventService()
        userVerificationHelperFactory = MockUserVerificationHelperFactory()
        vaultRepository = MockVaultRepository()
        subject = DefaultTextAutofillHelperFactory(
            authRepository: authRepository,
            errorReporter: errorReporter,
            eventService: eventService,
            userVerificationHelperFactory: userVerificationHelperFactory,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        eventService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `create()` creates the appropriate `TextAutofillHelper` depending on the OS version.
    @MainActor
    func test_create_returnsTextAutofillHelper() {
        let delegate = MockTextAutofillHelperDelegate()
        let helper = subject.create(delegate: delegate)

        guard #available(iOS 18.0, *) else {
            XCTAssertTrue(helper is NoOpTextAutofillHelper)
            return
        }
        XCTAssertTrue(helper is TextAutofillHelperRepromptWrapper)
        XCTAssertTrue(userVerificationHelperFactory.createCalled)
    }
}
