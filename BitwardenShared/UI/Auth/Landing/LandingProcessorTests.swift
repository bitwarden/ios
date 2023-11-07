import XCTest

@testable import BitwardenShared

// MARK: - LandingProcessorTests

class LandingProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LandingProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appSettingsStore = MockAppSettingsStore()
        coordinator = MockCoordinator<AuthRoute>()

        let state = LandingState()
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        appSettingsStore = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `init` without a remembered email in the app settings store initializes the state correctly.
    func test_init_withoutRememberedEmail() {
        appSettingsStore.rememberedEmail = nil
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: LandingState()
        )

        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isRememberMeOn)
    }

    /// `init` with a remembered email in the app settings store initializes the state correctly.
    func test_init_withRememberedEmail() {
        appSettingsStore.rememberedEmail = "email@example.com"
        let services = ServiceContainer.withMocks(
            appSettingsStore: appSettingsStore
        )
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: LandingState()
        )

        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.continuePressed` and an invalid email navigates to the `.alert` route.
    func test_receive_continuePressed_withInvalidEmail() {
        appSettingsStore.rememberedEmail = nil
        subject.state.email = "email"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .alert(Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    func test_receive_continuePressed_withValidEmail_isRememberMeOn_false() {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = false
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }

    /// `receive(_:)` with `.continuePressed` and a valid email surrounded by whitespace trims the whitespace and
    /// navigates to the login screen.
    func test_receive_continuePressed_withValidEmailAndSpace() {
        subject.state.email = " email@example.com "

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
    }

    /// `receive(_:)` with `.continuePressed` and a valid email with uppercase characters converts the email to
    /// lowercase and navigates to the login screen.
    func test_receive_continuePressed_withValidEmailUppercased() {
        subject.state.email = "EMAIL@EXAMPLE.COM"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
    }

    /// `receive(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    func test_receive_continuePressed_withValidEmail_isRememberMeOn_true() {
        appSettingsStore.rememberedEmail = nil
        subject.state.isRememberMeOn = true
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
            isLoginWithDeviceVisible: false
        ))
        XCTAssertEqual(appSettingsStore.rememberedEmail, "email@example.com")
    }

    /// `receive(_:)` with `.createAccountPressed` navigates to the create account screen.
    func test_receive_createAccountPressed() {
        subject.receive(.createAccountPressed)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `receive(_:)` with `.emailChanged` and an empty value updates the state to reflect the changes.
    func test_receive_emailChanged_empty() {
        subject.state.email = "email@example.com"

        subject.receive(.emailChanged(""))
        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.emailChanged` and an email value updates the state to reflect the changes.
    func test_receive_emailChanged_value() {
        XCTAssertEqual(subject.state.email, "")

        subject.receive(.emailChanged("email@example.com"))
        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.regionPressed` navigates to the region selection screen.
    func test_receive_regionPressed() async throws {
        subject.receive(.regionPressed)

        let route = coordinator.routes.last
        guard let route, case let AuthRoute.alert(alert) = route
        else {
            XCTFail("The last route was not an `.alert`: \(String(describing: route))")
            return
        }
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        await alert.alertActions[0].handler?(alert.alertActions[0])
        XCTAssertEqual(subject.state.region, .unitedStates)

        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        await alert.alertActions[1].handler?(alert.alertActions[1])
        XCTAssertEqual(subject.state.region, .europe)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        await alert.alertActions[2].handler?(alert.alertActions[2])
        XCTAssertEqual(subject.state.region, .selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted)
    }

    /// `receive(_:)` with `.rememberMeChanged(true)` updates the state to reflect the changes.
    func test_receive_rememberMeChanged_true() {
        XCTAssertFalse(subject.state.isRememberMeOn)

        subject.receive(.rememberMeChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
    }

    /// `receive(_:)` with `.rememberMeChanged(false)` updates the state to reflect the changes.
    func test_receive_rememberMeChanged_false() {
        appSettingsStore.rememberedEmail = "email@example.com"
        subject.state.isRememberMeOn = true

        subject.receive(.rememberMeChanged(false))
        XCTAssertFalse(subject.state.isRememberMeOn)
        XCTAssertNil(appSettingsStore.rememberedEmail)
    }
}
