import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorAuthProcessorTests

class TwoFactorAuthProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var subject: TwoFactorAuthProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<AuthRoute>()
        errorReporter = MockErrorReporter()

        subject = TwoFactorAuthProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            ),
            state: TwoFactorAuthState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `captchaErrored(error:)` records an error.
    func test_captchaErrored() {
        subject.captchaErrored(error: BitwardenTestError.example)

        waitFor(!coordinator.alertShown.isEmpty)
        XCTAssertEqual(coordinator.alertShown.last, .networkResponseError(BitwardenTestError.example))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `init` sets up the state correctly.
    func test_init() {
        let authMethodsData = ["1": ["Email": "test@example.com"]]
        let state = TwoFactorAuthState(authMethodsData: authMethodsData)
        subject = TwoFactorAuthProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            ),
            state: state
        )

        XCTAssertEqual(subject.state.availableAuthMethods, [.email, .recoveryCode])
        XCTAssertEqual(subject.state.displayEmail, "test@example.com")
    }

    /// `receive(_:)` with `.authMethodSelected` updates the value in the state.
    func test_receive_authMethodSelected() {
        subject.receive(.authMethodSelected(.authenticatorApp))
        XCTAssertEqual(subject.state.authMethod, .authenticatorApp)
    }

    /// `receive(_:)` with `.authMethodSelected` opens the url for the recover code.
    func test_receive_authMethodSelected_recoveryCode() {
        subject.state.authMethod = .email
        subject.receive(.authMethodSelected(.recoveryCode))
        XCTAssertEqual(subject.state.authMethod, .email)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.recoveryCode)
    }

    /// `receive(_:)` with `.clearURL` clears the URL in the state.
    func test_receive_clearURL() {
        subject.state.url = .example
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.rememberMeToggleChanged` updates the value in the state.
    func test_receive_rememberMeToggleChanged() {
        subject.receive(.rememberMeToggleChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
        subject.receive(.rememberMeToggleChanged(false))
        XCTAssertFalse(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.verificationCodeChanged` updates the value in the state and enables the button if
    /// applicable.
    func test_receive_verificationCodeChanged() {
        subject.receive(.verificationCodeChanged("123"))
        XCTAssertEqual(subject.state.verificationCode, "123")
        XCTAssertFalse(subject.state.continueEnabled)

        subject.receive(.verificationCodeChanged("123456"))
        XCTAssertEqual(subject.state.verificationCode, "123456")
        XCTAssertTrue(subject.state.continueEnabled)
    }
}
